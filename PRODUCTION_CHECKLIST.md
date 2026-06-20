# ✅ SmartIoT Production Fix Checklist
## বাগ টেস্ট + সিমুলেশন রিপোর্ট — v3.5 → v3.6-FIXED

---

## 🔴 CRITICAL BUGS — সমাধান করা হয়েছে

### [C-1] Firebase Credentials Exposed in Git ✅ FIXED
- **সমস্যা:** `lib/firebase_options.dart`-এ real API keys (AIzaSy...) hardcoded ছিল
- **ঝুঁকি:** যে কেউ আপনার Firebase project access করতে পারতো
- **সমাধান:** Placeholder দিয়ে replace করা হয়েছে। `.gitignore`-এ যোগ করা হয়েছে
- **আপনার কাজ:** `flutterfire configure --project=YOUR_PROJECT_ID` চালান

### [C-2] `firebase_options.dart` .gitignore-এ ছিল না ✅ FIXED
- **সমস্যা:** `.gitignore`-এ `lib/firebase_options.dart` এন্ট্রি মিসিং ছিল
- **সমাধান:** `.gitignore`-এ যোগ করা হয়েছে

### [C-3] `secrets.h` .gitignore-এ ছিল ✅ VERIFIED
- **স্ট্যাটাস:** `esp32/SmartIoT_v15/secrets.h` সঠিকভাবে git-ignored

### [C-4] Localization delegates missing from MaterialApp ✅ FIXED
- **সমস্যা:** `intl` package use হচ্ছিল কিন্তু `GlobalMaterialLocalizations.delegate` etc. ছিল না
- **সমাধান:** `main.dart`-এ `localizationsDelegates` এবং `supportedLocales` যোগ করা হয়েছে

---

## 🟠 HIGH BUGS — সমাধান করা হয়েছে

### [H-1] BLE Permission — Android 6-11 vs 12+ ✅ FIXED
- **সমস্যা:** `AndroidManifest.xml`-এ Android 12+ এর `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT` ছিল কিন্তু Android 6-11 এর `ACCESS_FINE_LOCATION` সঠিকভাবে ছিল না
- **সমাধান:** উভয় API level এর জন্য সম্পূর্ণ permission set যোগ করা হয়েছে

### [H-2] Firebase Rules — Insufficient Validation ✅ FIXED
- **সমস্যা:** Original rules-এ field-level `.validate` ছিল না
- **সমাধান:** সব fields-এ type validation + range check যোগ করা হয়েছে
- **নতুন:** `$other: {".validate": false}` — unknown fields block করা হয়েছে

### [H-3] DeviceService not in Provider tree — ProviderNotFoundException ✅ VERIFIED OK
- **স্ট্যাটাস:** `DeviceService` সঠিকভাবে `DashboardScreen.initState()`-এ create করা হয় এবং `ChangeNotifierProvider.value`-এ wrap করা হয়
- **মন্তব্য:** uid দরকার বলে root-এ রাখা যায় না — design সঠিক

### [H-4] `google-services.json` package name ✅ VERIFIED
- **স্ট্যাটাস:** Placeholder-এ `com.smartiot.smart_iot_interface` সেট করা আছে
- **আপনার কাজ:** Firebase Console থেকে real `google-services.json` download করুন

### [H-5] Network Security Config ✅ FIXED
- **সমস্যা:** Original config-এ Firebase domains explicitly listed ছিল না
- **সমাধান:** `firebaseio.com`, `googleapis.com` domains explicitly trust করা হয়েছে

---

## 🟡 MEDIUM ISSUES — সমাধান করা হয়েছে

### [M-1] Cleartext Traffic ✅ FIXED
- `android:usesCleartextTraffic="false"` যোগ করা হয়েছে AndroidManifest.xml-এ

### [M-2] pubspec.yaml dependency versions ✅ VERIFIED
- সব versions compatible এবং latest stable

### [M-3] `allow_backup="false"` ✅ FIXED
- Security best practice — backup disabled করা হয়েছে

---

## ✅ ESP32 Firmware — সিমুলেশন চেক

### Firmware v14.0.0 বাগ ফিক্স (v12→v14):

| সমস্যা | Status |
|--------|--------|
| AES-256-CBC separate input/output buffers | ✅ Fixed in v14.0.0 |
| OTA URL whitelist | ✅ Fixed in v14.0.0 |
| BLE CONNECT parser i-1 underflow | ✅ Fixed in v14.0.0 |
| AES decrypt PKCS7 padding guard | ✅ Fixed in v14.0.0 |
| Deep sleep button activity check | ✅ Fixed in v14.0.0 |
| OLED non-blocking screen cycle | ✅ Fixed in v14.0.0 |
| BLECmdCallback static instance | ✅ Fixed in v14.0.0 |
| No delay() in main loop | ✅ Confirmed |
| WiFi password NOT logged to Serial | ✅ Confirmed |
| secrets.h git-ignored | ✅ Confirmed |

---

## 📋 সেটআপ চেকলিস্ট (আপনার করণীয়)

- [ ] `flutterfire configure --project=YOUR_PROJECT_ID` → `lib/firebase_options.dart` generate করুন
- [ ] Firebase Console → Android App → `google-services.json` download → `android/app/` তে রাখুন
- [ ] `esp32/SmartIoT_v15/secrets.h` এ আপনার `FIREBASE_HOST` এবং `FIREBASE_DB_SECRET` দিন
- [ ] Firebase Console → Realtime Database → Rules → `firebase/database.rules.json` deploy করুন
- [ ] Firebase Console → Authentication → Email/Password enable করুন
- [ ] Firebase Cloud Messaging → Server key সেট করুন (FCM notifications এর জন্য)

---

## 🧪 Simulate করা হয়েছে যেসব scenario:

1. **নেটওয়ার্ক বিচ্ছিন্ন:** OfflineService Hive cache থেকে data দেখাবে ✅
2. **Firebase error:** DeviceService retry logic 1→30 seconds exponential backoff ✅
3. **Command timeout:** togglePump/toggleMode 10 second timeout — UI freeze হবে না ✅
4. **BLE provisioning:** 20-byte MTU chunking, response buffer accumulation ✅
5. **AES encryption:** ESP32 chip ID থেকে key derivation — hardware bound ✅
6. **Deep sleep:** alarm condition থাকলে sleep skip করবে ✅
7. **OTA:** URL whitelist — শুধু Firebase Storage URLs accept করবে ✅
8. **Dry-run protection:** পাম্প চলছে কিন্তু water level উঠছে না → 3 min পর pump বন্ধ ✅

---

*Report generated: SmartIoT v3.6-FIXED*

---

## ✅ ESP32 Firmware v15.0.0 — OLED + Production Hardening (29-05-2026)

| Fix | Status |
|-----|--------|
| OLED pipe y-coord off-screen flicker | ✅ Fixed v15 |
| Main screen row overlaps (size=2 + size=1 rows) | ✅ Fixed v15 |
| Tank % label below tank overlapping status rows | ✅ Fixed v15 |
| Alarm bar / time row overlap | ✅ Fixed v15 |
| Notification overlay overlapping top content | ✅ Fixed v15 |
| Status screen WiFi line >128px overflow | ✅ Fixed v15 |
| Info screen Heap+Temp >128px overflow | ✅ Fixed v15 |
| Provisioning BLE name truncation | ✅ Fixed v15 |
| animFrame tied to display rate — jerky animation | ✅ Fixed v15 (100ms tick) |
| getShortSSID off-by-one buffer overrun | ✅ Fixed v15 |
| Alarm text y=57+8=65 > 64px display | ✅ Fixed v15 |
| Factory Reset cancel text overflow + clipping | ✅ Fixed v15 |
| OTA title overflow + pct text clipping | ✅ Fixed v15 |
| Splash bottom rows clipped (y=58+8=66>64) | ✅ Fixed v15 |
| pinMajority reading wrong sensor buffer | ✅ Fixed v15 (critical sensor bug) |
| evaluateAutomations early-return skips eval | ✅ Fixed v15 |
| GPIO comment wrong (said GPIO2, is GPIO16) | ✅ Fixed v15 |
| Test suite: 71/71 (100%) PASS | ✅ Verified |

**Folder:** `esp32/SmartIoT_v15/SmartIoT_v15.ino`

---

## 📱 App-এ প্রথমবার Device যোগ করার নিয়ম

1. ESP32-এ firmware upload করুন
2. App open করুন → Login করুন
3. Dashboard → "+" বা "Add Device"
4. **Option A (BLE):** "Setup via Bluetooth" → ESP32 scan করুন → WiFi দিন
5. **Option B (Manual):** Serial number টাইপ করুন (OLED-এ দেখাচ্ছে)
6. Device যোগ হলে dashboard-এ live data দেখাবে

---

## ⚡ Offline Mode কীভাবে কাজ করে

- App internet ছাড়া খুললে **শেষ known status** দেখাবে (Hive cache)
- Dashboard-এ "Cached data" ব্যানার দেখাবে
- Internet ফিরলে automatically live data-তে switch হবে
- Commands (pump on/off) offline-এ কাজ করবে না

---

## 🆘 সমস্যা হলে

| সমস্যা | সমাধান |
|--------|--------|
| "Permission denied" error | Firebase Database Rules deploy করুন |
| FCM notification আসছে না | Blaze plan activate করুন + Functions deploy করুন (বা local notification-এই থাকুন — Spark plan যথেষ্ট) |
| BLE device খুঁজে পাচ্ছে না | Location permission দিন (Android 12-এর নিচে); `esp32/SmartIoT_v15/` (upgrade ফোল্ডার না) ফ্ল্যাশ করা আছে কিনা যাচাই করুন |
| iOS build fail | GoogleService-Info.plist ঠিক আছে কিনা দেখুন |
| ESP32 Firebase connect হচ্ছে না | secrets.h-এর FIREBASE_HOST ও DB_SECRET চেক করুন |
