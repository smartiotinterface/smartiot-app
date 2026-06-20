// lib/core/secure_storage.dart
// AES-256 secure storage via Android Keystore / iOS Keychain.
// Used for: clearing all session data on logout.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // AES-256 via Android Keystore
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Clear all secure data on logout (prevents session/token leaks)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
