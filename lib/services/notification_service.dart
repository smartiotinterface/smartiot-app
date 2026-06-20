// lib/services/notification_service.dart
// ══════════════════════════════════════════════════════════════════════════════
//  SmartIoT v8.0.0 — Notification Service
//  [v8.0.0] FCM token generation + Firebase save added
//  [v8.0.1] firebase_messaging fully integrated — real FCM token
//
//  ✅ Real flutter_local_notifications + firebase_messaging implementation.
//  Behaviour:
//     • Android 8+  → NotificationChannel "SmartIoT Alerts"
//     • Android 13+ → Requests POST_NOTIFICATIONS permission on init
//     • iOS         → Requests alert+badge+sound permissions on init
//     • Web/Desktop → Safe no-op guard (kIsWeb)
//
//  FCM Flow:
//     1. init() → request permission → get FCM token
//     2. token saved to Firebase via FirebaseService.saveFcmToken()
//     3. onTokenRefresh listener updates token automatically
//     4. Background/terminated message handler registered
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) debugPrint('[Notif] Background FCM: ${message.notification?.title}');
}

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId   = 'smartiot_alerts';
  static const _channelName = 'SmartIoT Alerts';
  static const _channelDesc = 'Pump status, dry-run and water level alerts';

  /// Call once at app startup — inits local notifications + FCM.
  static Future<void> init() async {
    if (kIsWeb) return;

    // ── Local notifications setup ──────────────────────────────────────────
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (kDebugMode) debugPrint('[Notif] tapped: ${details.payload}');
      },
    );

    // Create Android notification channel (required for Android 8+)
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;

    // ── Firebase Cloud Messaging setup ────────────────────────────────────
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (Android 13+ / iOS)
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (kDebugMode) {
      debugPrint('[Notif] FCM permission: ${settings.authorizationStatus}');
    }

    // Foreground message handler — show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        showLocalAlert(
          title: notification.title ?? 'SmartIoT',
          body: notification.body ?? '',
        );
      }
    });

    if (kDebugMode) debugPrint('[Notif] NotificationService fully initialized.');
  }

  /// Returns the real FCM registration token.
  /// Save this to Firebase via FirebaseService.saveFcmToken(uid, token).
  static Future<String?> getFcmToken() async {
    if (kIsWeb) return null;
    try {
      // iOS-এ APNS token আগে নিতে হয়, নইলে getToken() null দেয়
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (kDebugMode) debugPrint('[Notif] APNS token: $apns');
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) debugPrint('[Notif] FCM token: $token');
      return token;
    } catch (e) {
      if (kDebugMode) debugPrint('[Notif] getFcmToken error: $e');
      return null;
    }
  }

  /// Subscribe to token refresh — call this after user logs in.
  /// Pass a callback that saves the new token to Firebase.
  static void onTokenRefresh(Future<void> Function(String token) onRefresh) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (kDebugMode) debugPrint('[Notif] FCM token refreshed');
      await onRefresh(newToken);
    });
  }

  /// Show a local alert notification.
  static Future<void> showLocalAlert({
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !_initialized) {
      if (kDebugMode) debugPrint('[Notif] $title — $body');
      return;
    }
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      // Deterministic ID — same alert type replaces instead of stacking
      final id = title.hashCode.abs() % 10000;
      await _plugin.show(id, title, body, details);
    } catch (e) {
      if (kDebugMode) debugPrint('[Notif] showLocalAlert error: $e');
    }
  }
}
