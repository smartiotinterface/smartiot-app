<<<<<<< HEAD
# SmartIoT v1.0.2 — Smart Water Tank Monitor 🇧🇩

**ESP32 + Firebase + Flutter** দিয়ে তৈরি পানির ট্যাংক monitoring ও control system।

> **App: v1.0.2 (Play Store first release) | Firmware: v15.0.1** | Developer: Sobuj Billah — SMART IoT Interface
> ℹ️ Internal development history (v3.5 → v8.2.8) `CHANGELOG.md`-এ সংরক্ষিত — কখনো প্রকাশ হয়নি, ১.০.০ থেকে Semantic Versioning শুরু।
> 📦 এই ZIP-এ security sanitization apply করা আছে — deploy করার আগে **`SECURITY.md`** পড়ুন এবং নতুন Firebase DB Secret, AES Key ও Keystore তৈরি করুন।

---

## অ্যাপ ↔ ESP32 কানেকশনের ২টি পদ্ধতি

```
১. BLE (প্রথমবার WiFi setup)
   App ◄─── BLE (flutter_esp_ble_prov) ───► ESP32

২. Firebase (সব সময়)
   App ──► Firebase RTDB ◄── ESP32
```

## BLE Flow (প্রথমবার)

| ধাপ | কী হয় |
|-----|-------|
| App → ESP32 | `flutter_esp_ble_prov` দিয়ে BLE scan (`PROV_SmartIoT_...` prefix) |
| ESP32 → App | WiFi network list পাঠায় |
| App → ESP32 | SSID + Password (PoP দিয়ে এনক্রিপ্টেড) পাঠায় |
| ESP32 → App | `CONNECTED:<IP>` |
| App | Device auto-register করে Firebase-এ |

এরপর সব যোগাযোগ **Firebase RTDB-এর মাধ্যমে** — BLE আর লাগে না, যতক্ষণ না factory reset হয়। Provision না করলে ESP32 ৩ মিনিট পর নিজে restart হয়ে আবার scan-যোগ্য হয় (`PROV_INACTIVITY_MS`)।

## Firebase Data Structure (rules.json অনুযায়ী, verified)

```
/devices/{deviceId}/
  status/            ← ESP32 লেখে
    water_level, water_level_pct, pump, mode, sensor_mode,
    wifi_rssi, uptime, firmware, serial, bd_time, sleeping,
    alarm, dry_run, pump_cycles, pump_total_s, boot_count, heap_free, ts
  control/           ← App লেখে
    pump_cmd, mode_cmd, cmd_ts, ota_url, ota_sha256,
    dry_run_reset, mute_cmd
  history/{entry}/   ← App লেখে (critical events only)
  meta/              ← device_name, owner_id, calibration, thresholds, flow_rate_lpm
  alerts/lastAuto/

/device_owners/{deviceId}      → owner uid
/device_shared/{deviceId}/{uid} → shared-access uid
/users/{uid}/                  → devices, shared_devices, preferences, profile, fcmToken
/schedules/{deviceId}/{id}/    → hour, minute, duration_min, action, active
/scenes/{deviceId}/{id}/       → name, pumpCmd, modeCmd, icon, color
/automations/{deviceId}/{id}/  → triggerType, triggerValue, actionType, enabled
/user_lookup/{emailKey}        → uid (sharing-by-email lookup)
```

Every collection has a `$other: {".validate": false}` catch-all and the root has `$other: {read:false, write:false}` — unknown paths/fields are rejected by default.

## Quick Start (Flutter)

```powershell
flutter pub get
flutter gen-l10n
flutter run
```
(`build_runner`/codegen বাদ দেওয়া হয়েছে v8.2.8 হাউসকিপিং-এ — প্রজেক্টে কোনো `@HiveType`/`.g.dart` কোডজেন নেই, তাই এটা আগে থেকেই কার্যত no-op ছিল।)

## ESP32 Firmware v15.0.1

**⚠️ দুটো ফোল্ডার আছে — কনফিউশন এড়াতে পড়ো:**

| ফোল্ডার | অবস্থা |
|---|---|
| `esp32/SmartIoT_v15/SmartIoT_v15.ino` | ✅ **এটা ব্যবহার করো।** WiFi reason-201 (NO_AP_FOUND) ফিক্স ও 2.4GHz-only protocol force ফিক্স — দুটোই আছে। |
| `esp32/SmartIoT_v15 upgrade/SmartIoT_v15.ino` | ⚠️ একই ভার্সন নাম্বার (v15.0.1) কিন্তু উপরের দুটো WiFi ফিক্স **নেই**। সম্ভবত আগের কোনো snapshot। |

**Secrets:** `esp32/SmartIoT_v15/secrets.h` (⚠️ gitignored — কখনো commit করবেন না)

### secrets.h এ যা পূরণ করতে হবে:
```c
#define FIREBASE_HOST       "smartiot-8190a-default-rtdb.firebaseio.com"
#define FIREBASE_DB_SECRET  "your-firebase-database-secret"
#define PROV_POP            "Sm@rtW@t3r!BD24"  // Flutter-এর kPoP এর সাথে মিলতে হবে
#define TEST_WIFI_ENABLED   0   // ⚠️ Production-এ অবশ্যই 0 — 1 মানে BLE bypass
```

### Arduino IDE Settings:
- **Board:** ESP32 Dev Module
- **Partition Scheme:** No OTA (2MB APP/2MB SPIFFS) ⚠️ গুরুত্বপূর্ণ

### v15.0.1 মূল ফিচার:
- ✅ BLE provisioning cooldown (15s→30s→60s retry escalation) + 3-min inactivity auto-restart
- ✅ OTA: SHA-256 mandatory + Firebase Storage URL whitelist + TLS root-CA pinning
- ✅ Watchdog fed in WiFi/Prov callbacks, OTA loop, deep-sleep path
- ✅ AES-256 random IV per encryption (`esp_fill_random`), `PRODUCTION_MODE` strips Serial output
- ✅ Dry-run protection, automation rules evaluated on-device

## GPIO Summary (firmware-এর constexpr থেকে verified)

| GPIO | Function |
|------|----------|
| 16 | Pump Relay (`RELAY_ACTIVE_HIGH` configurable) |
| 4 | Float Low Sensor (INPUT_PULLUP) |
| 5 | Float Full Sensor (INPUT_PULLUP) |
| 15 | Float Mid Sensor (INPUT_PULLUP) |
| 2 | WiFi LED |
| 17 | Pump LED |
| 18 | Buzzer |
| 21/22 | OLED SDA/SCL (SSD1306 128×64) |
| 23 | Button MODE |
| 25 | Button PUMP |
| 26 | Button MUTE |
| 27/14 | Ultrasonic TRIG/ECHO (interrupt-driven) |
| 33 | Toggle Mode (LOW=Float, HIGH=Ultrasonic) |
| 34 | Emergency Wakeup (ext 10kΩ pull-up required) |
| 0 | Factory Reset (hold 10s) |

> ⚠️ পূর্ববর্তী README-তে GPIO 2 ও 16-এর function ভুলভাবে swap করা ছিল (Pump Relay ↔ WiFi LED) — এখানে firmware সোর্স থেকে যাচাই করে ঠিক করা হয়েছে।

## Requirements
- Flutter 3.24+
- Android 6.0+ (API 23), `targetSdk 36`
- ESP32 (BLE + WiFi)
- Arduino ESP32 Core ≥ 2.0.14
- Libraries: ArduinoJson ≥7.0, Adafruit SSD1306, Adafruit GFX

## আরও পড়ো
- প্রথমবার সেটআপ → `SETUP_GUIDE.md`
- পুরো ডেভেলপমেন্ট রেফারেন্স → `DEVELOPER_GUIDE.md`
- Security/credential rotation → `SECURITY.md`
- Release-এর আগে checklist → `PRODUCTION_CHECKLIST.md`
- Play Store submission → `PLAY_STORE_RELEASE_GUIDE.md`
- ভার্সন হিস্টরি → `CHANGELOG.md`

---
*Made with 💙 in Bangladesh 🇧🇩 | © 2025-2026 SMART IoT Interface*
=======
# smartiot-app
SmartIoT — Flutter app + ESP32 firmware (water level control)
>>>>>>> caf49db40bd5f68cc0e002f7e73d07768fe1a0a0
