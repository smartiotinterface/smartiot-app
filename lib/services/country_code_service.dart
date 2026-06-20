// lib/services/country_code_service.dart
// ══════════════════════════════════════════════════════════════════════════════
//  SmartIoT v1.0.2 — Auto Country Code Detection
//  [FIX-COUNTRY-1] Detects SIM/network/locale country automatically
//  [FIX-COUNTRY-2] Prefills phone E.164 prefix in login screen
//
//  Priority: SIM Country → Network Country → Device Locale → Default (+880)
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CountryCodeService {
  CountryCodeService._();

  static const _channel = MethodChannel('com.smartiot/country');

  /// Returns the E.164 dialing prefix for the device's SIM/network country.
  ///
  /// Priority:
  ///   1. SIM card country ISO (most reliable)
  ///   2. Network operator country ISO
  ///   3. Device locale country
  ///   4. Default: +880 (Bangladesh — primary market)
  ///
  /// Examples: "+880" (BD), "+91" (IN), "+1" (US), "+44" (UK)
  static Future<String> getDialCode() async {
    if (kIsWeb) return '+880';
    try {
      final result = await _channel.invokeMethod<String>('getPhoneDialCode');
      return result ?? '+880';
    } on MissingPluginException {
      // Web or unsupported platform
      return '+880';
    } catch (e) {
      if (kDebugMode) debugPrint('[CountryCode] getDialCode failed: $e');
      return '+880';
    }
  }

  /// Returns the ISO country code for the device (e.g. "bd", "in", "us").
  static Future<String> getIsoCode() async {
    if (kIsWeb) return 'bd';
    try {
      final result = await _channel.invokeMethod<String>('getSimIsoCountry');
      return result ?? 'bd';
    } catch (_) {
      return 'bd';
    }
  }

  /// Normalises a phone number to E.164 format.
  ///
  /// Rules:
  ///   - Already has '+' → returned as-is (user knows what they typed)
  ///   - Starts with '00' → replace '00' with '+'
  ///   - Pure digits (10-11 chars for BD) → prepend [dialCode]
  ///   - Otherwise → prepend [dialCode] and let Firebase validate
  ///
  /// [dialCode] defaults to '+880' (Bangladesh).
  static String normalizeE164(String raw, {String dialCode = '+880'}) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\s'), '');
    if (trimmed.isEmpty) return trimmed;

    // Already E.164
    if (trimmed.startsWith('+')) return trimmed;

    // 00-prefix international format
    if (trimmed.startsWith('00')) return '+${trimmed.substring(2)}';

    // Bangladesh: 01XXXXXXXXX (11 digits) → +88001XXXXXXXXX
    // But users often type 01XXXXXXXXX and expect +88001XXXXXXXXX
    // Firebase needs: +8801XXXXXXXXX (13 chars total)
    // Correct: strip leading 0 before prepending +880
    if (dialCode == '+880') {
      final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 11 && digits.startsWith('0')) {
        // 01XXXXXXXXX → +88001XXXXXXXXX? No: +880 + 1XXXXXXXXX = +8801XXXXXXXXX ✅
        return '+880${digits.substring(1)}'; // removes leading 0 → +8801XXXXXXXXX
      }
      if (digits.length == 10 && !digits.startsWith('0')) {
        // 1XXXXXXXXX → +8801XXXXXXXXX ✅
        return '$dialCode$digits';
      }
    }

    // Generic: prepend dial code as-is
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return '$dialCode$digits';
  }
}
