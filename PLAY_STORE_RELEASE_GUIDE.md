# Play Store Release Guide — SMART Water Level Control BD (SmartIoT)

---

## App Details

| Field | Value |
|-------|-------|
| **Package Name** | com.smartiot.smart_iot_interface |
| **App Name** | SMART Water Level Control BD |
| **Short Name** | SmartIoT Water |
| **Version** | 1.0.0 |
| **Category** | Tools / Home Automation |
| **Content Rating** | Everyone |
| **Price** | Free |

---

## Short Description (80 chars max)
```
Smart water tank monitoring & control with ESP32, BLE & Firebase. Free!
```

---

## Full Description (4000 chars max)

```
🌊 SMART WATER LEVEL CONTROL BD — Bangladesh's smartest water tank monitor!

Monitor and control your water tank from anywhere using your smartphone. Powered by ESP32 microcontroller, Bluetooth Low Energy (BLE) provisioning, and Firebase Realtime Database — 100% FREE on Firebase Spark plan.

━━━━━━━━━━━━━━━━━━━━━━━━━
🔑 KEY FEATURES
━━━━━━━━━━━━━━━━━━━━━━━━━

📊 REAL-TIME MONITORING
• Live water level (%) with animated 3D tank display
• Pump status (ON/OFF) and mode (AUTO/MANUAL)
• Dry-run detection — protects your pump automatically
• Wi-Fi signal strength & device uptime
• Bangladesh local time (GMT+6) display

🤖 SMART AUTOMATION
• Schedule-based pump control (time-of-day schedules)
• Condition-based automations (IF water below X% → pump ON)
• One-tap Scenes (preset pump configurations)
• Manual override anytime

📱 EASY SETUP — BLE PROVISIONING
• No complex networking needed
• Connect your ESP32 to Wi-Fi directly from the app via Bluetooth
• Guided step-by-step setup wizard

🔔 SMART ALERTS
• Low water level push notifications
• Pump status change alerts
• Dry-run alarm notifications
• Works even when app is in the background (FCM)

📈 HISTORY & ANALYTICS
• Complete event log (pump on/off, alerts, boots)
• Water usage estimation (liters per day/week/month)
• Visual charts (bar chart, donut chart)
• Local-first storage — works offline

👨‍👩‍👧 MULTI-USER & SHARING
• Share device access with family members by email
• Owner can revoke access anytime
• Each user sees their own device list

🔒 SECURITY
• Firebase Authentication (Email + Google Sign-In)
• Email verification required
• Firebase Security Rules — strict data isolation
• OTA firmware update with SHA-256 verification

💻 DUAL LANGUAGE
• Full support for English and Bangla (বাংলা)
• Switch language anytime from Settings

━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 HARDWARE REQUIRED
━━━━━━━━━━━━━━━━━━━━━━━━━

• ESP32 microcontroller (30-pin or 38-pin)
• Water tank float sensors (LOW/MID/FULL) OR HC-SR04 ultrasonic sensor
• 5V relay module (for pump control)
• OLED display 0.96" I2C (optional, recommended)

━━━━━━━━━━━━━━━━━━━━━━━━━
🆓 100% FREE
━━━━━━━━━━━━━━━━━━━━━━━━━

Uses Firebase Spark plan (free tier):
• No monthly subscription
• No hidden costs
• No ads

━━━━━━━━━━━━━━━━━━━━━━━━━
📞 SUPPORT
━━━━━━━━━━━━━━━━━━━━━━━━━

• YouTube: @smartiotinterface
• Blog: smartiotinterface.blogspot.com
• Email: smartiotinterface@gmail.com

Made with 💙 in Bangladesh 🇧🇩
```

---

## Bangla Description (বাংলা বিবরণ)

```
🌊 স্মার্ট ওয়াটার লেভেল কন্ট্রোল BD — বাংলাদেশের সবচেয়ে স্মার্ট পানির ট্যাংক মনিটর!

আপনার স্মার্টফোন থেকে যেকোনো জায়গা থেকে পানির ট্যাংক মনিটর ও নিয়ন্ত্রণ করুন। ESP32, BLE প্রভিশনিং ও Firebase ব্যবহার করে — ১০০% বিনামূল্যে!

📊 রিয়েল-টাইম মনিটরিং — পানির লেভেল, পাম্পের অবস্থা, ড্রাই-রান সুরক্ষা
🤖 স্মার্ট অটোমেশন — শিডিউল, কন্ডিশন-ভিত্তিক রুল, ওয়ান-ট্যাপ সিন
📱 সহজ সেটআপ — BLE দিয়ে সরাসরি ফোন থেকে WiFi সেটআপ
🔔 স্মার্ট অ্যালার্ট — পুশ নোটিফিকেশন (FCM)
📈 ইতিহাস ও বিশ্লেষণ — চার্ট, পানি ব্যবহার হিসাব
👨‍👩‍👧 পরিবার শেয়ারিং — একাধিক ব্যবহারকারী একই ডিভাইস ব্যবহার করতে পারবেন
🔒 নিরাপদ — Firebase Auth, Security Rules, OTA SHA-256

বাংলাদেশে তৈরি 💙🇧🇩
```

---

## Keywords / Tags
```
water level monitor, water tank, ESP32, IoT, pump control, smart home, automation, Bangladesh, পানির ট্যাংক, water pump, BLE provisioning, Firebase, free IoT
```

---

## Content Rating Questionnaire Answers

| Question | Answer |
|----------|--------|
| Violence | None |
| Sexual content | None |
| Language | None (Family-safe) |
| Controlled substance references | None |
| User-generated content | No (device data only) |
| Social features | Yes (device sharing by email) |
| Location sharing | No |
| Personal/sensitive information | Yes — email address for login |

**Suggested Rating: Everyone (E)**

---

## Data Safety Form

### Data collected:
| Data Type | Collected | Shared | Required |
|-----------|-----------|--------|----------|
| Name | Yes | No | Optional |
| Email address | Yes | No | Required (for login) |
| User IDs | Yes | No | Required |
| App interactions | Yes (Crashlytics) | No | Optional |
| Crash logs | Yes | With Google (Firebase) | Optional |

### Security practices:
- ✅ Data is encrypted in transit (HTTPS/TLS)
- ✅ Data can be deleted (contact email)
- ✅ Data is not sold to third parties
- ✅ Data is not used for tracking

---

## Required Screenshots (Minimum 2, Recommended 8)

Take screenshots of:
1. Login screen (Google Sign-In button visible)
2. Dashboard — water tank at 75% (green), PUMP: ON, MODE: AUTO
3. History screen — event list with charts
4. Schedules screen — list of time-based schedules
5. Automations screen — condition-based rules
6. BLE Provisioning screen — device list
7. Settings screen — language toggle (EN/BN)
8. Dark mode dashboard

**Screenshot specs:** 1080×1920px (portrait), PNG or JPEG, max 8MB each.

**Feature Graphic:** 1024×500px — use the SmartIoT banner with tank illustration and "SMART Water Level Control BD" text.

---

## Store Listing URLs Needed Before Submission

- [ ] Privacy Policy URL: `https://YOUR_GITHUB_USERNAME.github.io/smartiot-privacy/` (publish PRIVACY_POLICY.md as GitHub Pages)
- [ ] Support email: `smartiotinterface@gmail.com`
- [ ] Website: `https://smartiotinterface.blogspot.com`

---

## Submission ও Rollout Steps

### ১. Release Build
```powershell
flutter build appbundle --release
# আউটপুট: build/app/outputs/bundle/release/app-release.aab
```
Build log-এ নিশ্চিত করুন **release** signing config (আপনার নিজের `.jks`) ব্যবহার হচ্ছে, debug fallback না।

### ২. Firebase-এ Release SHA যোগ করুন
```powershell
keytool -list -v -keystore android\smartiot-release.jks
```
SHA-1 ও SHA-256 কপি করে Firebase Console → Project Settings → Android app-এ যোগ করুন (Google Sign-In কাজ করার জন্য আবশ্যক)।

### ৩. Play Console — Track অনুসারে Rollout
| Track | উদ্দেশ্য | সময়কাল |
|---|---|---|
| Internal testing | নিজে + ২-৩ জন trusted user | যতদিন প্রয়োজন |
| Closed testing | বড় গ্রুপ (১২+ tester, ১৪ দিন lifetime প্রয়োজন কিছু দেশে) | ন্যূনতম ৭ দিন recommended |
| Production (staged) | ২০% → ৫০% → ১০০% rollout | সমস্যা দেখা গেলে কমিয়ে আনা যায় |

### ৪. Submission-এর আগে শেষ চেক
- [ ] Content Rating questionnaire সম্পন্ন
- [ ] Data Safety form সম্পন্ন (উপরের টেবিল অনুযায়ী)
- [ ] Permission justification: BLE scan-এর জন্য `ACCESS_FINE_LOCATION` লাগে — Play Console-এ লিখুন এটা location track-এর জন্য না, BLE device discovery-এর জন্য আবশ্যক (Android-এর নিজস্ব সীমাবদ্ধতা)
- [ ] Privacy Policy URL লাইভ এবং accessible (publish করার পর ব্রাউজারে খুলে টেস্ট করুন)

