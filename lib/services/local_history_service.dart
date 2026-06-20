// lib/services/local_history_service.dart
// ══════════════════════════════════════════════════════════════════════════════
//  SmartIoT v4.0.0 — Local History Service
//
//  STRATEGY (100% Spark-plan compatible):
//  ┌─────────────────────────────────────────────────────────┐
//  │  PHONE STORAGE (Hive) — সব history এখানে সেভ হয়        │
//  │    • Unlimited local storage                            │
//  │    • Works offline                                      │
//  │    • Max 5000 entries per device (auto-trim)            │
//  │    • Full event log: every pump on/off, mode, alert     │
//  │                                                         │
//  │  FIREBASE RTDB (Spark FREE) — শুধু important events    │
//  │    • Only: dry_run, alarm, low_level, pump_on           │
//  │    • Max 200 entries per device (auto-trim in rules)    │
//  │    • Shared across devices, viewable from any phone     │
//  └─────────────────────────────────────────────────────────┘
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A single history event entry
class HistoryEvent {
  final String id;
  final String deviceId;
  final String event;
  final int ts; // epoch ms
  final bool isCloudSynced;
  final String? extra; // optional JSON string for extra data

  const HistoryEvent({
    required this.id,
    required this.deviceId,
    required this.event,
    required this.ts,
    this.isCloudSynced = false,
    this.extra,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'deviceId': deviceId,
        'event': event,
        'ts': ts,
        'synced': isCloudSynced,
        if (extra != null) 'extra': extra,
      };

  factory HistoryEvent.fromMap(Map<dynamic, dynamic> m) => HistoryEvent(
        id: m['id']?.toString() ?? '',
        deviceId: m['deviceId']?.toString() ?? '',
        event: m['event']?.toString() ?? '',
        ts: (m['ts'] as num?)?.toInt() ?? 0,
        isCloudSynced: m['synced'] == true,
        extra: m['extra']?.toString(),
      );

  /// Returns true if this event should also be pushed to Firebase RTDB
  bool get isCritical {
    final e = event.toLowerCase();
    return e.contains('dry_run') ||
        e.contains('alarm') ||
        e.contains('low') ||
        e.contains('empty') ||
        e.contains('pump on') ||
        e.contains('pump_on') ||
        e.contains('boot');
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(ts);
}

/// Hive-based local storage for all device history events.
/// Cloud syncing of critical events is done by FirebaseService.
class LocalHistoryService {
  LocalHistoryService._();

  static const String _boxPrefix = 'history_'; // per-device box
  static const int _maxLocalEntries = 5000; // auto-trim threshold per device
  static const int _trimTarget = 4500;       // trim down to this

  static final Map<String, Box<dynamic>> _openBoxes = {};

  // ── Init ────────────────────────────────────────────────────────────────

  /// Call once at app startup (after Hive.initFlutter())
  static Future<void> init() async {
    // Hive already initialised by OfflineService — nothing extra needed
    if (kDebugMode) debugPrint('[LocalHistory] Service ready (Hive-backed)');
  }

  // ── Box management ──────────────────────────────────────────────────────

  static Future<Box<dynamic>> _boxFor(String deviceId) async {
    final key = '$_boxPrefix${deviceId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}';
    if (_openBoxes.containsKey(key) && _openBoxes[key]!.isOpen) {
      return _openBoxes[key]!;
    }
    final box = await Hive.openBox(key);
    _openBoxes[key] = box;
    return box;
  }

  // ── Write ───────────────────────────────────────────────────────────────

  /// Log an event locally. Returns the saved HistoryEvent.
  static Future<HistoryEvent> logEvent({
    required String deviceId,
    required String event,
    String? extra,
    bool cloudSynced = false,
  }) async {
    final id = '${DateTime.now().millisecondsSinceEpoch}_${deviceId.hashCode.abs()}';
    final e = HistoryEvent(
      id: id,
      deviceId: deviceId,
      event: event,
      ts: DateTime.now().millisecondsSinceEpoch,
      isCloudSynced: cloudSynced,
      extra: extra,
    );
    try {
      final box = await _boxFor(deviceId);
      await box.put(id, e.toMap());
      // Auto-trim if over limit
      if (box.length > _maxLocalEntries) {
        await _trim(box, deviceId);
      }
    } catch (err) {
      if (kDebugMode) debugPrint('[LocalHistory] logEvent failed: $err');
    }
    return e;
  }

  /// Mark an event as cloud-synced (updates local record)
  static Future<void> markSynced(String deviceId, String eventId) async {
    try {
      final box = await _boxFor(deviceId);
      final raw = box.get(eventId);
      if (raw != null) {
        final m = Map<String, dynamic>.from(raw is Map ? raw : {});
        m['synced'] = true;
        await box.put(eventId, m);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[LocalHistory] markSynced failed: $e');
    }
  }

  // ── Read ────────────────────────────────────────────────────────────────

  /// Get local events for a device, sorted newest first.
  static Future<List<HistoryEvent>> getEvents(
    String deviceId, {
    int limit = 100,
    int offset = 0,
    String? filterType, // 'pump', 'mode', 'alert', 'boot', 'all'
  }) async {
    try {
      final box = await _boxFor(deviceId);
      final all = box.values
          .map((v) => HistoryEvent.fromMap(v is Map ? Map<String,dynamic>.from(v) : {}))
          .where((e) => e.deviceId == deviceId)
          .where((e) => _matchFilter(e, filterType))
          .toList()
        ..sort((a, b) => b.ts.compareTo(a.ts));

      final end = (offset + limit).clamp(0, all.length);
      if (offset >= all.length) return [];
      return all.sublist(offset, end);
    } catch (e) {
      if (kDebugMode) debugPrint('[LocalHistory] getEvents failed: $e');
      return [];
    }
  }

  /// Total event count for a device
  static Future<int> getCount(String deviceId, {String? filterType}) async {
    try {
      final box = await _boxFor(deviceId);
      return box.values
          .map((v) => HistoryEvent.fromMap(v is Map ? Map<String,dynamic>.from(v) : {}))
          .where((e) => e.deviceId == deviceId)
          .where((e) => _matchFilter(e, filterType))
          .length;
    } catch (_) {
      return 0;
    }
  }

  /// Get events grouped by day for the last N days (for chart)
  static Future<Map<DateTime, int>> getEventsByDay(
    String deviceId, {
    int days = 30,
    String? filterType,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final events = await getEvents(deviceId,
        limit: _maxLocalEntries, filterType: filterType);
    final result = <DateTime, int>{};

    // Pre-fill all days with 0
    for (int i = 0; i < days; i++) {
      final d = DateTime.now().subtract(Duration(days: days - 1 - i));
      result[DateTime(d.year, d.month, d.day)] = 0;
    }

    for (final e in events) {
      if (e.dateTime.isBefore(cutoff)) continue;
      final day = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
      result[day] = (result[day] ?? 0) + 1;
    }
    return result;
  }

  /// Pump usage stats from local history
  static Future<PumpStats> getPumpStats(String deviceId) async {
    try {
      final events = await getEvents(deviceId, limit: _maxLocalEntries);
      int pumpOnCount = 0;
      int pumpOffCount = 0;
      int alarmCount = 0;
      int dryRunCount = 0;
      int lowLevelCount = 0;

      for (final e in events) {
        final ev = e.event.toLowerCase();
        if (ev.contains('pump on') || ev.contains('pump_on')) pumpOnCount++;
        if (ev.contains('pump off') || ev.contains('pump_off')) pumpOffCount++;
        if (ev.contains('alarm')) alarmCount++;
        if (ev.contains('dry')) dryRunCount++;
        if (ev.contains('low') || ev.contains('empty')) lowLevelCount++;
      }
      return PumpStats(
        totalEvents: events.length,
        pumpOnCount: pumpOnCount,
        pumpOffCount: pumpOffCount,
        alarmCount: alarmCount,
        dryRunCount: dryRunCount,
        lowLevelCount: lowLevelCount,
      );
    } catch (_) {
      return PumpStats.empty;
    }
  }

  // ── Delete ──────────────────────────────────────────────────────────────

  /// Clear all local history for a device
  static Future<void> clearDevice(String deviceId) async {
    try {
      final box = await _boxFor(deviceId);
      await box.clear();
      if (kDebugMode) debugPrint('[LocalHistory] Cleared history for $deviceId');
    } catch (e) {
      if (kDebugMode) debugPrint('[LocalHistory] clearDevice failed: $e');
    }
  }

  // ── Merge cloud events into local ───────────────────────────────────────

  /// Import cloud events (from Firebase) into local storage.
  /// Used on first launch / fresh install to restore critical events.
  static Future<int> mergeCloudEvents(
      String deviceId, List<Map<String, dynamic>> cloudEvents) async {
    int imported = 0;
    try {
      final box = await _boxFor(deviceId);
      for (final ce in cloudEvents) {
        final tsRaw = ce['ts'];
        if (tsRaw == null) continue;
        int epoch = (tsRaw is num) ? tsRaw.toInt() : int.tryParse(tsRaw.toString()) ?? 0;
        if (epoch < 1000000000000) epoch *= 1000;
        final id = 'cloud_${epoch}_${deviceId.hashCode.abs()}';
        if (!box.containsKey(id)) {
          await box.put(id, {
            'id': id,
            'deviceId': deviceId,
            'event': ce['event']?.toString() ?? '',
            'ts': epoch,
            'synced': true,
          });
          imported++;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[LocalHistory] mergeCloudEvents failed: $e');
    }
    return imported;
  }

  // ── Private ─────────────────────────────────────────────────────────────

  static bool _matchFilter(HistoryEvent e, String? filter) {
    if (filter == null || filter == 'all') return true;
    final ev = e.event.toLowerCase();
    switch (filter) {
      case 'pump':
        return ev.contains('pump');
      case 'mode':
        return ev.contains('mode') || ev.contains('auto') || ev.contains('manual');
      case 'alert':
        return ev.contains('alarm') || ev.contains('dry') || ev.contains('low') || ev.contains('empty');
      case 'boot':
        return ev.contains('boot') || ev.contains('register') || ev.contains('ota');
      default:
        return true;
    }
  }

  static Future<void> _trim(Box<dynamic> box, String deviceId) async {
    try {
      final all = box.values
          .map((v) => HistoryEvent.fromMap(v is Map ? Map<String,dynamic>.from(v) : {}))
          .toList()
        ..sort((a, b) => a.ts.compareTo(b.ts)); // oldest first

      final toDelete = all.take(all.length - _trimTarget);
      for (final e in toDelete) {
        await box.delete(e.id);
      }
      if (kDebugMode) debugPrint('[LocalHistory] Trimmed ${toDelete.length} old entries for $deviceId');
    } catch (e) {
      if (kDebugMode) debugPrint('[LocalHistory] Trim failed: $e');
    }
  }

  static Future<void> closeAll() async {
    for (final box in _openBoxes.values) {
      if (box.isOpen) await box.close();
    }
    _openBoxes.clear();
  }
}

// ── Stats model ─────────────────────────────────────────────────────────────

class PumpStats {
  final int totalEvents;
  final int pumpOnCount;
  final int pumpOffCount;
  final int alarmCount;
  final int dryRunCount;
  final int lowLevelCount;

  const PumpStats({
    required this.totalEvents,
    required this.pumpOnCount,
    required this.pumpOffCount,
    required this.alarmCount,
    required this.dryRunCount,
    required this.lowLevelCount,
  });

  static const PumpStats empty = PumpStats(
    totalEvents: 0,
    pumpOnCount: 0,
    pumpOffCount: 0,
    alarmCount: 0,
    dryRunCount: 0,
    lowLevelCount: 0,
  );
}
