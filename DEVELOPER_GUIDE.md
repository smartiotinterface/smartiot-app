# 📖 DEVELOPER GUIDE — Smart Water Level Control BD
### Smart IoT Interface | Developer: Sobuj Billah
### App: v1.0.2 | Firmware: v15.0.1 | smartiotinterface@gmail.com

---

## ১. Firebase প্রোজেক্ট সেটআপ (ধাপে ধাপে)

### ধাপ ১ — Firebase প্রোজেক্ট তৈরি
১. [firebase.google.com](https://firebase.google.com) এ যান এবং Google account দিয়ে লগইন করুন
২. **"Create a project"** বাটনে ক্লিক করুন
৩. প্রোজেক্টের নাম দিন (যেমন: `smart-iot-water`)
৪. Google Analytics চালু রাখুন (ঐচ্ছিক) → **Create project** ক্লিক করুন

### ধাপ ২ — Realtime Database চালু করা
১. বাম মেনু থেকে **Build → Realtime Database** এ যান
২. **"Create Database"** বাটনে ক্লিক করুন
৩. Location বেছে নিন (Asia-southeast1 বা নিকটতম)
৪. **"Start in test mode"** বেছে নিন → **Enable** ক্লিক করুন
৫. Database URL টি কপি করুন (পরে লাগবে)

### ধাপ ৩ — Database Rules আপলোড করা
১. Realtime Database → **Rules** ট্যাবে যান
২. `firebase/database.rules.json` ফাইলের সম্পূর্ণ কন্টেন্ট কপি করুন
৩. Rules editor-এ পেস্ট করুন → **Publish** ক্লিক করুন

### ধাপ ৪ — Authentication চালু করা
১. বাম মেনু থেকে **Build → Authentication** এ যান
২. **"Get started"** বাটনে ক্লিক করুন
৩. **Sign-in method** ট্যাব → **Email/Password** বেছে নিন
৪. প্রথম toggle **Enable** করুন → **Save** ক্লিক করুন

### ধাপ ৫ — Android অ্যাপ যোগ করা
১. Project Overview থেকে Android আইকনে ক্লিক করুন
২. Package name দিন: `com.smartiotinterface.water`
৩. App nickname: `Smart IoT Water`
৪. **Register app** ক্লিক করুন
৫. **google-services.json** ডাউনলোড করুন
৬. ফাইলটি `android/app/` ফোল্ডারে রাখুন

### ধাপ ৬ — firebase_options.dart কনফিগার করা
`lib/firebase_options.dart` ফাইলে নিচের placeholder-গুলো আপনার আসল মান দিয়ে বদলান:

```dart
apiKey: 'YOUR_API_KEY',           // google-services.json থেকে
projectId: 'YOUR_PROJECT_ID',     // Firebase Console → Project Settings
messagingSenderId: 'YOUR_SENDER_ID',
appId: 'YOUR_APP_ID',
databaseURL: 'YOUR_DATABASE_URL', // Realtime Database URL
storageBucket: 'YOUR_BUCKET',
```

### ধাপ ৭ — Cloud Functions চালু করা (Blaze Plan প্রয়োজন)
> ⚠️ Cloud Functions ব্যবহার করতে Firebase Blaze (Pay-as-you-go) plan দরকার।
> Free Spark plan-এ FCM notification কাজ করবে না।

```bash
# Firebase CLI ইন্সটল করুন (একবারই করতে হবে)
npm install -g firebase-tools

# Login করুন
firebase login

# প্রোজেক্ট ফোল্ডারে যান
cd SmartIoT_AUDITED

# Functions deploy করুন
npm install
```

### ধাপ ৮ — Firebase Storage চালু করা (OTA-র জন্য)
১. বাম মেনু থেকে **Build → Storage** এ যান
২. **"Get started"** বাটনে ক্লিক করুন
৩. Default rules রাখুন → **Done** ক্লিক করুন
৪. OTA firmware upload করুন: `ota/{deviceId}/firmware.bin`

---

## ২. ESP32 পিন কানেকশন

```
┌─────────────────────┬──────────┬────────────────────┐
│ কম্পোনেন্ট         │ ESP32 Pin│ নোট                │
├─────────────────────┼──────────┼────────────────────┤
│ HC-SR04 TRIG        │ GPIO 27  │ OUTPUT             │
│ HC-SR04 ECHO        │ GPIO 14  │ INPUT (interrupt)  │
│ Pump Relay          │ GPIO  2  │ Active-LOW         │
│ Buzzer              │ GPIO 18  │ PWM                │
│ LED WiFi            │ GPIO 16  │ OUTPUT             │
│ LED Pump            │ GPIO 17  │ OUTPUT             │
│ Button Mode         │ GPIO 23  │ INPUT_PULLUP       │
│ Button Pump         │ GPIO 25  │ INPUT_PULLUP       │
│ Button Mute         │ GPIO 26  │ INPUT_PULLUP       │
│ Button Reset        │ GPIO  0  │ INPUT_PULLUP       │
│ Float Sensor LOW    │ GPIO  4  │ INPUT_PULLUP       │
│ Float Sensor MID    │ GPIO 15  │ INPUT_PULLUP       │
│ Float Sensor FULL   │ GPIO  5  │ INPUT_PULLUP       │
│ Mode Toggle         │ GPIO 33  │ INPUT              │
│ Wakeup Pin          │ GPIO 34  │ INPUT_ONLY (RTC)   │
│ OLED SDA            │ GPIO 21  │ I2C                │
│ OLED SCL            │ GPIO 22  │ I2C                │
└─────────────────────┴──────────┴────────────────────┘
```

**পাওয়ার সাপ্লাই:** ESP32 → 5V USB বা 3.3V regulated  
**Relay:** Active-LOW (GPIO LOW = পাম্প চালু, GPIO HIGH = পাম্প বন্ধ)  
**HC-SR04:** VCC=5V, GND=GND, TRIG=GPIO27, ECHO=GPIO14  
**OLED SSD1306:** VCC=3.3V, GND=GND, SDA=GPIO21, SCL=GPIO22  

---

## ৩. Arduino IDE সেটআপ ও লাইব্রেরি

### Board Manager সেটআপ
১. Arduino IDE খুলুন → **File → Preferences**
২. "Additional boards manager URLs" এ যোগ করুন:
   ```
   https://espressif.github.io/arduino-esp32/package_esp32_index.json
   ```
3. **Tools → Board → Boards Manager** → "ESP32" সার্চ করুন
4. **"ESP32 by Espressif Systems"** ইন্সটল করুন (v3.x বা সর্বশেষ)

### Library Manager থেকে ইন্সটল করুন
| লাইব্রেরি | ভার্সন |
|------------|--------|
| Adafruit SSD1306 | v2.5.7 |
| Adafruit GFX Library | v1.11.9 |
| ArduinoJson | v7.x (v6 নয়!) |

> ⚠️ **গুরুত্বপূর্ণ:** ArduinoJson v7 ব্যবহার করুন। v6-এ `StaticJsonDocument` আছে, v7-এ শুধু `JsonDocument`।

### বিল্ট-ইন লাইব্রেরি (আলাদা ইন্সটল লাগবে না)
- ESP32 BLE Arduino
- HTTPClient
- HTTPUpdate
- Preferences (NVS)
- mbedtls (AES + HMAC-SHA256)
- WiFi, WiFiClientSecure

---

## ৪. ESP32 কোড আপলোড

### Board সেটিংস (Tools মেনু)
```
Board           : ESP32 Dev Module
Upload Speed    : 115200
Flash Frequency : 80MHz
Flash Mode      : QIO
Flash Size      : 4MB (32Mb)
Partition Scheme: No OTA (2MB APP/2MB SPIFFS)   ⚠️ "Default 4MB with spiffs" নয় — BLE stack বড়, app partition-এ জায়গা লাগবে
Core Debug Level: None
PSRAM           : Disabled
```

### secrets.h কনফিগার করা
`esp32/SmartIoT_v15/secrets.h` ফাইলটি খুলুন এবং আপনার মান দিন:

```cpp
#define FIREBASE_HOST       "YOUR_PROJECT-default-rtdb.firebaseio.com"
#define FIREBASE_DB_SECRET  "YOUR_DATABASE_SECRET"  // Database Secret থেকে
#define TEST_WIFI_ENABLED   0                        // Production-এ অবশ্যই 0
```
> Device ID dynamically generate হয় (ESP32 চিপ ID থেকে) — হার্ডকোড করার দরকার নেই।

### আপলোড করার ধাপ
1. ESP32 USB দিয়ে কম্পিউটারে সংযুক্ত করুন
2. Arduino IDE-তে সঠিক COM port বেছে নিন
3. `esp32/SmartIoT_v15/SmartIoT_v15.ino` খুলুন (⚠️ "SmartIoT_v15 upgrade" ফোল্ডারটি না — README.md দেখুন কেন)
4. **Verify** (✓) বাটনে ক্লিক করে compile করুন
5. কোনো error না থাকলে **Upload** (→) বাটনে ক্লিক করুন
6. Serial Monitor খুলুন (115200 baud) → boot message দেখুন

---

## ৫. Flutter প্রজেক্ট চালানো

### প্রথমবার সেটআপ
```bash
# Dependencies ডাউনলোড করুন
flutter pub get

# l10n (localization) generate করুন
flutter gen-l10n
```
> পুরনো guide-এ একটা `build_runner`/Hive-adapter codegen স্টেপ ছিল — প্রজেক্টে কোনো `@HiveType` মডেল নেই (data plain `Map`-ভিত্তিক), তাই সেটা বাস্তবে কখনো কিছু generate করতো না। v8.2.8 হাউসকিপিং-এ ওই dev dependency-ই সরিয়ে দেওয়া হয়েছে।

### Debug মোডে চালানো
```bash
# Android device/emulator সংযুক্ত থাকলে
flutter run --debug

# নির্দিষ্ট device-এ
flutter run -d <device_id> --debug
```

### Release APK তৈরি করা
```bash
# ABI অনুযায়ী আলাদা APK (ছোট সাইজ)
flutter build apk --release --split-per-abi

# সব ABI একসাথে (universal)
flutter build apk --release

# APK পাবেন এখানে:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## ৬. প্রথমবার ব্যবহার

### অ্যাপ ইন্সটল
1. Android ফোনে **Settings → Security → Unknown Sources** চালু করুন
2. `app-release.apk` ফোনে কপি করুন এবং ইন্সটল করুন

### নতুন অ্যাকাউন্ট তৈরি
1. অ্যাপ খুলুন → **Register** ট্যাবে যান
2. Email ও Password দিন (কমপক্ষে ৮ অক্ষর, ১ uppercase, ১ সংখ্যা)
3. **Register** বাটনে ক্লিক করুন

### BLE দিয়ে ESP32 সেটআপ
1. ESP32-এ ৫V পাওয়ার দিন
2. ফোনের Bluetooth চালু করুন
3. অ্যাপে **"Add Device"** → **"Start BLE Setup"** বাটনে ক্লিক করুন
4. Permission চাইলে Allow করুন
5. "SmartIoT_Setup" device দেখালে ট্যাপ করুন
6. আপনার WiFi network বেছে নিন, পাসওয়ার্ড দিন
7. সফল হলে Dashboard-এ চলে যাবে

---

## ৭. OTA Firmware আপডেট

### নতুন firmware আপলোড করার ধাপ

**ধাপ ১ — .bin ফাইল তৈরি করুন:**
```
Arduino IDE → Sketch → Export Compiled Binary
```
এটি একটি `.bin` ফাইল তৈরি করবে।

**ধাপ ২ — Firebase Storage-এ আপলোড করুন:**
```
Firebase Console → Storage → ota/{deviceId}/firmware.bin
```
অথবা Firebase CLI দিয়ে:
```bash
firebase storage:upload ota/ESP32_001/firmware.bin ./firmware.bin
```

**ধাপ ৩ — Download URL সংগ্রহ করুন:**
Firebase Storage-এ ফাইলটির উপর ক্লিক করুন → "Copy download URL"

**ধাপ ৪ — RTDB আপডেট করুন:**
Firebase Console → Realtime Database → নিচের path-এ data সেট করুন:
```json
/devices/ESP32_001/ota: {
  "available": true,
  "version": "2.4.0",
}
```

**ধাপ ৫ — ESP32 স্বয়ংক্রিয়ভাবে আপডেট করবে:**
পরবর্তী ৩০ মিনিটের মধ্যে ESP32 নতুন firmware ডাউনলোড ও ইন্সটল করবে।

---

## ৮. সাধারণ সমস্যা ও সমাধান

### BLE সমস্যা
| সমস্যা | সমাধান |
|--------|--------|
| Device পাচ্ছি না | Location permission দিন, Bluetooth চালু রাখুন |
| ESP32 scan করছি না | ESP32-এ পাওয়ার দিয়ে ৩০ সেকেন্ড অপেক্ষা করুন |
| BLE connect হচ্ছে না | ফোন ESP32-এর কাছাকাছি রাখুন (১ মিটারের মধ্যে) |

### WiFi সমস্যা
| সমস্যা | সমাধান |
|--------|--------|
| WiFi connect হচ্ছে না | পাসওয়ার্ড সঠিক কিনা দেখুন; 2.4GHz নেটওয়ার্ক ব্যবহার করুন (5GHz কাজ করবে না) |
| IP address পাচ্ছে না | Router-এ MAC filtering থাকলে বন্ধ করুন |

### Firebase/App সমস্যা
| সমস্যা | সমাধান |
|--------|--------|
| Dashboard-এ ডেটা আসছে না | Firebase Rules সঠিকভাবে আপলোড হয়েছে কিনা দেখুন |
| Login হচ্ছে না | Firebase Authentication → Email/Password চালু আছে কিনা দেখুন |
| google-services.json error | সঠিক package name (`com.smartiotinterface.water`) দিয়ে app register করুন |

### Flutter/Build সমস্যা
| সমস্যা | সমাধান |
|--------|--------|
| `device_model.g.dart` নেই | `flutter pub run build_runner build --delete-conflicting-outputs` চালান |
| JetBrains Mono font দেখাচ্ছে না | `flutter pub get` আবার চালান |
| build_runner error | পুরোনো generated files মুছুন, তারপর build করুন |
| Gradle build fail | `cd android && ./gradlew clean` চালান |
| minSdk error | `android/app/build.gradle.kts`-এ `minSdk = 23` আছে কিনা দেখুন |

### ESP32 সমস্যা
| সমস্যা | সমাধান |
|--------|--------|
| WiFi connect হচ্ছে না | `Serial Monitor` খুলুন, error message দেখুন |
| Firebase PUT fail হচ্ছে | `FIREBASE_HOST` ও `DEVICE_ID` সঠিক কিনা দেখুন |
| OTA update হচ্ছে না | Firebase Storage URL সঠিক কিনা দেখুন, HTTPS ব্যবহার করুন |
| OLED দেখাচ্ছে না | I2C address `0x3C` সঠিক কিনা দেখুন |

---

## ৯. প্রোজেক্ট ফোল্ডার কাঠামো

```
SmartIoT_AUDITED/
├── esp32/
│   └── SmartIoT_v15/
│       ├── SmartIoT_v15.ino    ← মূল ESP32 firmware (v15.0.1)
│       └── secrets.h           ← Firebase credentials (git-এ রাখবেন না!)
│
├── lib/
│   ├── main.dart               ← App entry point, Provider tree
│   ├── firebase_options.dart   ← Firebase config (YOUR_ placeholders)
│   ├── core/
│   │   ├── constants.dart      ← App constants, Firebase paths
│   │   ├── utils.dart          ← Helper functions
│   │   └── secure_storage.dart ← FlutterSecureStorage wrapper
│   ├── models/
│   │   └── device_model.dart   ← plain Map-based model (fromMap/toMap, no codegen)
│   ├── services/               ← Business logic (ChangeNotifier)
│   ├── screens/                ← UI screens
│   ├── widgets/                ← Reusable widgets (TankWidget, etc.)
│   ├── theme/
│   │   └── app_theme.dart      ← Colors, typography, theme data
│   └── l10n/
│       ├── app_en.arb          ← English strings
│       └── app_bn.arb          ← Bengali strings
│
├── firebase/
│   ├── database.rules.json     ← RTDB security rules
│   └── functions/
│       ├── index.js            ← FCM Cloud Functions
│       └── package.json
│
├── android/                    ← Android build config
├── ios/                        ← iOS build config
├── assets/
│   └── i18n/                   ← JSON translation files
└── pubspec.yaml                ← Flutter dependencies
```

---

## ১০. যোগাযোগ

কোনো সমস্যায় বা feedback-এর জন্য:

| মাধ্যম | তথ্য |
|--------|------|
| 📧 Email | smartiotinterface@gmail.com |
| 📞 Phone | +8801680603444 |
| 📺 YouTube | [youtube.com/@smartiotinterface](https://youtube.com/@smartiotinterface) |
| 👥 Facebook | [Smart IoT Interface](https://www.facebook.com/profile.php?id=100087725496322) |

---

*Smart IoT Interface © 2024 · Developer: Sobuj Billah · Made with 💙 in Bangladesh 🇧🇩*
