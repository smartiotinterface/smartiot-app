// ══════════════════════════════════════════════════════════════════════════════
//  SMART WATER LEVEL CONTROL BD — Android Build Config v5.1.0
//
//  SIGNING SETUP:
//  1. প্রথমে CREATE_KEYSTORE.bat চালান (project root থেকে)
//  2. android\app\smartiot-release.jks তৈরি হবে
//  3. android\key.properties এ password দিন
//  4. তারপর: flutter build apk --release
//
//  Keystore না থাকলে automatically debug signing use করে।
//
//  GOOGLE SIGN-IN:
//  keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
//  SHA-1 → Firebase Console → Project Settings → Android App → Add fingerprint
// ══════════════════════════════════════════════════════════════════════════════

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Keystore detection ────────────────────────────────────────────────────────
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Check if the actual .jks file exists
val jksFile: java.io.File? = run {
    if (!keystorePropertiesFile.exists()) return@run null
    val path = keystoreProperties["storeFile"] as? String ?: return@run null
    // Try: android/app/<path> first, then absolute/relative
    listOf(
        rootProject.file("app/$path"),
        file(path),
        rootProject.file(path)
    ).firstOrNull { it.exists() }
}

val hasReleaseSigning = jksFile != null

android {
    namespace = "com.smartiot.smart_iot_interface"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.smartiot.smart_iot_interface"
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // Only create release signing config when the keystore file actually exists
    if (hasReleaseSigning) {
        signingConfigs {
            create("release") {
                keyAlias      = keystoreProperties["keyAlias"] as String
                keyPassword   = keystoreProperties["keyPassword"] as String
                storeFile     = jksFile!!
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        getByName("debug") {
            isDebuggable = true
        }
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Use release signing if keystore ready, otherwise debug signing
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.core:core-splashscreen:1.0.1")
}
