// lib/services/firebase_service.dart
// ══════════════════════════════════════════════════════════════════════════════
//  SmartIoT v8.0.0 — Firebase RTDB Service (Singleton)
//
//  CHANGELOG v4.0.0:
//   ✅ [BUG-SHARE] shareDevice now ALSO writes users/{targetUid}/shared_devices/{deviceId}
//      so shared users can discover devices they have access to
//   ✅ [BUG-SHARE] unshareDevice now ALSO removes users/{targetUid}/shared_devices/{deviceId}
//   ✅ [BUG-SHARE] getUserDevices now returns BOTH owned + shared devices (merged, no duplicates)
//   ✅ [SECURITY] device_owners validate: newData.val() === auth.uid enforced
//   ✅ [SECURITY] ota_url validate enforces https:// prefix in rules
//   ✅ [SECURITY] wifi_rssi range validated in rules
//   ✅ [SECURITY] user_lookup write restricted: only write your own uid, cannot overwrite others
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/device_model.dart';
import 'local_history_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance; // Singleton
  FirebaseService._internal();

  final _db = FirebaseDatabase.instance;

  // [FIX-TIMEOUT] All RTDB reads timeout after 10s — prevents UI hang on slow/offline
  static const _kTimeout = Duration(seconds: 10);

  /// Expose database instance for direct queries (e.g. auto-claim polling)
  FirebaseDatabase get db => _db;

  // ── Status Stream ──────────────────────────────────────────────────────────
  Stream<DeviceStatus?> statusStream(String deviceId) {
    return _db
        .ref('${AppConstants.devicesPath}/$deviceId/${AppConstants.statusPath}')
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return null;
      if (data is Map) {
        return DeviceStatus.fromMap(Map<dynamic, dynamic>.from(data));
      }
      return null;
    });
  }

  // ── Meta ───────────────────────────────────────────────────────────────────
  Future<DeviceMeta?> getMeta(String deviceId) async {
    final snap = await _db
        .ref('${AppConstants.devicesPath}/$deviceId/${AppConstants.metaPath}')
        .get().timeout(_kTimeout);
    if (!snap.exists || snap.value == null) return null;
    return DeviceMeta.fromMap(Map<dynamic, dynamic>.from(snap.value is Map ? snap.value as Map : {}));
  }

  Future<void> setMeta(String deviceId, DeviceMeta meta) async {
    await _db
        .ref('${AppConstants.devicesPath}/$deviceId/${AppConstants.metaPath}')
        .update(meta.toMap());
  }

  // ── Control Commands ───────────────────────────────────────────────────────
  Future<void> sendPumpCommand(String deviceId, String command) async {
    await _db
        .ref('${AppConstants.devicesPath}/$deviceId/${AppConstants.controlPath}')
        .update({
      AppConstants.fieldPumpCommand: command.toUpperCase(),
      AppConstants.fieldCmdTimestamp:
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  Future<void> sendModeCommand(String deviceId, String mode) async {
    await _db
        .ref('${AppConstants.devicesPath}/$deviceId/${AppConstants.controlPath}')
        .update({
      AppConstants.fieldModeCommand: mode.toUpperCase(),
      AppConstants.fieldCmdTimestamp:
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  Future<void> sendDryRunReset(String deviceId) async {
    await _db
        .ref('${AppConstants.devicesPath}/$deviceId/${AppConstants.controlPath}')
        .update({
      AppConstants.fieldDryRunReset: true,
      AppConstants.fieldCmdTimestamp:
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  // ── Device Ownership ───────────────────────────────────────────────────────
  Future<void> claimDevice(String deviceId, String uid) async {
    // [FIX-v1.0.2] device_owners uses FLAT string format throughout Firebase rules.
    // All rules check: root.child('device_owners').child(\$deviceId).val() === auth.uid
    // and device_owners validate: newData.isString() — nested Map fails validate.
    // Write: device_owners/$deviceId = "uid"  (flat, rules-compliant)
    await _db.ref().update({
      '${AppConstants.deviceOwnersPath}/$deviceId': uid,           // ← flat string — matches rules exactly
      '${AppConstants.usersPath}/$uid/devices/$deviceId': true,    // ← user index unchanged
    });
  }

  Future<String?> getDeviceOwner(String deviceId) async {
    // device_owners/$deviceId is a flat string (uid). See claimDevice().
    final snap =
        await _db.ref('${AppConstants.deviceOwnersPath}/$deviceId').get().timeout(_kTimeout);
    if (!snap.exists || snap.value == null) return null;
    return snap.value?.toString();
  }

  /// Returns ALL devices the user can access: owned + shared (merged, deduped).
  /// [BUG-SHARE FIX] Previously only returned owned devices — shared devices were invisible.
  Future<List<String>> getUserDevices(String uid) async {
    final results = <String>{};

    // 1 — Owned devices
    final ownedSnap =
        await _db.ref('${AppConstants.usersPath}/$uid/devices').get().timeout(_kTimeout);
    if (ownedSnap.exists && ownedSnap.value != null) {
      final map =
          Map<dynamic, dynamic>.from(ownedSnap.value is Map ? ownedSnap.value as Map<dynamic,dynamic> : {});
      for (final e in map.entries) {
        if (e.value == true) results.add(e.key.toString());
      }
    }

    // 2 — Shared devices (devices others shared WITH this user)
    final sharedSnap =
        await _db.ref('${AppConstants.usersPath}/$uid/shared_devices').get().timeout(_kTimeout);
    if (sharedSnap.exists && sharedSnap.value != null) {
      final map =
          Map<dynamic, dynamic>.from(sharedSnap.value is Map ? sharedSnap.value as Map<dynamic,dynamic> : {});
      for (final e in map.entries) {
        if (e.value == true) results.add(e.key.toString());
      }
    }

    return results.toList();
  }

  // ── Device Sharing ─────────────────────────────────────────────────────────
  /// Share device with another user by their UID.
  /// [BUG-SHARE FIX] Now also writes to targetUid's shared_devices index
  /// so the device appears in their dashboard.
  Future<void> shareDevice(String deviceId, String targetUid) async {
    await _db.ref().update({
      // Grant access in device_shared (checked by Firebase rules)
      '${AppConstants.deviceSharedPath}/$deviceId/$targetUid': true,
      // Add to target user's shared_devices index (so they can discover it)
      '${AppConstants.usersPath}/$targetUid/${AppConstants.sharedDevicesKey}/$deviceId': true,
    });
  }

  /// Remove sharing for a user.
  /// [BUG-SHARE FIX] Also removes from targetUid's shared_devices index.
  Future<void> unshareDevice(String deviceId, String targetUid) async {
    await _db.ref().update({
      '${AppConstants.deviceSharedPath}/$deviceId/$targetUid': null,
      '${AppConstants.usersPath}/$targetUid/${AppConstants.sharedDevicesKey}/$deviceId': null,
    }).timeout(_kTimeout);
  }

  /// Get list of UIDs this device is shared with
  Future<List<String>> getSharedUsers(String deviceId) async {
    final snap = await _db
        .ref('${AppConstants.deviceSharedPath}/$deviceId')
        .get().timeout(_kTimeout);
    if (!snap.exists || snap.value == null) return [];
    final map = Map<dynamic, dynamic>.from(snap.value is Map ? snap.value as Map : {});
    return map.entries
        .where((e) => e.value == true)
        .map((e) => e.key.toString())
        .toList();
  }

  // ── Email → UID Lookup (Spark-plan sharing) ────────────────────────────────
  //
  // Firebase Auth has no public email→UID API (needs Admin SDK / Cloud Function).
  // Workaround: Each user writes their own email→UID mapping on login.
  //   user_lookup/{email_key} = uid
  //   Email key: '.' replaced with ',' (Firebase keys cannot contain '.')
  //
  static String emailToKey(String email) =>
      email.trim().toLowerCase().replaceAll('.', ',');

  Future<void> registerEmailLookup(String uid, String email) async {
    // [SECURITY] The Firebase rule now enforces newData.val() === auth.uid
    // and !data.exists() || data.val() === auth.uid — so this is idempotent
    // and no other user can overwrite your mapping.
    await _db
        .ref('${AppConstants.userLookupPath}/${emailToKey(email)}')
        .set(uid)
        .timeout(_kTimeout);
  }

  Future<String?> lookupUidByEmail(String email) async {
    final snap = await _db
        .ref('${AppConstants.userLookupPath}/${emailToKey(email)}')
        .get().timeout(_kTimeout);
    if (!snap.exists) return null;
    return snap.value?.toString();
  }

  // ── User Profile ───────────────────────────────────────────────────────────
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.ref('${AppConstants.usersPath}/$uid/profile').update(data).timeout(_kTimeout);
  }

  /// Saves Google profile data (name, photo) to Firebase on first sign-in.
  /// Call this after a successful Google Sign-In.
  Future<void> saveGoogleProfile(
      String uid, String? displayName, String? photoURL) async {
    final data = <String, dynamic>{
      if (displayName != null && displayName.isNotEmpty)
        'displayName': displayName.length > 100
            ? displayName.substring(0, 100)
            : displayName,
      if (photoURL != null && photoURL.startsWith('https://'))
        'photoURL': photoURL.length > 500
            ? photoURL.substring(0, 500)
            : photoURL,
      'provider': 'google.com',
    };
    if (data.isNotEmpty) {
      await _db
          .ref('${AppConstants.usersPath}/$uid/profile')
          .update(data).timeout(_kTimeout);
    }
  }

  Future<void> savePreference(String uid, String key, dynamic value) async {
    await _db
        .ref('${AppConstants.usersPath}/$uid/preferences/$key')
        .set(value);
  }

  // ── History ────────────────────────────────────────────────────────────────
  //
  //  v4.0.0 LOCAL-FIRST STRATEGY:
  //  • ALL events  → phone storage (Hive) via LocalHistoryService
  //  • CRITICAL only → Firebase RTDB (keeps Spark plan usage low)
  //  Critical = dry_run | alarm | low | empty | pump_on | boot
  //
  static bool _isCriticalEvent(String event) {
    final e = event.toLowerCase();
    return e.contains('dry') ||
        e.contains('alarm') ||
        e.contains('low') ||
        e.contains('empty') ||
        e.contains('pump on') ||
        e.contains('pump_on') ||
        e.contains('boot');
  }

  /// Log to BOTH local storage and (if critical) Firebase RTDB.
  /// Call this instead of the old logHistoryEvent.
  Future<void> logEvent(String deviceId, String event) async {
    // 1 — Always save locally (no network, no quota)
    // Import is done lazily to avoid circular deps
    await _logLocal(deviceId, event);
    // 2 — Only push critical events to Firebase RTDB
    if (_isCriticalEvent(event)) {
      try {
        await _db
            .ref('${AppConstants.devicesPath}/$deviceId/history')
            .push()
            .set({
          'event': event,
          'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      } catch (_) {
        // Cloud push failed — local copy still saved, no data loss
      }
    }
  }

  /// Legacy — kept for backward compat. Use logEvent() going forward.
  Future<void> logHistoryEvent(String deviceId, String event) async {
    await logEvent(deviceId, event);
  }

  Future<void> _logLocal(String deviceId, String event) async {
    try {
      await LocalHistoryService.logEvent(
        deviceId: deviceId,
        event: event,
        cloudSynced: _isCriticalEvent(event),
      );
      if (kDebugMode) debugPrint('[Firebase] logEvent saved locally: $event for $deviceId');
    } catch (e) {
      if (kDebugMode) debugPrint('[Firebase] _logLocal error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(
      String deviceId, {int limit = 20}) async {
    final snap = await _db
        .ref('${AppConstants.devicesPath}/$deviceId/history')
        .orderByChild('ts')
        .limitToLast(limit)
        .get().timeout(_kTimeout);
    if (!snap.exists || snap.value == null) return [];
    final map = Map<dynamic, dynamic>.from(snap.value is Map ? snap.value as Map : {});
    return map.values
        .map((v) => Map<String, dynamic>.from(v is Map ? v : {}))
        .toList()
      ..sort((a, b) => (b['ts'] as int).compareTo(a['ts'] as int));
  }

  // ── Schedules ──────────────────────────────────────────────────────────────
  Future<void> saveSchedule(
      String deviceId, String scheduleId, Map<String, dynamic> data) async {
    // [FIX BUG-SCHED] Use update() not set() — set() overwrites the entire
    // schedule node, so toggling active/inactive erases hour/minute/duration.
    await _db
        .ref('${AppConstants.schedulesPath}/$deviceId/$scheduleId')
        .update(data).timeout(_kTimeout);
  }

  Future<List<Map<String, dynamic>>> getSchedules(String deviceId) async {
    final snap =
        await _db.ref('${AppConstants.schedulesPath}/$deviceId').get().timeout(_kTimeout);
    if (!snap.exists || snap.value == null) return [];
    final map = Map<dynamic, dynamic>.from(snap.value is Map ? snap.value as Map : {});
    return map.entries
        .map((e) => {
              'id': e.key.toString(),
              ...Map<String, dynamic>.from(e.value is Map ? e.value as Map<dynamic,dynamic> : {}),
            })
        .toList();
  }

  Future<void> deleteSchedule(String deviceId, String scheduleId) async {
    await _db
        .ref('${AppConstants.schedulesPath}/$deviceId/$scheduleId')
        .remove();
  }


  // ── Calibration ────────────────────────────────────────────────────────────
  Future<void> saveCalibration(String deviceId, Map<String, dynamic> data) async {
    await _db
        .ref('${AppConstants.devicesPath}/$deviceId/meta/calibration')
        .update(data).timeout(_kTimeout);
  }

  Future<Map<String, dynamic>?> getCalibration(String deviceId) async {
    final snap = await _db
        .ref('${AppConstants.devicesPath}/$deviceId/meta/calibration')
        .get().timeout(_kTimeout);
    if (!snap.exists || snap.value == null) return null;
    return Map<String, dynamic>.from(snap.value is Map ? Map<dynamic,dynamic>.from(snap.value as Map) : {});
  }

  // ── Thresholds ─────────────────────────────────────────────────────────────
  Future<void> saveThresholds(String deviceId, Map<String, dynamic> data) async {
    await _db
        .ref('${AppConstants.devicesPath}/$deviceId/meta/thresholds')
        .update(data).timeout(_kTimeout);
    // Note: /control/thresholds write removed — Firebase rules block it ($other: false).
    // ESP32 reads thresholds from /meta/thresholds via a dedicated meta poll.
    // If real-time threshold sync to ESP32 is needed, add the rule and re-enable.
  }

  Future<Map<String, dynamic>?> getThresholds(String deviceId) async {
    final snap = await _db
        .ref('${AppConstants.devicesPath}/$deviceId/meta/thresholds')
        .get().timeout(_kTimeout);
    if (!snap.exists || snap.value == null) return null;
    return Map<String, dynamic>.from(snap.value is Map ? Map<dynamic,dynamic>.from(snap.value as Map) : {});
  }

  // ── Flow rate ──────────────────────────────────────────────────────────────
  Future<void> saveFlowRate(String deviceId, double lpm) async {
    await _db
        .ref('${AppConstants.devicesPath}/$deviceId/meta')
        .update({'flow_rate_lpm': lpm}).timeout(_kTimeout);
  }

  // ── Device claim check ─────────────────────────────────────────────────────
  Future<String?> checkDeviceClaimed(String deviceId) async {
    try {
      // device_owners/$deviceId is a flat string uid. See claimDevice().
      final snap =
          await _db.ref('${AppConstants.deviceOwnersPath}/$deviceId').get().timeout(_kTimeout);
      if (!snap.exists || snap.value == null) return null;
      return snap.value?.toString();
    } catch (_) {
      return null;
    }
  }


  // ── FCM Token ──────────────────────────────────────────────────────────────
  /// Save FCM push notification token to Firebase RTDB.
  /// Call this after notification_service initializes and gets a token.
  Future<void> saveFcmToken(String uid, String token) async {
    try {
      await _db
          .ref('${AppConstants.usersPath}/$uid/fcmToken')
          .set(token);
      if (kDebugMode) debugPrint('[Firebase] FCM token saved for $uid');
    } catch (e) {
      if (kDebugMode) debugPrint('[Firebase] FCM token save failed: $e');
    }
  }

  /// Remove FCM token on logout (so user stops receiving notifications after sign-out).
  Future<void> removeFcmToken(String uid) async {
    try {
      await _db.ref('${AppConstants.usersPath}/$uid/fcmToken').remove();
    } catch (_) {}
  }

  // ── Bulk meta fetch ────────────────────────────────────────────────────────
  /// Fetches all device meta in parallel (Future.wait) — NOT N+1 sequential.
  Future<Map<String, DeviceMeta>> getMetaForDevices(
      List<String> deviceIds) async {
    if (deviceIds.isEmpty) return {};
    final futures = deviceIds.map((id) async {
      final meta = await getMeta(id);
      return MapEntry(id, meta);
    });
    final results = await Future.wait(futures);
    final map = <String, DeviceMeta>{};
    for (final entry in results) {
      if (entry.value != null) map[entry.key] = entry.value!;
    }
    return map;
  }
}
