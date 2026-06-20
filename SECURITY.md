# 🔐 SECURITY.md — SmartIoT v1.0.2

এই ফাইলটা নতুন developer বা deployment-এর সময় অবশ্যই পড়তে হবে।

---

## ১. Firebase Database Secret — REVOKE করুন এখনই

এই ZIP distribution-এর আগের version-এ `FIREBASE_DB_SECRET` exposed হয়েছে।

**Firebase Console → Project Settings → Service Accounts → Database Secrets**
- পুরনো secret: **REVOKE** করুন
- নতুন secret generate করুন
- `esp32/SmartIoT_v15/secrets.h`-এ `FIREBASE_DB_SECRET`-এ paste করুন

---

## ২. AES-256 Key — নতুন generate করুন

```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

Output (64 hex chars) `secrets.h`-এর `AES_BACKUP_KEY_HEX`-এ রাখুন।
⚠️ প্রতিটি ESP32 device-এর জন্য **আলাদা unique key**।

---

## ৩. Android Release Keystore — নতুন তৈরি করুন

এই ZIP-এ `.jks` ফাইল নেই (নিরাপত্তার জন্য বাদ দেওয়া হয়েছে)।
নতুন keystore তৈরি করুন:

```bash
keytool -genkey -v \
  -keystore android/app/smartiot-release.jks \
  -alias smartiot \
  -keyalg RSA -keysize 2048 \
  -validity 10000
```

তারপর `android/key.properties`-এ password দিন।
⚠️ `.jks` এবং `key.properties` কখনো Git-এ push করবেন না।

---

## ৪. BLE Proof-of-Possession (PoP) — পরিবর্তন করুন

`esp32/SmartIoT_v15/secrets.h`-এ `PROV_POP` এবং
`lib/services/ble_provisioning_service.dart`-এর `kPoP` — দুটো **একই** রাখুন।
Default `Sm@rtW@t3r!BD24` production-এ ব্যবহার করবেন না।

---

## ৫. Google Services API Key — Restrict করুন

`android/app/google-services.json`-এর API key:
Firebase Console → Project Settings → API Keys → Restrict করুন
(Android apps only, package: `com.smartiot.smart_iot_interface`)

---

## ৬. secrets.h — কখনো Git-এ push করবেন না

`.gitignore`-এ আছে। Double-check করুন:
```bash
git status --short | grep secrets.h  # কিছু না দেখালে নিরাপদ
```

---

## ৭. Firmware Production Build

`esp32/SmartIoT_v15/SmartIoT_v15.ino`-এ নিশ্চিত করুন:
```cpp
#define PRODUCTION_MODE 1  // ← 1 হতে হবে, 0 না
```
`0` হলে সব debug info UART-এ expose হবে।
