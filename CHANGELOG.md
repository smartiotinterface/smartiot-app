## [1.0.2] — 2026-06-19

### 🔴 CRITICAL FIXES
- **[FIX-RULES-1]** `firebase_service.dart` — `claimDevice()` now writes `device_owners/$deviceId` as **flat string** (uid), matching the RTDB rules exactly. The previous nested-map format (`device_owners/$deviceId/$uid = true`) caused ALL device operations to fail with PERMISSION_DENIED because every rule checks `.val() === auth.uid` (string comparison). `getDeviceOwner()` and `checkDeviceClaimed()` also updated to read flat string.
- **[FIX-OTP-1]** `auth_service.dart` — `sendPhoneOTP()` now normalises the phone number to E.164 format before calling Firebase. Previously, numbers entered without `+880` (e.g. `01711XXXXXX`) caused silent SMS delivery failure.

### 🟡 AUTH / UX IMPROVEMENTS
- **[FIX-COUNTRY-1]** `MainActivity.kt` — New `com.smartiot/country` MethodChannel detects SIM country ISO via `TelephonyManager`. Priority: SIM country → network country → device locale → `+880` default.
- **[FIX-COUNTRY-2]** `CountryCodeService` (new) — Flutter service wrapping the MethodChannel. Provides `getDialCode()` (returns `+880` etc.) and `normalizeE164()` (converts `01711XXXXXX` → `+8801711XXXXXX`).
- **[FIX-COUNTRY-3]** `login_screen.dart` — On entering phone auth mode, `_detectCountryCode()` is called. The phone field is auto-prefilled with the detected dial code. The `dialCode` is passed to `sendPhoneOTP()`.
- **[FIX-MANIFEST-1]** `AndroidManifest.xml` — Added `READ_PHONE_STATE` (required for `TelephonyManager` country detection) and SMS Retriever broadcast receiver (enables OTP auto-read on Android 8+ without `RECEIVE_SMS`).
- **[FIX-BLE-1]** `ble_provisioning_service.dart` — Removed misleading `// TODO: Change before release` comment from `kPoP`. The value `Sm@rtW@t3r!BD24` IS the production PoP, matching `secrets.h`.

### 🔵 SECURITY / DOCUMENTATION
- **[SEC-NOTE]** `SmartIoT_v15.ino` — Documented static AES-CBC IV (`0x37 × 16`) in NVS backup. Risk: low (local device storage); changing IV requires STATE_VERSION bump + NVS clear.
- **[L10N]** Added `country_code_auto_label` and `phone_e164_hint` keys to EN + BN ARB files and Dart classes.
- **Version bump:** 1.0.0+1 → 1.0.2+3

# 📋 CHANGELOG — SmartIoT Smart Water Level Control BD

---

## v1.0.0 — FIRST PUBLIC RELEASE (2026-06-17)

### 🧹 Merged in from user's independent "v8.2.8_CLEAN" cleanup pass
ব্যবহারকারী নিজে আমার v8.2.8 ডেলিভারি থেকে কিছু ফাইল manually delete করে একটা "CLEAN" ভার্সন বানিয়েছিলেন — compare করে দেখা গেছে প্রতিটা deletion-ই সঠিক ছিল (আমার নিজের audit-এ মিস হয়ে গিয়েছিল):
- `lib/core/firebase_error_handler.dart` — সম্পূর্ণ অব্যবহৃত ছিল (zero import, কোথাও call হয় না)
- `assets/i18n/en.json` ও `bn.json` — legacy JSON-ভিত্তিক localization-এর অবশিষ্ট, বর্তমান ARB-ভিত্তিক সিস্টেম এগুলো পড়েই না; সাথে `pubspec.yaml`-এর dangling `assets/i18n/` entry-ও সরানো হয়েছে
- `firebase/database.rules.SIMPLE_START.json` — একটা পুরোনো "সব authenticated user-এর জন্য সব read/write" টেমপ্লেট, কোথাও reference হয় না, ভুলে deploy হলে real rules-এর উপর security regression হতো
- `esp32/SmartIoT_v15 upgrade/` ফোল্ডার — আগেই সুপারিশ করা হয়েছিল মুছে ফেলার, ব্যবহারকারী করেছেন ✅

এই তিনটা dead-file ফিক্স এখন এই (v1.0.0) ভার্সনেও যুক্ত করা হলো। CLEAN-এ অনুপস্থিত ছিল: theme consolidation, নতুন test ফাইল দুটো, `.gitignore`, এবং `assets/images/icon_set/`-এর Play Store marketing asset (icon/feature graphic) দুটো — এগুলো CLEAN বানানোর *আগে* বা *সময়* missing হয়ে গেছে বলে মনে হচ্ছে, ইচ্ছাকৃত cleanup না (এই দুটো ফাইল ছাড়া Play Store submission করা যাবে না, ফেরত আনতে হবে)।
- প্রথমে অনুমান করা হয়েছিল ১৪টা স্ক্রিনে theme ছড়িয়ে আছে — exhaustive code scan করে দেখা গেছে আসলে তা নয়। মাত্র `ble_provisioning_screen.dart`-এর নিজস্ব `_Brand` palette (ইচ্ছাকৃত "Premium Corporate" নীল থিম, ফাইল হেডারে স্পষ্ট লেখা) আলাদা — এটা bug না, deliberate design, তাই **ছোঁয়া হয়নি**।
- আসল সমস্যা ছিল ভিন্ন: ৭টা ফাইলে (`dashboard_screen.dart`, `login_screen.dart`, `splash_screen.dart`, `settings_screen.dart`, `device_setup_screen.dart`, `google_sign_in_button.dart`, `tank_widget.dart`) ৬০টা raw hex color literal (যেমন `Color(0xFF7C61D4)`) ছিল যেগুলো `AppTheme`-এর already-named কালারের সাথে exact মিলে যায় — সব `AppTheme.xxx` reference-এ পরিবর্তন করা হয়েছে। **Pixel-level output অপরিবর্তিত** (hex value হুবহু একই, শুধু কোডে দুইবার লেখার বদলে একবার), কিন্তু এখন ভবিষ্যতে কোনো brand color বদলাতে চাইলে এক জায়গায় বদলালেই সব জায়গায় প্রতিফলিত হবে। ৩টা ফাইলে `app_theme.dart` import যোগ করতে হয়েছে।

### 🧪 Testing
- `test/automation_scene_models_test.dart` (নতুন) — `AutomationModel`/`SceneModel`-এর জন্য কখনো test ছিল না (v8.0-এ যোগ হয়েছিল, কিন্তু `DeviceStatus`/`DeviceMeta`-র মতো test coverage পায়নি) — fromMap/toMap/defaults/triggerLabel/accentColor সব কভার করা হয়েছে।
- `test/l10n_consistency_test.dart` (নতুন) — ঠিক যে বাগটা ধরা পড়েছিল (ARB-এ key না থাকা সত্ত্বেও generated ফাইলে reference করা) তার জন্য একটা specific regression guard — `automation_deleted`/`scene_deleted` সহ ১১টা ভিন্ন feature area-র key সরাসরি instantiate করে টেস্ট করে (Flutter widget pumping লাগে না, milliseconds-এ চলে)। এখন থেকে এই ক্যাটাগরির বাগ আবার হলে শুধু analyze না, `flutter test`-ও সাথে সাথে ধরিয়ে দেবে।
- প্রজেক্ট-জুড়ে সব ৪৪টা Dart ফাইল (lib+test+integration_test) আবার bracket-balance verify করা হয়েছে, l10n 374/374/374/374 সিঙ্ক রিকনফার্ম।

এখান থেকে Play Store-এর জন্য Semantic Versioning শুরু (Major.Minor.Patch — যেমন 1.0.1 = patch, 1.1.0 = নতুন ফিচার, 2.0.0 = breaking/বড় পরিবর্তন)। নিচের v8.2.8 ও তার আগের সব entry **internal development history** হিসেবে সংরক্ষিত আছে (অফিসিয়াল Play Store-এ কখনো প্রকাশ হয়নি)।

- **[VERSION]** `pubspec.yaml`: `8.2.8+8` → `1.0.0+1` — Android `versionCode`/`versionName` ও iOS `CFBundleVersion`/`CFBundleShortVersionString` এই একটা লাইন থেকেই dynamically derive হয় (`flutter.versionCode`/`flutter.versionName` reference, কোথাও hardcoded নয়), in-app "About" স্ক্রিনের ভার্সনও `PackageInfo` দিয়ে dynamic — তাই এই একটা change-এই পুরো app-জুড়ে সব জায়গায় সঠিক ভার্সন দেখাবে। **তবে** এক্সহস্টিভ প্রজেক্ট-ওয়াইড সুইপে আরও কয়েক জায়গায় hardcoded version string পাওয়া গেছে যেগুলো `pubspec.yaml`-এর সাথে সিঙ্কড না (একই ক্যাটাগরির সমস্যা যেটা গত পাসে `automation_deleted`-এ ধরা পড়েছিল) — সব নিচে আলাদা করে ফিক্স করা হয়েছে:
  - `lib/core/constants.dart`: একটা সম্পূর্ণ unused `appVersion = '8.2.7'` constant (dead code, repo-জুড়ে zero usage — সরিয়ে দেওয়া হয়েছে) এবং একটা **real bug**: `firmwareVersion = 'v15.0.0'` ছিল (actual current firmware v15.0.1) — এটা `about_screen.dart`-এ লাইভ ব্যবহার হয়, তাই ফিক্স করা জরুরি ছিল।
  - `lib/screens/privacy_policy_screen.dart` (২ জায়গা) ও `lib/screens/user_guide_screen.dart` — in-app স্ক্রিনে hardcoded "Version: 8.2.4" দেখাচ্ছিল, ব্যবহারকারী সরাসরি দেখতে পারতো। `1.0.0`-এ ঠিক করা হয়েছে। ⚠️ এগুলো এখনও hardcoded string (about_screen.dart-এর মতো PackageInfo দিয়ে dynamic না) — পরের ভার্সন bump-এও এই একই কাজ আবার ম্যানুয়ালি করতে হবে, যদি না future-এ dynamic-এ রিফ্যাক্টর করা হয়।
  - `privacy_policy.html` (hosted, Play Store-এ link হবে) — একই "Version: 8.2.4" সমস্যা, ফিক্স করা হয়েছে। "Last Updated" তারিখ পরিবর্তন করা হয়নি, কারণ policy-র মূল কনটেন্ট রিভিউ/পরিবর্তন করা হয়নি — শুধু তারিখ বদলালে legal document-এ misleading হতো।
  - `lib/main.dart`, `lib/core/constants.dart`, `lib/services/ble_provisioning_service.dart`, `lib/screens/{about,user_guide,privacy_policy,ble_provisioning}_screen.dart`, `integration_test/app_test.dart`, `build_release.sh`, `analysis_options.yaml`, `test/widget_test.dart`, `SECURITY.md` — file-header comment-এ পুরনো version stamp ছিল, সব সিঙ্ক করা হয়েছে (cosmetic, compile-impact নেই)।
  - **ইচ্ছাকৃতভাবে ছোঁয়া হয়নি:** `ios/Flutter/Generated.xcconfig` ও `flutter_export_environment.sh` — এগুলো Flutter build tool কর্তৃক **auto-generated** (ARB-এর মতোই — ম্যানুয়াল এডিট করলে next build-এ overwrite হয়ে যাবে), পরের `flutter build`/`flutter run`-এ এগুলো নিজে থেকেই pubspec.yaml থেকে সঠিক 1.0.0 দিয়ে রিজেনারেট হবে। `esp32/*/SmartIoT_v15.ino`-এর `[FIX-SERIAL v8.2.7]` কমেন্ট দুটোও ছোঁয়া হয়নি — এগুলো historical bug-fix marker (কখন ফিক্সটা হয়েছিল তার রেকর্ড), current-version claim না।
- **[NOTE]** ESP32 firmware versioning (`v15.0.1`) ইচ্ছাকৃতভাবে আলাদা রাখা হয়েছে — app ও firmware-এর independent version scheme থাকা স্বাভাবিক প্র্যাকটিস (অনেক IoT প্রোডাক্টেই app version আলাদা, device firmware version আলাদা)।
- **[ASSUMPTION]** `versionCode 1` বেছে নেওয়া হয়েছে এই ধরে নিয়ে যে Play Console-এ (internal/closed testing track-সহ) আগে কখনো কোনো build আপলোড হয়নি। যদি ভুল হয়, আগের সর্বোচ্চ versionCode জানিয়ে দিলে সেটার থেকে +1 করে দেওয়া হবে।

---

## 🗄️ Internal Development History (pre-1.0, কখনো প্রকাশ হয়নি)

## v8.2.8 — PRODUCTION AUDIT (2026-06-16)

### 🔧 Correction (একই দিনে, user-এর `flutter run` থেকে ধরা পড়েছে)
আগের v8.2.8 পাসে `automation_deleted`/`scene_deleted` key সরাসরি generated ফাইলে (`lib/l10n/app_localizations*.dart`) যোগ করা হয়েছিল, কিন্তু **ARB source file-এ (`app_en.arb`/`app_bn.arb`) যোগ করা হয়নি** — `flutter gen-l10n` রান করলে ওই generated ফাইল ARB থেকে নতুন করে তৈরি হয়, ফলে key দুটো হারিয়ে যায় ("undefined_getter" compile error)। এখন ঠিক জায়গায় (ARB) ফিক্স করা হয়েছে এবং 374 ARB key ↔ abstract class ↔ EN impl ↔ BN impl ↔ lib/-এর সব ১৪৭টা actual usage — সব মিলিয়ে cross-verify করা হয়েছে (০ mismatch)। সাথে একটা প্রকৃত bug-ও ধরা পড়েছিল: `automations_screen.dart`-এ async Firebase delete-এর পর `mounted` চেক ছাড়াই `context` ব্যবহার হচ্ছিল (`use_build_context_synchronously`) — এটাও ফিক্স করা হয়েছে।

### 🔴 High-Priority Findings (flagged, NOT auto-fixed — needs your decision)
- **[FIRMWARE]** `esp32/SmartIoT_v15/` ও `esp32/SmartIoT_v15 upgrade/` দুটো ফোল্ডারেই `FIRMWARE_VER "v15.0.1"` — কিন্তু `upgrade` ফোল্ডারে WiFi reason-201 (NO_AP_FOUND) ফিক্স ও 2.4GHz-only protocol-force ফিক্স **নেই**। `esp32/SmartIoT_v15/` (upgrade ছাড়া) ব্যবহার করুন।
- **[SECURITY]** Firebase "Database Secrets" Google কর্তৃক deprecated মার্ক করা (এখনও কাজ করে, কিন্তু ভবিষ্যতে সরিয়ে দেওয়া হতে পারে) — দীর্ঘমেয়াদে migration বিবেচনা করুন।
- **[I18N]** `automations_screen.dart` ও `scenes_screen.dart` ~৯০% হার্ডকোডেড ইংরেজি (প্রায় ৬০টা string) — বাকি app-এর ৩৪৭-key bilingual coverage-এর সাথে সামঞ্জস্যপূর্ণ নয়। বড় কাজ, পরবর্তী dedicated pass-এ করার সুপারিশ।
- **[DATA]** `/devices/{id}/history` cloud path-এ কোনো server-side trim নেই (local Hive cache 5000→4500 ট্রিম হয়, কিন্তু cloud copy unbounded growth — critical-event-only filtering দিয়ে rate কম রাখা আছে)।

### 🐛 Bug Fixes
- **[FIX]** `android/app/src/main/res/mipmap-*/ic_launcher_foreground.png` — adaptive icon foreground layer ভুল আকারে (legacy 48-192px-এ, যেখানে লাগে 108-432px) এবং **কোনো transparency ছাড়াই** (ic_launcher.png-এর সাথে byte-identical) ছিল — Samsung/Pixel/অন্য OEM mask shape-এ icon clip হওয়ার ঝুঁকি ছিল। সঠিক canvas size + ৬৬% safe-zone scale + প্রকৃত transparency দিয়ে regenerate করা হয়েছে।
- **[FIX]** `firebase/database.rules.json` — `devices/{id}/history`-এ `.indexOn: "ts"` যোগ করা হয়েছে (app `orderByChild('ts').limitToLast()` ব্যবহার করে, index ছাড়া পুরো node স্কেন হতো)
- **[FIX]** README.md-এ GPIO টেবিলে GPIO 2 ও 16-এর function ভুলভাবে swap করা ছিল (Pump Relay ↔ WiFi LED) — firmware source থেকে verify করে ঠিক করা হয়েছে
- **[FIX]** DEVELOPER_GUIDE.md ও SETUP_GUIDE.md-এ ভুল Partition Scheme লেখা ছিল ("Default 4MB with spiffs") — firmware-এর নিজস্ব কমেন্ট অনুযায়ী সঠিক "No OTA (2MB APP/2MB SPIFFS)"-এ ঠিক করা হয়েছে (ভুলটা থাকলে compile/upload fail করতে পারত)

### ♻️ Code Quality
- **[DUPLICATE-LOGIC]** `automations_screen.dart` ও `scenes_screen.dart`-এর identical private `_snack()` method সরিয়ে shared `AppUtils.showSnack()`-এ delegate করা হয়েছে
- **[I18N]** ৩টা হার্ডকোডেড ইংরেজি string (`Could not open link`, `Automation deleted`, `Scene deleted`) localize করা হয়েছে — নতুন `automation_deleted`/`scene_deleted` key যোগ (en+bn, ৩৪৭/৩৪৭/৩৪৭ key sync verified)
- **[CLEANUP]** `build_runner` dev dependency সরানো হয়েছে — প্রজেক্টে কোনো `@HiveType`/codegen annotation নেই, এটা কখনো কিছু generate করত না
- **[CLEANUP]** ১০টি ডকুমেন্ট থেকে ৮টায় consolidate: `FIRST_RUN.md` → `SETUP_GUIDE.md`-এ মার্জ, `PRODUCTION_DEPLOY_GUIDE.md` → `PRODUCTION_CHECKLIST.md`-এ মার্জ, `PLAY_STORE_LISTING.md` → `PLAY_STORE_RELEASE_GUIDE.md` (rename + submission steps যোগ)
- **[DOCS]** README.md, DEVELOPER_GUIDE.md, SETUP_GUIDE.md, PRODUCTION_DEPLOY_GUIDE(→CHECKLIST)-এ থাকা v2.3.0/v3.7/v14.0.0-era স্টেল ভার্সন স্ট্যাম্প ও path reference (`SmartIoT_v14`) সব v8.2.7/v15.0.1-এ আপডেট
- **[DOCS]** SETUP_GUIDE.md-এ একটা self-contradictory FIREBASE_DB_SECRET ব্যাখ্যা ছিল — পরিষ্কার করে লেখা হয়েছে

### ✅ Verified (no issue found)
- Dead screen check: সব screen-এর class অন্তত একবার navigate/reference হচ্ছে — কোনো orphan file নেই
- OTA: SHA-256 mandatory, Firebase Storage URL whitelist, TLS root-CA pinned, watchdog fed during download — সব ঠিক আছে
- Watchdog coverage: WiFi/Prov callback, OTA loop, deep-sleep path — সব জায়গায় feed হচ্ছে
- Firebase rules: প্রতিটা collection-এ `$other: {validate:false}` catch-all + root-level catch-all — anonymous access blocked, ownership/sharing logic সঠিক

---

## v8.2.7 — PRODUCTION SECURE (2026-06-07)

### 🔐 Security Fixes
- **[SEC-1]** `smartiot-release.jks` ZIP distribution থেকে বাদ দেওয়া হয়েছে
- **[SEC-2]** `secrets.h` এ real credentials sanitize করা হয়েছে (placeholder দেওয়া হয়েছে)
- **[SEC-3]** `key.properties` থেকে real passwords সরানো হয়েছে
- **[SEC-4]** ESP32 firmware: `PRODUCTION_MODE 0 → 1` — Serial output বন্ধ
- **[SEC-5]** ESP32 firmware: `setInsecure()` → `setCACert(GOOGLE_ROOT_CA)` — TLS certificate pinning
- **[SEC-6]** Personal phone number firmware comment থেকে সরানো হয়েছে
- **[SEC-7]** `SECURITY.md` তৈরি করা হয়েছে — credential management guide

### 🐛 Bug Fixes
- **[BUG-FIX]** GPIO summary comment ঠিক করা হয়েছে: `LED_WIFI = GPIO16` → `LED_WIFI = GPIO2`

### ♻️ Code Quality
- **[REFACTOR]** `google_fonts` package সম্পূর্ণ সরানো হয়েছে → bundled local SpaceGrotesk font ব্যবহার হচ্ছে
  - `app_theme.dart`: সব `GoogleFonts.spaceGrotesk()` → `TextStyle(fontFamily: 'SpaceGrotesk', ...)`
  - `main.dart`: `GoogleFonts.config.allowRuntimeFetching = false` সরানো হয়েছে
  - `pubspec.yaml`: `google_fonts: ^6.2.1` dependency সরানো হয়েছে
- **[CLEANUP]** `debug/` duplicate folder সরানো হয়েছে
- **[CLEANUP]** `esp32/SmartIoT_v14/` পুরনো firmware সরানো হয়েছে
- **[CLEANUP]** ১৫টি redundant documentation file consolidate করা হয়েছে

---

## v8.2.7 (2026-06-03)
- BLE provisioning session fix: `WiFiProv.endProvision()` before each `beginProvision()`
- OLED display: 12টি display bug fix (row overlap, clipping, animation)
- Firmware: `pinMajority` bug fix — correct sensor buffer references
- Firmware: `evaluateAutomations` early-return bug fix

## v8.2.5 (2026-05-31)
- BLE auto-retry: cooldown 15s→30s→60s, max 3 retries
- Flutter: `PlatformException(E1)` WiFi scan retry logic
- Firebase database rules deployed via CLI

## v8.2.3 (2026-05-31)
- 100% Production Complete build
- Release keystore generated
- Firebase SHA-1 registered
- Bilingual EN/BN (361 keys) 100% complete

## v8.0.0 (2026-05-28)
- BLE GATT → Espressif WiFiProv.h migration
- Firebase Custom Token auth design (ESP32 Custom Token flow)
- Flutter analyze: 69 issues resolved
- iOS CFBundleURLTypes REVERSED_CLIENT_ID fix (Google Sign-In critical fix)
- Firebase Crashlytics integration
- Dashboard 3D tank + profile card + offline banner

## v7.0.0 (2026-05-20)
- Cinematic splash screen: mesh grid + particle burst + shimmer title
- Premium login: animated ocean background
- ARB-based bilingual localization code generation
- OfflineService wired into DeviceService with stale-data banner

## v5.0.0 (2026-05-10)
- Production readiness audit: 69 issues identified and fixed
- Missing iOS `GoogleService-Info.plist` added
- `TimeoutException` class conflict with `dart:async` resolved
- `ProviderNotFoundException` for DeviceService resolved
