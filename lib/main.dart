// lib/main.dart
// v1.0.2 — AUTO COUNTRY CODE + DEVICE OWNERS FORMAT FIX
// ✅ BLE timeouts + null-safety + release keystore + SHA-1 embedded + bilingual EN/BN
// Bilingual (EN/BN) — 100% EN or 100% BN, no mixed language

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/offline_service.dart';
import 'services/local_history_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'core/constants.dart';
import 'providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // [LOCAL-FONTS] SpaceGrotesk font is bundled in assets/fonts/ — no google_fonts package needed.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } else {
    // Debug: print errors without Crashlytics
    FlutterError.onError = FlutterError.presentError;
  }

  await OfflineService.init();
  await LocalHistoryService.init();
  await NotificationService.init();

  // ── FCM token wiring ──────────────────────────────────────────────────────
  // Wire token refresh listener — updates Firebase when FCM token rotates
  final fbService = FirebaseService();
  NotificationService.onTokenRefresh((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) await fbService.saveFcmToken(user.uid, newToken);
  });

  final prefs = await SharedPreferences.getInstance();
  final darkMode = prefs.getBool(AppConstants.prefDarkMode) ?? true;

  runApp(SmartIoTApp(initialDarkMode: darkMode));
}

// ── ThemeNotifier ─────────────────────────────────────────────────────────────
class ThemeNotifier extends ChangeNotifier {
  bool _isDark;
  ThemeNotifier(this._isDark);

  bool get isDark => _isDark;

  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefDarkMode, _isDark);
  }
}

// ── App root ──────────────────────────────────────────────────────────────────
class SmartIoTApp extends StatelessWidget {
  final bool initialDarkMode;
  const SmartIoTApp({super.key, required this.initialDarkMode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier(initialDarkMode)),
        // LocaleProvider — persists user language choice via SharedPreferences
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const _MaterialAppWrapper(),
    );
  }
}

class _MaterialAppWrapper extends StatelessWidget {
  const _MaterialAppWrapper();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final locale = context.watch<LocaleProvider>().locale;
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      // ── Localisation ──────────────────────────────────────
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('bn'),
      ],
      home: const SplashScreen(),
    );
  }
}
