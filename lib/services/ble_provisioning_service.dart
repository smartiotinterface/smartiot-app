// lib/services/ble_provisioning_service.dart
// ══════════════════════════════════════════════════════════════════════════════
//  SmartIoT v1.0.2 — BLE Provisioning Service  [FIXED-E1-NEWLINE]
//
//  Package : flutter_esp_ble_prov ^0.1.7
//  ✅ REAL Espressif native SDK embedded (Android + iOS)
//  ✅ AGP 8.9.1 compatible
//  ✅ Android 11 (Z35) compatible — Location permission handled internally
//  ✅ Verified API from pub.dev/packages/flutter_esp_ble_prov/example
//  ✅ Flutter-side timeouts on all 3 async operations
//  ✅ Null-safe return value handling (bool? from provisionWifi)
//
//  [FIX-BLE-1] Retry cooldown timer — Android BLE GATT cleanup fix
//  ─────────────────────────────────────────────────────────────────
//  ROOT CAUSE: flutter_esp_ble_prov Android SDK leaves a semi-open BLE
//  GATT connection after a failed session. Retrying immediately causes
//  "Failed to create session" (stale GATT cache) or "Connect timeout"
//  (Android BLE stack still cleaning up previous connection).
//  FIX: Enforce a cooldown after connectAndScanWifi failures so Android's
//  BLE subsystem has time to close the GATT connection before retrying.
//
//  Cooldown schedule:
//    1st failure  → 15 seconds  (standard BLE cleanup time)
//    2nd failure  → 30 seconds  (longer delay + restart hint)
//    3rd+ failure → 60 seconds  (strong restart required hint)
//
//  API (official, verified):
//    final _ble = FlutterEspBleProv();
//    List<String>  devices  = await _ble.scanBleDevices(prefix);
//    List<String>? networks = await _ble.scanWifiNetworks(deviceName, pop);
//    bool?         ok       = await _ble.provisionWifi(deviceName, pop, ssid, password);
//
//  Firmware BLE prefix: "PROV_SmartIoT"
//  Firmware PoP (secrets.h): "Sm@rtW@t3r!BD24"
//  ESP32 advertises as: "PROV_SmartIoT_XXXXXX" (last 6 chars of serial)
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';                                 // [FIX-E1-BOND] Platform.isAndroid

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';           // [FIX-E1-BOND] MethodChannel
import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';

// ── Step enum ─────────────────────────────────────────────────────────────────
enum ProvStep {
  idle,
  scanning,    // BLE scan চলছে
  scanDone,    // device list পাওয়া গেছে
  connecting,  // BLE connect + WiFi scan চলছে
  wifiReady,   // WiFi list পাওয়া গেছে
  sending,     // credentials পাঠানো হচ্ছে
  success,     // ✅ সম্পন্ন
  failed,      // ❌ error
}

// ── Timeouts ──────────────────────────────────────────────────────────────────
const _kScanTimeout    = Duration(seconds: 15);   // BLE device scan
const _kConnectTimeout = Duration(seconds: 30);   // BLE connect + WiFi scan
const _kProvTimeout    = Duration(seconds: 45);   // WiFi provisioning

// ── [FIX-BLE-1] Cooldown durations ───────────────────────────────────────────
const _kCooldown1 = 15;   // 1st connect failure → 15s
const _kCooldown2 = 30;   // 2nd connect failure → 30s
const _kCooldown3 = 60;   // 3rd+ connect failure → 60s

// ── [FIX-BLE-2] Auto-retry & settle delay ────────────────────────────────────
const _kMaxAutoRetry  = 3;                            // auto-retry বন্ধ হবে 3 failure এর পর
const _kSettleDelay   = Duration(milliseconds: 1500); // BLE stack ready হতে দেওয়া

// ══════════════════════════════════════════════════════════════════════════════
class BleProvisioningService extends ChangeNotifier {

  // ── Plugin instance ────────────────────────────────────────────────────────
  final _ble = FlutterEspBleProv();

  // ── Constants ──────────────────────────────────────────────────────────────
  // Firmware: "PROV_SmartIoT_" + serial.substring(0, 6)
  static const String kDevicePrefix = 'PROV_SmartIoT';
  // ⚠️  Must EXACTLY match #define PROV_POP in esp32/SmartIoT_v15/secrets.h
  // ⚠️  Production-এ এই value পরিবর্তন করুন এবং secrets.h-এ একই value রাখুন
  static const String kPoP          = 'Sm@rtW@t3r!BD24'; // ✅ Production PoP — matches PROV_POP in secrets.h

  // ── [FIX-E1-BOND] Android BLE bond MethodChannel ──────────────────────────
  // MainActivity.kt-এ "clearSmartIoTBonds" method implement করা আছে।
  // Flutter এই channel দিয়ে Android-এর stale BLE bond remove করে।
  static const MethodChannel _bondChannel = MethodChannel('com.smartiot/ble_bond');

  // ── State ──────────────────────────────────────────────────────────────────
  ProvStep     _step         = ProvStep.idle;
  String       _message      = '';
  String?      _error;
  List<String> _devices      = [];
  List<String> _wifiNetworks = [];
  String?      _selectedDevice;

  // ── [FIX-BLE-1] Cooldown state ───────────────────────────────────────────
  int    _connectFailCount    = 0;   // consecutive connectAndScanWifi failures
  int    _cooldownSecondsLeft = 0;   // countdown (0 = not cooling)
  Timer? _cooldownTimer;

  // ── Public getters ─────────────────────────────────────────────────────────
  ProvStep     get step           => _step;
  String       get message        => _message;
  String?      get error          => _error;
  List<String> get devices        => List.unmodifiable(_devices);
  List<String> get wifiNetworks   => List.unmodifiable(_wifiNetworks);
  String?      get selectedDevice => _selectedDevice;

  // ── [FIX-BLE-1] Cooldown getters ─────────────────────────────────────────
  bool get isCoolingDown       => _cooldownSecondsLeft > 0;
  int  get cooldownSecondsLeft => _cooldownSecondsLeft;
  int  get connectFailCount    => _connectFailCount;
  // [FIX-BLE-2] true = cooldown শেষে auto-retry হবে; false = manual retry লাগবে
  bool get autoRetryEnabled    => _connectFailCount < _kMaxAutoRetry;

  bool get isBusy =>
      _step == ProvStep.scanning   ||
      _step == ProvStep.connecting ||
      _step == ProvStep.sending;

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1: BLE Scan
  // flutter_esp_ble_prov handles permissions internally
  // Timeout: 15s — if ESP32 not nearby, don't hang forever
  // Note: BLE scan does NOT use GATT — safe to call during cooldown
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> startBleScan() async {
    if (kIsWeb) {
      _setError('BLE provisioning web এ কাজ করে না। Android app ব্যবহার করুন।');
      return;
    }

    _setState(ProvStep.scanning, 'ble_svc_scanning:$kDevicePrefix');
    _devices         = [];
    _wifiNetworks    = [];
    _selectedDevice  = null;

    try {
      if (kDebugMode) debugPrint('[BLE] Scanning prefix=$kDevicePrefix');

      // flutter_esp_ble_prov: scanBleDevices returns List<String> device names
      // Timeout: 15s to avoid infinite hang if Bluetooth is slow
      final found = await _ble
          .scanBleDevices(kDevicePrefix)
          .timeout(_kScanTimeout, onTimeout: () {
            throw TimeoutException('BLE scan 15s timeout', _kScanTimeout);
          });

      if (kDebugMode) debugPrint('[BLE] Found: $found');

      if (found.isEmpty) {
        _setError(
          'কোনো ESP32 device পাওয়া যায়নি!\n\n'
          'নিশ্চিত করুন:\n'
          '• ESP32 চালু আছে (LED blink করছে)\n'
          '• Factory-reset অবস্থায় আছে (WiFi provisioned হয়নি)\n'
          '• ফোনের ৩ মিটারের মধ্যে আছে\n'
          '• SmartIoT v15 firmware upload হয়েছে\n\n'
          'Serial Monitor (115200 baud) এ দেখুন:\n'
          '"[PROV] Starting BLE: PROV_SmartIoT_XXXXXX"',
        );
        return;
      }

      _devices = List<String>.from(found);
      _setState(ProvStep.scanDone, 'ble_svc_found:${found.length}');

    } on TimeoutException {
      if (kDebugMode) debugPrint('[BLE] Scan timeout');
      _setError(
        'Scan timeout (15s)!\n'
        'ESP32 কাছে আনুন (৩ মিটার) এবং আবার চেষ্টা করুন।\n\n'
        'Bluetooth ও Location চালু আছে কিনা চেক করুন।',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[BLE] Scan error: $e');
      _setError(_parseError(e, 'scan'));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // [FIX-E1-BOND] Android BLE Bond Removal
  // ──────────────────────────────────────────────────────────────────────────
  // ROOT CAUSE (confirmed — GitHub espressif/esp-idf issue #9536):
  //   ESP32 WiFi provisioning এর পরে Android OS, ESP32 এর সাথে একটি BLE bond
  //   তৈরি করে রাখে। পরে ESP32 reset বা re-provision হলে পুরানো bond info
  //   মেলে না → BLE session key exchange fail → "Failed to create session" (E1)।
  //
  //   Firmware-এ ESP_LE_AUTH_NO_BOND থাকলেও Android-এ পুরানো cached bond
  //   থেকে যায় এবং connect করার সময় encrypted channel চায়, যা ESP32 দিতে পারে না।
  //
  // FIX: প্রতিটি connection attempt এর আগে "PROV_SmartIoT" prefix-এর সব
  //   Android bond remove করো। bond remove হলে Android fresh, unencrypted
  //   connection করে → ESP32 handshake সফল হয়।
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _clearStaleAndroidBonds() async {
    if (!Platform.isAndroid) return; // iOS-এ BLE bonding আলাদাভাবে কাজ করে

    try {
      final cleared = await _bondChannel.invokeMethod<int>(
        'clearSmartIoTBonds',
        {'prefix': kDevicePrefix}, // 'PROV_SmartIoT'
      );

      if (cleared != null && cleared > 0) {
        if (kDebugMode) {
          debugPrint('[BLE-BOND] $cleared টি পুরানো Android bond মোছা হয়েছে — E1 রোধ হবে');
        }
        // Bond remove হতে Android কে সামান্য সময় দাও
        await Future.delayed(const Duration(milliseconds: 600));
      } else {
        if (kDebugMode) debugPrint('[BLE-BOND] কোনো stale bond ছিল না');
      }
    } catch (e) {
      // best-effort: bond clear না হলেও crash করবে না
      // worst case: E1 হলে cooldown+retry এখনো কাজ করবে
      if (kDebugMode) debugPrint('[BLE-BOND] Bond clear skip: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 2: Connect to device + Scan WiFi networks
  // flutter_esp_ble_prov: scanWifiNetworks(deviceName, pop) → List<String>?
  // Timeout: 30s — BLE connect + WiFi scan একসাথে করে
  //
  // [FIX-BLE-1] On failure: starts cooldown timer so Android BLE stack
  //   has time to close the GATT connection before the next retry.
  //   connectFailCount increases with each failure; cooldown grows accordingly.
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> connectAndScanWifi(String deviceName) async {
    // [FIX-BLE-1] Block connect during cooldown — GATT not yet cleaned up
    if (isCoolingDown) {
      if (kDebugMode) {
        debugPrint('[BLE] Blocked: Android BLE cooling down ($_cooldownSecondsLeft s left)');
      }
      return;
    }

    _selectedDevice = deviceName;
    _setState(ProvStep.connecting, 'ble_svc_connecting:$deviceName');

    try {
      if (kDebugMode) debugPrint('[BLE] WiFi scan for: $deviceName  PoP: $kPoP');

      // [FIX-E1-BOND] Android-এর stale BLE bond remove করো (E1 এর real root cause)
      // এটা না করলে Android পুরানো encrypted channel দিয়ে connect করার চেষ্টা করে
      // এবং ESP32 session establish করতে পারে না → E1 error।
      await _clearStaleAndroidBonds();

      // [FIX-BLE-2] BLE stack কে settle হতে সময় দাও (1.5s)
      // Android BLE advertisement → GATT connect handover এ সামান্য বিলম্ব দরকার
      await Future.delayed(_kSettleDelay);

      // flutter_esp_ble_prov: scanWifiNetworks handles BLE connect + WiFi scan
      // Timeout: 30s — BLE pairing + scan takes up to ~20s
      final networks = await _ble
          .scanWifiNetworks(deviceName, kPoP)
          .timeout(_kConnectTimeout, onTimeout: () {
            throw TimeoutException('BLE connect + WiFi scan 30s timeout', _kConnectTimeout);
          });

      if (kDebugMode) debugPrint('[BLE] WiFi networks: $networks');

      // ✅ Success — reset failure counter
      _connectFailCount = 0;

      _wifiNetworks = networks
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();

      if (_wifiNetworks.isEmpty) {
        _setState(ProvStep.wifiReady, 'ble_svc_no_wifi');
      } else {
        _setState(ProvStep.wifiReady, 'ble_svc_wifi_found:${_wifiNetworks.length}');
      }

    } on TimeoutException {
      if (kDebugMode) debugPrint('[BLE] Connect timeout');
      _connectFailCount++;
      // [FIX-BLE-1] Start cooldown — let Android BLE stack finish cleanup
      _startCooldown(_cooldownForFailCount(_connectFailCount));

      final extraHint = _connectFailCount >= 3
          ? '\n\n⚠️ ESP32 power off করে ৫ সেকেন্ড অপেক্ষা করে আবার চালু করুন।'
          : '';

      _setError(
        'Connect timeout (30s)!\n\n'
        '• ESP32 কাছে আনুন\n'
        '• ESP32 restart করুন (Power off → on)\n'
        '• PoP মিলছে কিনা দেখুন: $kPoP\n'
        '• Serial Monitor: "[PROV] Starting BLE:" দেখাচ্ছে কিনা চেক করুন'
        '$extraHint',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[BLE] WiFi scan error: $e');
      _connectFailCount++;
      // [FIX-BLE-1] Start cooldown — GATT state must settle before retry
      _startCooldown(_cooldownForFailCount(_connectFailCount));
      _setError(_parseError(e, 'connect'));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 2b: Refresh WiFi scan
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> refreshWifiScan() async {
    if (_selectedDevice == null) return;
    await connectAndScanWifi(_selectedDevice!);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 3: Send WiFi credentials → ESP32
  // flutter_esp_ble_prov: provisionWifi(deviceName, pop, ssid, password) → bool?
  // Timeout: 45s — WiFi connection can take up to ~30s
  // Null safety: bool? return — null treated as failure
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> sendCredentials({
    required String ssid,
    required String password,
  }) async {
    if (ssid.trim().isEmpty) {
      _setError('ble_svc_ssid_empty');
      return;
    }
    if (_selectedDevice == null) {
      _setError('ble_svc_no_device_selected');
      return;
    }

    _setState(ProvStep.sending, 'ble_svc_sending:$ssid');

    try {
      if (kDebugMode) {
        debugPrint('[BLE] Provisioning "$ssid" → ${_selectedDevice!}');
      }

      // flutter_esp_ble_prov: provisionWifi returns bool?
      // null means plugin error — treat as failure
      // Timeout: 45s — ESP32 WiFi connect can take up to ~30s
      final result = await _ble
          .provisionWifi(
            _selectedDevice!,
            kPoP,
            ssid.trim(),
            password,
          )
          .timeout(_kProvTimeout, onTimeout: () {
            throw TimeoutException('WiFi provisioning 45s timeout', _kProvTimeout);
          });

      if (kDebugMode) debugPrint('[BLE] Provision result: $result');

      if (result == true) {
        _connectFailCount = 0;  // reset on success
        _setState(ProvStep.success, 'ble_svc_success:$ssid');
      } else if (result == null) {
        // Plugin returned null — internal SDK error
        _setError(
          'ble_svc_prov_failed:Plugin error (null result)\n'
          'ESP32 restart করে আবার চেষ্টা করুন।',
        );
      } else {
        // result == false
        _setError(
          'ble_svc_prov_failed:WiFi connect হয়নি!\n'
          'SSID "$ssid" ও Password আবার চেক করুন।',
        );
      }

    } on TimeoutException {
      if (kDebugMode) debugPrint('[BLE] Provision timeout');
      _setError(
        'ble_svc_prov_failed:Provisioning timeout (45s)!\n\n'
        '• ESP32 WiFi range এ আছে কিনা দেখুন\n'
        '• 2.4GHz WiFi ব্যবহার করুন (ESP32 5GHz সাপোর্ট করে না)\n'
        '• SSID ও Password সঠিক কিনা দেখুন\n'
        '• ESP32 restart করে আবার চেষ্টা করুন',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[BLE] Provision error: $e');
      _setError(_parseError(e, 'provision'));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Reset — clears all state including cooldown
  // ══════════════════════════════════════════════════════════════════════════
  void reset() {
    _cancelCooldown();          // [FIX-BLE-1]
    _connectFailCount = 0;      // [FIX-BLE-1]
    _devices        = [];
    _wifiNetworks   = [];
    _selectedDevice = null;
    _step           = ProvStep.idle;
    _message        = '';
    _error          = null;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // [FIX-BLE-1] Cooldown — Android BLE GATT cleanup timer
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns cooldown duration (seconds) based on consecutive failure count.
  int _cooldownForFailCount(int count) {
    if (count <= 1) return _kCooldown1;  // 1st failure: 15s
    if (count == 2) return _kCooldown2;  // 2nd failure: 30s
    return _kCooldown3;                  // 3rd+ failure: 60s
  }

  /// Starts the countdown timer. Notifies listeners every second.
  void _startCooldown(int seconds) {
    _cancelCooldown();
    _cooldownSecondsLeft = seconds;
    if (kDebugMode) {
      debugPrint('[BLE] Cooldown started: ${seconds}s (fail #$_connectFailCount)'
          ' — auto-retry: ${_connectFailCount < _kMaxAutoRetry}');
    }
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldownSecondsLeft <= 1) {
        _cooldownSecondsLeft = 0;
        t.cancel();
        _cooldownTimer = null;
        if (kDebugMode) debugPrint('[BLE] Cooldown done');

        // [FIX-BLE-2] Auto-retry: cooldown শেষে automatically connectAndScanWifi চালাও
        // শর্ত: device জানা আছে + step failed + fail count max এ পৌঁছায়নি
        if (_step == ProvStep.failed &&
            _selectedDevice != null &&
            _connectFailCount < _kMaxAutoRetry) {
          if (kDebugMode) debugPrint('[BLE] Auto-retry #$_connectFailCount for $_selectedDevice');
          connectAndScanWifi(_selectedDevice!);  // auto-retry — user দেখবে automatically
          return; // connectAndScanWifi notifyListeners নিজেই করবে
        }
      } else {
        _cooldownSecondsLeft--;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  /// Cancels any active cooldown without notifying.
  void _cancelCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer       = null;
    _cooldownSecondsLeft = 0;
  }

  @override
  void dispose() {
    _cancelCooldown();  // [FIX-BLE-1] ensure timer is cancelled on dispose
    super.dispose();
  }

  // ── Private helpers ────────────────────────────────────────────────────────
  void _setState(ProvStep step, String message) {
    _step    = step;
    _message = message;
    _error   = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _step    = ProvStep.failed;
    _message = 'ble_svc_error';
    _error   = msg;
    notifyListeners();
  }

  String _parseError(Object e, String context) {
    final msg = e.toString().toLowerCase();

    // [FIX-BLE-2] E1 = Espressif SDK session/security handshake failure
    // PlatformException(E1, WiFi scan failed, java.lang.RuntimeException: Failed to create session.)
    if (msg.contains('e1') || msg.contains('failed to create session') ||
        (msg.contains('wifi scan failed') && msg.contains('session'))) {
      return 'BLE session error (E1)!\n\n'
          'Android এর পুরানো BLE GATT connection এখনো close হয়নি।\n'
          'Auto-retry countdown শেষে automatically আবার চেষ্টা হবে।\n\n'
          'এরপরেও বারবার হলে:\n'
          '• ESP32 power OFF করুন → ৫ সেকেন্ড অপেক্ষা → power ON\n'
          '• তারপর "Try Again" চাপুন';
    }
    if (msg.contains('permission') || msg.contains('denied')) {
      return 'Permission দেওয়া নেই!\n'
          'Settings → Apps → SmartIoT → Permissions:\n'
          '• Nearby devices → Allow\n'
          '• Location → Allow (Android 11-এ BLE scan-এর জন্য)';
    }
    if (msg.contains('bluetooth') &&
        (msg.contains('off') || msg.contains('disabled'))) {
      return 'Bluetooth বন্ধ আছে! চালু করুন।';
    }
    if (msg.contains('location') && msg.contains('off')) {
      return 'Location বন্ধ আছে!\n'
          'Android 11-এ BLE scan করতে Location চালু রাখতে হয়।';
    }
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return 'Timeout!\nESP32 কাছে আনুন (৩ মিটার) এবং আবার চেষ্টা করুন।';
    }
    if (msg.contains('session') || msg.contains('create session')) {
      // [FIX-BLE-1] "Failed to create session" is a known Android BLE GATT
      // cache issue — cooldown has already been started by caller
      return 'BLE session error!\n\n'
          'Android BLE stack এর পুরানো connection clean হচ্ছে।\n'
          'Cooldown শেষ হলে automatically retry সম্ভব হবে।\n\n'
          'এরপরেও সমস্যা হলে:\n'
          '• ESP32 power off → ৫ সেকেন্ড অপেক্ষা → power on\n'
          '• তারপর "Try Again" চাপুন';
    }
    if (msg.contains('pop') || msg.contains('proof')) {
      return 'Security mismatch!\nESP32 firmware এ PoP চেক করুন: $kPoP\n'
          'secrets.h এ PROV_POP এর সাথে মিলছে কিনা দেখুন।';
    }
    if (context == 'provision') {
      return 'Provisioning failed!\n'
          'SSID ও Password চেক করুন।\n'
          'ESP32 restart করে আবার চেষ্টা করুন।';
    }
    return 'Error ($context): '
        '${e.toString().length > 150 ? e.toString().substring(0, 150) : e}\n\n'
        'ESP32 restart করে আবার চেষ্টা করুন।';
  }
}
