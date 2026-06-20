# 🔑 Release Keystore তৈরির নির্দেশনা

## ধাপ ১ — Keystore বানানো
Windows CMD বা PowerShell-এ নিচের command চালান:

```
keytool -genkey -v -keystore android\smartiot-release-key.jks -alias smartiot -keyalg RSA -keysize 2048 -validity 10000
```

প্রশ্নের উত্তর দিন (বাংলায় বা ইংরেজিতে):
- First and Last Name: Sobuj Billah
- Organizational unit: SmartIoT
- Organization: SmartIoT Interface
- City: Dhaka
- State: Dhaka
- Country code: BD

## ধাপ ২ — key.properties ফাইল তৈরি
`android/key.properties.template` ফাইলটির নাম পরিবর্তন করুন:

```
copy android\key.properties.template android\key.properties
```

তারপর `android/key.properties` খুলে fill করুন:
```
storePassword=আপনার_keystore_password
keyPassword=আপনার_key_password
keyAlias=smartiot
storeFile=smartiot-release-key.jks
```

## ধাপ ৩ — APK Build
```
flutter build apk --release --split-per-abi
```

APK পাওয়া যাবে:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` ← এটা ব্যবহার করুন

## ⚠️ গুরুত্বপূর্ণ
- `key.properties` এবং `smartiot-release-key.jks` কখনো GitHub-এ push করবেন না
- এই দুটি ফাইল হারিয়ে গেলে Play Store-এ আর update দিতে পারবেন না
- নিরাপদ জায়গায় backup রাখুন
