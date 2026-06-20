# ============================================================
# SmartIoT Interface — ProGuard / R8 Rules
# [FIX C-3] Proper keep rules for all dependencies
# ============================================================

# Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.**

# Flutter embedding
-keep class io.flutter.embedding.** { *; }

# Firebase core + auth + database + crashlytics
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Crashlytics — keep stack traces readable
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Hive — Dart-only package; no Java class to keep
# (com.hivedb rules removed — Hive is pure Dart, not Java/Kotlin)

# Espressif BLE Provisioning
-keep class com.espressif.** { *; }
-dontwarn com.espressif.**

# esp_wifi_provisioning — AGP 8+ compatible BLE provisioning
-keep class com.espressif.** { *; }
-dontwarn com.espressif.**
-keep class com.souravsinghrawat.esp_wifi_provisioning.** { *; }
-dontwarn com.souravsinghrawat.esp_wifi_provisioning.**

# flutter_local_notifications — [FIX BUG-12] restored with package
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# permission_handler removed — esp_wifi_provisioning handles permissions internally
# (connectivity_plus removed — Spark plan cleanup)

# package_info_plus
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Kotlin stdlib
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# App model classes (prevent stripping data classes)
-keep class com.smartiot.smart_iot_interface.** { *; }

# Play Core (deferred components — suppress warning)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# OkHttp (used by Firebase)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# Gson (used internally by some Firebase libs)
-keepattributes Signature
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

# fl_chart — Dart-only package; no Java class to keep
# (com.github.mikephil.charting rules removed — fl_chart is pure Dart)

# google_fonts — keep font loader
-keep class com.google.android.gms.fonts.** { *; }

# cached_network_image / image cache
-keep class com.squareup.picasso.** { *; }
-dontwarn com.squareup.picasso.**

# shimmer — REMOVED: package not in pubspec.yaml (com.facebook.shimmer removed)

# connectivity_plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# firebase_storage
-keep class com.google.firebase.storage.** { *; }

# ── flutter_esp_ble_prov plugin wrapper ─────────────────────────────────────
# [FIX-PROGUARD] flutter_esp_ble_prov এর Java plugin class ProGuard এ
# obfuscate হলে WiFi scan এর সময় session drop হয় → E1 error।
-keep class com.kevindowling.flutter_esp_ble_prov.** { *; }
-dontwarn com.kevindowling.flutter_esp_ble_prov.**

# Espressif provisioning protobuf classes (reflection দিয়ে load হয়)
-keep class com.espressif.provisioning.** { *; }
-keepclassmembers class com.espressif.** {
    public *;
    protected *;
}

# Protobuf (used internally by Espressif provisioning)
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**
-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite {
    <fields>;
}
