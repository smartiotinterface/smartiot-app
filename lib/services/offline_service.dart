// lib/services/offline_service.dart
// [FIX MEDIUM-4] Pending command queue added
// Hive-based offline cache for:
//   (a) last-known device status — shows stale data when offline
//   (b) pending commands queue — replays on reconnect, no lost commands

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class OfflineService {
  OfflineService._();

  static const String _cacheBoxName  = 'device_cache';
  static const String _queueBoxName  = 'cmd_queue';
  static const String _keyPrefix     = 'status_';
  static const String _queueKey      = 'pending_cmds';

  static Box<dynamic>? _cacheBox;
  static Box<dynamic>? _queueBox;

  // ── Init ─────────────────────────────────────────────────────────────
  static Future<void> init() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox(_cacheBoxName);
    _queueBox = await Hive.openBox(_queueBoxName);
    if (kDebugMode) { debugPrint('[Offline] Hive ready — cache: ${_cacheBox!.length} entries, '
               'queue: $pendingCommandCount pending'); }
  }

  // ── Status cache ─────────────────────────────────────────────────────
  static Future<void> saveStatus(
      String deviceId, Map<String, dynamic> status) async {
    if (_cacheBox == null || !_cacheBox!.isOpen) return;
    try {
      await _cacheBox!.put('$_keyPrefix$deviceId', {
        ...status,
        '_cached_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[Offline] Save status failed: $e');
    }
  }

  static Map<String, dynamic>? loadStatus(String deviceId) {
    if (_cacheBox == null || !_cacheBox!.isOpen) return null;
    try {
      final raw = _cacheBox!.get('$_keyPrefix$deviceId');
      if (raw == null) return null;
      return raw is Map ? Map<String, dynamic>.from(raw) : null;
    } catch (e) {
      if (kDebugMode) debugPrint('[Offline] Load status failed: $e');
      return null;
    }
  }

  static Duration? cacheAge(String deviceId) {
    final data = loadStatus(deviceId);
    if (data == null) return null;
    final cachedAt = data['_cached_at'] as int?;
    if (cachedAt == null) return null;
    return DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(cachedAt));
  }

  static Future<void> clearDevice(String deviceId) async {
    await _cacheBox?.delete('$_keyPrefix$deviceId');
  }

  static Future<void> clearAll() async {
    await _cacheBox?.clear();
  }

  // ── Pending command queue ─────────────────────────────────────────────
  // Each entry: { 'deviceId': ..., 'type': 'pump'|'mode'|'dry_run_reset',
  //               'value': ..., 'queuedAt': epoch_ms }

  static int get pendingCommandCount {
    if (_queueBox == null || !_queueBox!.isOpen) return 0;
    final raw = _queueBox!.get(_queueKey);
    if (raw == null) return 0;
    return raw is List ? raw.length : 0;
  }

  /// Enqueue a command that failed due to being offline.
  static Future<void> enqueueCommand({
    required String deviceId,
    required String type,   // 'pump', 'mode', 'dry_run_reset'
    String? value,          // 'ON'|'OFF' for pump, 'AUTO'|'MANUAL' for mode
  }) async {
    if (_queueBox == null || !_queueBox!.isOpen) return;
    try {
      final raw0 = _queueBox!.get(_queueKey, defaultValue: <dynamic>[]);
      final List<dynamic> queue = List.from(raw0 is List ? raw0 : <dynamic>[]);
      // Deduplicate: if same deviceId+type already queued, replace it
      queue.removeWhere((e) =>
          e is Map && e['deviceId'] == deviceId && e['type'] == type);
      queue.add({
        'deviceId': deviceId,
        'type': type,
        'value': value,
        'queuedAt': DateTime.now().millisecondsSinceEpoch,
      });
      await _queueBox!.put(_queueKey, queue);
      if (kDebugMode) debugPrint('[Offline] Command queued: $type for $deviceId');
    } catch (e) {
      if (kDebugMode) debugPrint('[Offline] Enqueue failed: $e');
    }
  }

  /// Returns all pending commands and clears the queue.
  static Future<List<Map<String, dynamic>>> drainQueue() async {
    if (_queueBox == null || !_queueBox!.isOpen) return [];
    try {
      final raw = _queueBox!.get(_queueKey);
      if (raw == null) return [];
      final cmds = List<Map<String, dynamic>>.from(
          (raw is List ? raw : []).map((e) => e is Map ? Map<String, dynamic>.from(e) : <String,dynamic>{}));
      await _queueBox!.delete(_queueKey);
      return cmds;
    } catch (e) {
      if (kDebugMode) debugPrint('[Offline] Drain failed: $e');
      return [];
    }
  }

  // ── Close Hive ────────────────────────────────────────────────────────
  static Future<void> close() async {
    await _cacheBox?.close();
    await _queueBox?.close();
  }
}
