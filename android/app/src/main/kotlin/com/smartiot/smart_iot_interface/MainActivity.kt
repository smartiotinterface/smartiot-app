package com.smartiot.smart_iot_interface

import android.bluetooth.BluetoothManager
import android.content.Context
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // ── [FIX-E1-BOND] Android BLE bond management ─────────────────────────────
    // ROOT CAUSE: flutter_esp_ble_prov ব্যবহারে Android OS, ESP32-এর সাথে
    // একটি Bluetooth bond তৈরি করে। ESP32 reset বা re-provision করলে পুরানো
    // bond info মিলে না → "Failed to create session" (E1) error হয়।
    //
    // FIX: প্রতিটি connectAndScanWifi এর আগে Flutter থেকে এই channel call করা হয়।
    // সব "PROV_SmartIoT" prefix-এর bonded device-এর bond Android থেকে মুছে দেয়।
    // ─────────────────────────────────────────────────────────────────────────
    private val BLE_BOND_CHANNEL = "com.smartiot/ble_bond"

    // ── [FIX-COUNTRY-CODE] Auto SIM country detection channel ─────────────────
    // Flutter-এ TelephonyManager access নেই। এই channel দিয়ে:
    //   getSimCountryIso() → SIM card-এর ISO country code (e.g. "bd", "in", "us")
    //   getNetworkCountryIso() → network operator country (fallback)
    // ─────────────────────────────────────────────────────────────────────────
    private val COUNTRY_CHANNEL = "com.smartiot/country"

    // ISO country code → E.164 dialing prefix map
    private val countryDialCodeMap = mapOf(
        "bd" to "+880",  // Bangladesh
        "in" to "+91",   // India
        "us" to "+1",    // USA
        "gb" to "+44",   // UK
        "ae" to "+971",  // UAE
        "pk" to "+92",   // Pakistan
        "sa" to "+966",  // Saudi Arabia
        "my" to "+60",   // Malaysia
        "sg" to "+65",   // Singapore
        "qa" to "+974",  // Qatar
        "kw" to "+965",  // Kuwait
        "bh" to "+973",  // Bahrain
        "om" to "+968",  // Oman
        "jo" to "+962",  // Jordan
        "eg" to "+20",   // Egypt
        "ng" to "+234",  // Nigeria
        "gh" to "+233",  // Ghana
        "ke" to "+254",  // Kenya
        "za" to "+27",   // South Africa
        "de" to "+49",   // Germany
        "fr" to "+33",   // France
        "it" to "+39",   // Italy
        "es" to "+34",   // Spain
        "nl" to "+31",   // Netherlands
        "au" to "+61",   // Australia
        "ca" to "+1",    // Canada
        "jp" to "+81",   // Japan
        "kr" to "+82",   // South Korea
        "cn" to "+86",   // China
        "id" to "+62",   // Indonesia
        "ph" to "+63",   // Philippines
        "th" to "+66",   // Thailand
        "vn" to "+84",   // Vietnam
        "np" to "+977",  // Nepal
        "lk" to "+94",   // Sri Lanka
        "mm" to "+95",   // Myanmar
        "tr" to "+90",   // Turkey
        "ru" to "+7",    // Russia
        "ua" to "+380",  // Ukraine
        "br" to "+55",   // Brazil
        "mx" to "+52",   // Mexico
        "ar" to "+54",   // Argentina
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── BLE Bond Channel ───────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BLE_BOND_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // "clearSmartIoTBonds" — PROV_SmartIoT* prefix সব bond মুছো
                    // Returns: Int — কতটি bond মোছা হয়েছে (0 = কিছু নেই / already clean)
                    "clearSmartIoTBonds" -> {
                        val prefix = call.argument<String>("prefix") ?: "PROV_SmartIoT"
                        var cleared = 0
                        try {
                            val btManager = getSystemService(Context.BLUETOOTH_SERVICE)
                                    as? BluetoothManager
                            val adapter = btManager?.adapter
                            val bonded = adapter?.bondedDevices ?: emptySet()

                            for (device in bonded) {
                                if (device.name?.startsWith(prefix) == true) {
                                    try {
                                        // removeBond() একটি hidden Android API।
                                        // সব Android version-এ reflection দিয়ে কাজ করে।
                                        val m = device.javaClass.getMethod("removeBond")
                                        m.invoke(device)
                                        cleared++
                                    } catch (_: Exception) {
                                        // best-effort — একটি bond remove না হলে বাকিগুলো try করো
                                    }
                                }
                            }
                            result.success(cleared)
                        } catch (_: Exception) {
                            // Bluetooth off বা adapter unavailable → 0 দিয়ে success
                            // Bond clear না হলেও app crash করবে না
                            result.success(0)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        // ── Country Detection Channel ──────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COUNTRY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // "getPhoneDialCode" — Returns E.164 prefix for device SIM country.
                    // Priority: SIM country → Network country → Device locale → "+880" default
                    // Returns: String, e.g. "+880" for Bangladesh
                    "getPhoneDialCode" -> {
                        try {
                            val tm = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
                            // 1. Try SIM country ISO (most reliable — physical SIM)
                            val simIso = tm?.simCountryIso?.lowercase()?.trim()
                            if (!simIso.isNullOrEmpty() && simIso != "null") {
                                val dialCode = countryDialCodeMap[simIso]
                                if (dialCode != null) {
                                    result.success(dialCode)
                                    return@setMethodCallHandler
                                }
                            }
                            // 2. Try network country ISO (works on devices without SIM)
                            val netIso = tm?.networkCountryIso?.lowercase()?.trim()
                            if (!netIso.isNullOrEmpty() && netIso != "null") {
                                val dialCode = countryDialCodeMap[netIso]
                                if (dialCode != null) {
                                    result.success(dialCode)
                                    return@setMethodCallHandler
                                }
                            }
                            // 3. Try device locale country
                            val localeIso = java.util.Locale.getDefault().country?.lowercase()?.trim()
                            if (!localeIso.isNullOrEmpty()) {
                                val dialCode = countryDialCodeMap[localeIso]
                                if (dialCode != null) {
                                    result.success(dialCode)
                                    return@setMethodCallHandler
                                }
                            }
                            // 4. Default: Bangladesh (primary market)
                            result.success("+880")
                        } catch (_: Exception) {
                            result.success("+880")
                        }
                    }

                    // "getSimIsoCountry" — Returns raw ISO code, e.g. "bd"
                    "getSimIsoCountry" -> {
                        try {
                            val tm = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
                            val simIso = tm?.simCountryIso?.lowercase()?.trim()
                            if (!simIso.isNullOrEmpty() && simIso != "null") {
                                result.success(simIso)
                            } else {
                                val netIso = tm?.networkCountryIso?.lowercase()?.trim()
                                result.success(if (!netIso.isNullOrEmpty()) netIso else "bd")
                            }
                        } catch (_: Exception) {
                            result.success("bd")
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
