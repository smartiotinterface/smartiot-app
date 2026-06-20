# 🔧 SmartIoT সেটআপ গাইড — App v1.0.2 / Firmware v15.0.1

## 💰 সম্পূর্ণ ফ্রি কিনা?

### ✅ সম্পূর্ণ ফ্রি কম্পোনেন্ট:
| কম্পোনেন্ট | কেন ফ্রি |
|------------|---------|
| Firebase Realtime Database | Spark (free) plan: 1GB storage, 10GB/month transfer |
| Firebase Authentication | Spark plan: 10,000 auth/month |
| Flutter + Android Studio | সম্পূর্ণ ফ্রি, open source |
| ESP32 Arduino firmware | সম্পূর্ণ ফ্রি, সব libraries free |
| Local push notifications | flutter_local_notifications — ফ্রি |
| Google Fonts | ফ্রি |
| BLE provisioning | ফ্রি |

### ⚠️ শুধু একটি কম্পোনেন্ট পেইড হতে পারে:
| কম্পোনেন্ট | কী লাগে | বিকল্প |
|------------|---------|--------|
| Firebase Cloud Functions | Blaze plan (পে-অ্যাজ-ইউ-গো) | **ইতিমধ্যে ফ্রি বিকল্প যোগ করা হয়েছে** ↓ |

### 🆓 Cloud Functions ছাড়াই notifications কাজ করে!
এই release এ `device_service.dart`-এ **client-side notification** যোগ করা হয়েছে।
অ্যাপ খোলা/background থাকলে সব alert পাবেন:
- ⚠️ Dry run alert
- 🚨 Alarm active
- 💧 পাম্প চালু/বন্ধ
- 🪣 পানি কম (< 10%)
- 🎉 ট্যাংক পূর্ণ (> 90%)

**Cloud Functions শুধু দরকার হয় যদি:** অ্যাপ পুরোপুরি বন্ধ থাকলেও notification পেতে চান।
সেক্ষেত্রে Firebase Blaze plan activate করুন (প্রথম 2M invocations/month ফ্রি)।

---

## ⚡ দ্রুত শুরু (5 ধাপে)

---

## ধাপ ১: Firebase Project তৈরি

1. [console.firebase.google.com](https://console.firebase.google.com) → **Add project**
2. **Realtime Database** চালু করুন → us-central1 region → Start in test mode
3. **Authentication** → Email/Password → Enable

---

## ধাপ ২: Flutter অ্যাপ সেটআপ

```bash
# Firebase CLI install (একবার)
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Project folder এ
cd SmartIoT_FINAL/
flutter pub get

# Firebase configure করুন (lib/firebase_options.dart তৈরি হবে)
flutterfire configure --project=YOUR_PROJECT_ID

# Run করুন
flutter run
```

### Android-এর জন্য google-services.json:
1. Firebase Console → Project Settings → Your Apps → Android
2. Package name: `com.smartiot.smart_iot_interface` দিন
3. `google-services.json` download করুন → `android/app/` ফোল্ডারে রাখুন

---

## ধাপ ৩: Firebase Database Rules Deploy

```bash
firebase deploy --only database
```

অথবা Firebase Console → Realtime Database → Rules → `firebase/database.rules.json` এর content paste করুন → Publish

---

## ধাপ ৪: ESP32 Firmware সেটআপ (CRITICAL FIX)

```bash
cd esp32/SmartIoT_v15/
```

`secrets.h` edit করুন — **দুটো জায়গা** fill করুন:

```cpp
#define FIREBASE_HOST       "YOUR_PROJECT_ID-default-rtdb.firebaseio.com"
#define FIREBASE_DB_SECRET  "YOUR_FIREBASE_DATABASE_SECRET"
```

### Firebase Database Secret কোথায় পাবেন:
```
Firebase Console
  → Project Settings (gear icon)
  → Service Accounts tab
  → Database Secrets section
  → "Add secret" অথবা existing secret "Show" করুন
  → সেই string copy করুন
```

> ℹ️ **নোট:** Firebase RTDB-এর REST API self-signed JWT/OAuth2 token সরাসরি accept করে না (legacy secret-ভিত্তিক auth লাগে) — তাই firmware **Database Secret** (`?auth=` query param দিয়ে, TLS root-CA pinning সহ পাঠানো হয়) ব্যবহার করে। এটিই Firebase-এর REST API-তে legacy secret ব্যবহারের একমাত্র সমর্থিত পদ্ধতি।
> ⚠️ Google "Database Secrets"-কে deprecated মার্ক করেছে (এখনো কাজ করে, কিন্তু ভবিষ্যতে সরিয়ে দেওয়া হতে পারে) — দীর্ঘমেয়াদে Firebase Auth custom token-ভিত্তিক device identity-তে migrate করার কথা ভাবা উচিত।

### Arduino IDE Libraries (Tools → Manage Libraries):
- `ArduinoJson` by Benoit Blanchon (v7.x)
- `Adafruit SSD1306`
- `Adafruit GFX Library`

### Board Settings:
- Board: **ESP32 Dev Module**
- Upload Speed: **921600**
- Flash Size: **4MB (32Mb)**
- Partition Scheme: **No OTA (2MB APP/2MB SPIFFS)** ⚠️ "Default 4MB with spiffs" নয় — BLE stack বড়, app partition-এ জায়গা লাগবে

---

## ধাপ ৫: (Optional) Cloud Functions — Blaze Plan

অ্যাপ বন্ধ থাকলেও notification পেতে চাইলে:

```bash
# Firebase Blaze plan activate করুন (console.firebase.google.com)
# প্রথম 2 million invocations/month বিনামূল্যে

npm install
```

---

## 🔐 Security Checklist

| চেক | Status |
|-----|--------|
| `lib/firebase_options.dart` — placeholder (আপনার data নেই) | ✅ |
| `android/app/google-services.json` — placeholder | ✅ |
| `esp32/SmartIoT_v15/secrets.h` — .gitignore এ | ✅ |
| WiFi password ESP32-এ AES-256 encrypted | ✅ |
| Firebase Rules production-ready | ✅ |
| OTA URL whitelist active | ✅ |

---

## 🛠️ ট্রাবলশুটিং

| সমস্যা | সমাধান |
|--------|--------|
| ESP32 Firebase write হচ্ছে না (403 error) | `secrets.h` এ FIREBASE_DB_SECRET সঠিক দিন |
| `flutter pub get` ব্যর্থ | Dart SDK ≥3.4.0: `dart --version` |
| BLE scan কাজ করছে না | Location + Bluetooth permissions দিন |
| Notification আসছে না (app খোলা) | FirebaseAuth login করুন, permission দিন |
| Firebase connection নেই | `firebase_options.dart` configure করা? |

---

## ✅ দ্রুত যাচাই (ফোন ছাড়াই ESP32 টেস্ট)

উপরের সব ধাপ শেষ করার পর, ফোন/BLE ছাড়াই শুধু Serial Monitor দিয়ে ESP32 ঠিকমতো কাজ করছে কিনা যাচাই করতে নিতে পারো:

1. `esp32/SmartIoT_v15/secrets.h`-এ `FIREBASE_DB_SECRET` দাও, `TEST_WIFI_ENABLED 1` রাখো (test WiFi credential দিয়ে hardcode করে BLE বাইপাস করে)
2. Arduino IDE → Upload → Serial Monitor (115200 baud) খুলো
3. দেখা উচিত: `[TEST] ✅ WiFi OK — IP: 192.168.x.x`
4. Firebase Console → Realtime Database → `/devices/` এ data আসছে কিনা দেখো

Flutter app টেস্ট করতে:
```bash
flutter pub get
flutter run -d chrome    # browser-এ, বা
flutter run              # connected phone/emulator-এ
```

⚠️ এই quick-test শেষে `TEST_WIFI_ENABLED` আবার `0` করে re-flash করো — production-এ `1` রাখলে BLE provisioning সম্পূর্ণ বাইপাস হয়ে যাবে।

---

*SmartIoT Interface — Made with 💙 in Bangladesh 🇧🇩*
