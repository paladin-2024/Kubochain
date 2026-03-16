import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Firebase imports — only used when Firebase is configured
// ignore: depend_on_referenced_packages
import 'package:firebase_messaging/firebase_messaging.dart';

import 'api_service.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}

class AppNotification {
  final String title;
  final String body;
  final DateTime time;
  final String? type; // 'ride_request', 'ride_accepted', 'driver_arrived', 'trip_completed', etc.

  AppNotification({
    required this.title,
    required this.body,
    required this.time,
    this.type,
  });
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'kubochain_main';
  static const _channelName = 'KuboChain';
  static const _channelDesc = 'Ride updates, promotions, and alerts';

  // In-memory notification history (shown in the notifications screen)
  static final List<AppNotification> _history = [];
  static List<AppNotification> get history => List.unmodifiable(_history);

  // Notify listeners when history changes
  static final _listeners = <VoidCallback>[];
  static void addListener(VoidCallback cb) => _listeners.add(cb);
  static void removeListener(VoidCallback cb) => _listeners.remove(cb);
  static void _notifyListeners() {
    for (final cb in List.of(_listeners)) {
      cb();
    }
  }

  static Future<void> init() async {
    // Local notifications setup
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Firebase Messaging setup
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

      // Show notification when app is in foreground
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n != null) {
          show(title: n.title ?? 'KuboChain', body: n.body ?? '');
        }
      });

      // Save/refresh FCM token to backend
      final token = await messaging.getToken();
      if (token != null) await _saveToken(token);

      messaging.onTokenRefresh.listen((newToken) => _saveToken(newToken));
    } catch (e) {
      debugPrint('Firebase messaging not available: $e');
    }
  }

  static Future<void> _saveToken(String token) async {
    try {
      if (StorageService.isLoggedIn()) {
        await ApiService.updateFcmToken(token);
      }
    } catch (_) {}
  }

  /// Show a local notification immediately and add to history
  static Future<void> show({
    required String title,
    required String body,
    String? type,
  }) async {
    // Add to in-app history
    _history.insert(0, AppNotification(title: title, body: body, time: DateTime.now(), type: type));
    _notifyListeners();

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static void clearHistory() {
    _history.clear();
    _notifyListeners();
  }
}
