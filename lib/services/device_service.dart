// lib/services/device_service.dart
// SmartIoT v8.0.0
// [FIX CRITICAL] _DeviceSelector showed same name for all devices
// [FIX HIGH-7] FirebaseService is singleton — DI injected, not new instance
// [FIX HIGH-8] Stream auto-reconnects on error with exponential backoff
// [FIX HIGH-9] User device index used for lookup
// [FIX MEDIUM-10] Theme persistence via SharedPreferences
// [FIX LOW-14] Conflict handling on addDevice
// [FIX BUG-6] togglePump/toggleMode/resetDryRun now have 10s timeout → no UI freeze
// [FIX OFFLINE] OfflineService now wired: saveStatus on every update, loadStatus on selectDevice

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/device_model.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import 'offline_service.dart';

class DeviceService extends ChangeNotifier {
  final FirebaseService _fb;
  final String uid;

  DeviceService({required this.uid, required FirebaseService firebaseService})
      : _fb = firebaseService;

  List<String> _deviceIds = [];
  String? _selectedDeviceId;
  DeviceStatus? _status;
  DeviceMeta? _meta;
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  bool _isOffline = false;
  StreamSubscription<DeviceStatus?>? _statusSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  int _retryCount = 0;
  Timer? _retryTimer;
  bool _wasConnected = true;

  final Map<String, String> _deviceNames = {};

  List<String> get deviceIds => _deviceIds;
  String? get selectedDeviceId => _selectedDeviceId;
  DeviceStatus? get status => _status;
  DeviceMeta? get meta => _meta;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  bool get hasDevice => _selectedDeviceId != null;
  bool get isOffline => _isOffline;

  String deviceName(String deviceId) =>
      _deviceNames[deviceId] ?? deviceId;

  bool get isDeviceOnline {
    final ts = _status?.timestamp;
    if (ts == null) return false;
    try {
      int epoch = (ts is String) ? int.parse(ts) : (ts as num).toInt();
      if (epoch < 1000000000000) epoch *= 1000;
      final lastSeen = DateTime.fromMillisecondsSinceEpoch(epoch);
      return DateTime.now().difference(lastSeen) < AppConstants.offlineThreshold;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    _setupConnectivityListener();
    try {
      _deviceIds = await _fb.getUserDevices(uid);

      if (_deviceIds.isNotEmpty) {
        final metaMap = await _fb.getMetaForDevices(_deviceIds);
        _deviceNames.clear();
        for (final entry in metaMap.entries) {
          _deviceNames[entry.key] = entry.value.deviceName;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getString(AppConstants.prefLastDeviceId);
      if (lastId != null && _deviceIds.contains(lastId)) {
        await selectDevice(lastId);
      } else if (_deviceIds.isNotEmpty && _selectedDeviceId == null) {
        await selectDevice(_deviceIds.first);
      }
    } catch (e) {
      _error = 'err_load_devices'; // [v8.0.0] l10n key — UI resolves this
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectDevice(String deviceId) async {
    if (_selectedDeviceId == deviceId) return;
    _selectedDeviceId = deviceId;
    _status = null;
    _isOffline = false;
    _retryCount = 0;
    notifyListeners();

    // [FIX OFFLINE] Load cached status immediately so UI shows something
    final cached = OfflineService.loadStatus(deviceId);
    if (cached != null) {
      try {
        _status = DeviceStatus.fromMap(
            cached.map((k, v) => MapEntry(k, v)));
        _isOffline = true; // show stale banner until live data arrives
        notifyListeners();
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLastDeviceId, deviceId);

    _subscribeToStatus(deviceId);

    _meta = await _fb.getMeta(deviceId);
    if (_meta != null) {
      _deviceNames[deviceId] = _meta!.deviceName;
    }
    notifyListeners();
  }

  // ── Connectivity monitoring — auto-reconnect on network restore ──────────
  void _setupConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (results) {
        final connected = results.any((r) => r != ConnectivityResult.none);
        if (connected && !_wasConnected) {
          // Network just came back — re-subscribe immediately
          if (kDebugMode) debugPrint('[DeviceService] Network restored — reconnecting...');
          if (_selectedDeviceId != null) {
            _retryCount = 0;
            _retryTimer?.cancel();
            _subscribeToStatus(_selectedDeviceId!);
          }
        }
        _wasConnected = connected;
      },
    );
  }

  void _subscribeToStatus(String deviceId) {
    _statusSub?.cancel();
    _retryTimer?.cancel();

    bool queueDrained = false; // [FIX-5] drain once per connect, not every 15s
    _statusSub = _fb.statusStream(deviceId).listen(
      (s) async {
        // [FIX MEDIUM-4] On reconnect, drain queued commands — only ONCE, not every 15s
        if (!queueDrained) {
          queueDrained = true;
          final pending = await OfflineService.drainQueue();
          for (final cmd in pending) {
            if (cmd['deviceId'] != deviceId) continue;
            try {
              switch (cmd['type']) {
                case 'pump':
                  await _fb.sendPumpCommand(deviceId, cmd['value']?.toString() ?? '')
                      .timeout(AppConstants.commandTimeout);
                  break;
                case 'mode':
                  await _fb.sendModeCommand(deviceId, cmd['value']?.toString() ?? '')
                      .timeout(AppConstants.commandTimeout);
                  break;
                case 'dry_run_reset':
                  await _fb.sendDryRunReset(deviceId)
                      .timeout(AppConstants.commandTimeout);
                  break;
              }
              if (kDebugMode) debugPrint('[DeviceService] Replayed offline cmd: ${cmd['type']}');
            } catch (e) {
              if (kDebugMode) debugPrint('[DeviceService] Replay failed: $e');
            }
          }
        } // end queueDrained guard

        // [FIX OFFLINE] Save every live update to Hive cache
        if (s != null && deviceId == _selectedDeviceId) {
          _saveStatusToCache(deviceId, s);
        }

        // [FREE ALTERNATIVE] Client-side notifications
        _checkAndNotify(_status, s, deviceId);
        _status = s;
        _isOffline = false; // live data arrived — no longer stale
        _retryCount = 0;
        notifyListeners();
      },
      onError: (e) {
        _error = 'svc_reconnecting';
        notifyListeners();
        _scheduleRetry(deviceId);
      },
      onDone: () {
        _scheduleRetry(deviceId);
      },
    );
  }

  // [FIX OFFLINE] Save DeviceStatus fields to OfflineService cache
  void _saveStatusToCache(String deviceId, DeviceStatus s) {
    final map = <String, dynamic>{
      AppConstants.fieldWaterLevel:    s.waterLevel,
      AppConstants.fieldWaterLevelPct: s.waterLevelPct,
      AppConstants.fieldPumpState:     s.pumpState,
      AppConstants.fieldPumpMode:      s.pumpMode,
      AppConstants.fieldSensorMode:    s.sensorMode,
      AppConstants.fieldWifiRssi:      s.wifiRssi,
      AppConstants.fieldUptime:        s.uptime,
      AppConstants.fieldTimestamp:     s.timestamp,
      AppConstants.fieldAlarm:         s.alarmActive,
      AppConstants.fieldDryRun:        s.dryRunActive,
      AppConstants.fieldPumpCycles:    s.pumpCycles,
      AppConstants.fieldPumpTotalS:    s.pumpTotalSeconds,
      AppConstants.fieldBootCount:     s.bootCount,
      AppConstants.fieldHeapFree:      s.heapFree,
    };
    OfflineService.saveStatus(deviceId, map);
  }

  void _scheduleRetry(String deviceId) {
    if (_selectedDeviceId != deviceId) return;
    _retryCount++;
    // [FIX MEDIUM-3] Exponential backoff with jitter: 2^n + random(0-4)s, max ~37s
    // Prevents thundering-herd when many devices reconnect simultaneously
    final exp = (1 << _retryCount.clamp(0, 5)); // 2, 4, 8, 16, 32
    final jitter = (DateTime.now().millisecondsSinceEpoch % 5).toInt();
    final delaySec = (exp + jitter).clamp(2, 40);
    _retryTimer = Timer(Duration(seconds: delaySec), () {
      if (_selectedDeviceId == deviceId) {
        _subscribeToStatus(deviceId);
      }
    });
  }

  Future<DeviceAddResult> addDevice(String serial, String name) async {
    final existingOwner = await _fb.checkDeviceClaimed(serial);
    if (existingOwner != null && existingOwner != uid) {
      return DeviceAddResult.alreadyClaimed;
    }
    if (existingOwner == uid || _deviceIds.contains(serial)) {
      if (!_deviceIds.contains(serial)) _deviceIds.add(serial);
      _deviceNames[serial] = name;
      await selectDevice(serial);
      notifyListeners();
      return DeviceAddResult.alreadyOwned;
    }

    try {
      await _fb.claimDevice(serial, uid);
      final meta = DeviceMeta(
        serial: serial,
        firmware: '--',
        deviceName: name,
        ownerId: uid,
        registeredAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      await _fb.setMeta(serial, meta);
      await _fb.logEvent(serial, 'Device registered'); // [FIX] removed duplicate LocalHistoryService call — _fb.logEvent() handles local+cloud
      _deviceIds.add(serial);
      _deviceNames[serial] = name;
      notifyListeners();
      await selectDevice(serial);
      return DeviceAddResult.success;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('permission-denied') || msg.contains('Permission denied')) {
        _error = 'Database permission denied.\n'
            'Go to Firebase Console → Realtime Database → Rules\n'
            'and deploy firebase/database.rules.json';
      } else if (msg.contains('network') || msg.contains('timeout')) {
        _error = 'Network error. Check your internet connection.';
      } else {
        _error = 'Failed to register device. (${msg.length > 60 ? msg.substring(0, 60) : msg})';
      }
      notifyListeners();
      return DeviceAddResult.error;
    }
  }

  // [FIX BUG-6]: timeout added — isSending can no longer freeze forever
  // [FIX MEDIUM-4]: enqueue command if offline so it's replayed on reconnect
  Future<bool> togglePump() async {
    if (_selectedDeviceId == null || _status == null) return false;
    _isSending = true;
    _error = null;
    notifyListeners();
    final cmd = _status!.isPumpOn ? AppConstants.pumpOff : AppConstants.pumpOn;
    try {
      await _fb
          .sendPumpCommand(_selectedDeviceId!, cmd)
          .timeout(AppConstants.commandTimeout, onTimeout: () {
        throw TimeoutException('Command timed out');
      });
      await _fb.logEvent(_selectedDeviceId!, 'Pump command: $cmd'); // [FIX] removed duplicate LocalHistoryService call
      _isSending = false;
      notifyListeners();
      return true;
    } on TimeoutException {
      _error = 'Offline — pump command queued, will send on reconnect.';
      await OfflineService.enqueueCommand(
          deviceId: _selectedDeviceId!, type: 'pump', value: cmd);
      _isSending = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Command failed. Please try again.';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  // [FIX BUG-6]: timeout added
  // [FIX MEDIUM-4]: enqueue if offline
  Future<bool> toggleMode() async {
    if (_selectedDeviceId == null || _status == null) return false;
    _isSending = true;
    _error = null;
    notifyListeners();
    final cmd = _status!.isAutoMode ? AppConstants.modeManual : AppConstants.modeAuto;
    try {
      await _fb
          .sendModeCommand(_selectedDeviceId!, cmd)
          .timeout(AppConstants.commandTimeout, onTimeout: () {
        throw TimeoutException('Command timed out');
      });
      await _fb.logEvent(_selectedDeviceId!, 'Mode changed to: $cmd'); // [FIX] removed duplicate LocalHistoryService call
      _isSending = false;
      notifyListeners();
      return true;
    } on TimeoutException {
      _error = 'Offline — mode change queued, will send on reconnect.';
      await OfflineService.enqueueCommand(
          deviceId: _selectedDeviceId!, type: 'mode', value: cmd);
      _isSending = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Mode switch failed. Please try again.';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  // [FIX BUG-6]: timeout added
  // [FIX MEDIUM-4]: enqueue if offline
  Future<bool> resetDryRun() async {
    if (_selectedDeviceId == null) return false;
    _isSending = true;
    _error = null;
    notifyListeners();
    try {
      await _fb
          .sendDryRunReset(_selectedDeviceId!)
          .timeout(AppConstants.commandTimeout, onTimeout: () {
        throw TimeoutException('Reset timed out');
      });
      _isSending = false;
      notifyListeners();
      return true;
    } on TimeoutException {
      _error = 'Offline — dry-run reset queued, will send on reconnect.';
      await OfflineService.enqueueCommand(
          deviceId: _selectedDeviceId!, type: 'dry_run_reset');
      _isSending = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Reset failed.';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _retryTimer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  // ── Local Notification Triggers (FREE — no Cloud Functions needed) ───────
  void _checkAndNotify(DeviceStatus? before, DeviceStatus? after, String deviceId) {
    if (before == null || after == null) return;
    final name = _deviceNames[deviceId] ?? deviceId;

    if (before.dryRunActive != true && after.dryRunActive == true) {
      NotificationService.showLocalAlert(
        title: '⚠️ Dry Run Alert!',
        body: '$name: Pump running without water! Level: ${after.waterLevelPct}%',
      );
    }
    if (before.alarmActive != true && after.alarmActive == true) {
      NotificationService.showLocalAlert(
        title: '🚨 Alarm Active',
        body: '$name: Alert active! Water level: ${after.waterLevel} (${after.waterLevelPct}%)',
      );
    }
    if (before.pumpState == 'OFF' && after.pumpState == 'ON') {
      NotificationService.showLocalAlert(
        title: '💧 Pump Started',
        body: '$name: Pump running. Water level: ${after.waterLevelPct}%',
      );
    }
    if (before.pumpState == 'ON' && after.pumpState == 'OFF') {
      NotificationService.showLocalAlert(
        title: '✅ Pump Stopped',
        body: '$name: Pump stopped. Water level: ${after.waterLevelPct}%',
      );
    }
    final prevPct = before.waterLevelPct;
    final curPct = after.waterLevelPct;
    if (curPct <= 10 && prevPct > 10) {
      NotificationService.showLocalAlert(
        title: '🪣 Water Low!',
        body: '$name: Water level dangerously low ($curPct%)',
      );
    }
    if (curPct >= 90 && prevPct < 90) {
      NotificationService.showLocalAlert(
        title: '🎉 Tank Full!',
        body: '$name: Tank is full ($curPct%)',
      );
    }
  }

}

enum DeviceAddResult { success, alreadyClaimed, alreadyOwned, error }
