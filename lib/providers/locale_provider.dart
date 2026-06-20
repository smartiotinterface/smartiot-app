// lib/providers/locale_provider.dart
// LocaleProvider — persists language choice via SharedPreferences
// ✅ FIXED: Default language set to Bengali (bn)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _prefKey = 'app_locale';

  Locale _locale = const Locale('bn');  // ✅ ডিফল্ট বাংলা
  Locale get locale => _locale;

  LocaleProvider() {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && saved.isNotEmpty) {
      _locale = Locale(saved);
      notifyListeners();
    } else {
      // কোনো সেভ করা ভাষা না থাকলে বাংলা সেট করুন
      _locale = const Locale('bn');
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }

  void toggleLanguage() {
    if (_locale.languageCode == 'bn') {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('bn'));
    }
  }

  String get currentLanguageCode => _locale.languageCode;
  bool get isBengali => _locale.languageCode == 'bn';
  bool get isEnglish => _locale.languageCode == 'en';
}