import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final String? type;
  final bool isRead;

  AppNotification({
    required this.title,
    required this.body,
    required this.time,
    this.type,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'time': time.toIso8601String(),
        'type': type,
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        title: j['title'] ?? '',
        body: j['body'] ?? '',
        time: DateTime.parse(j['time']),
        type: j['type'],
        isRead: j['isRead'] ?? false,
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
        title: title,
        body: body,
        time: time,
        type: type,
        isRead: isRead ?? this.isRead,
      );
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  // Navigation callback — set from main.dart
  static void Function(Map<String, dynamic> data)? _onNotificationTap;
  static void setNotificationTapHandler(void Function(Map<String, dynamic> data) handler) {
    _onNotificationTap = handler;
  }

  static const _channelId = 'kubochain_main';
  static const _channelName = 'KuboChain';
  static const _channelDesc = 'Ride updates, promotions, and alerts';
  static const _prefKey = 'notif_history';

  static final List<AppNotification> _history = [];
  static List<AppNotification> get history => List.unmodifiable(_history);

  /// Number of unread notifications
  static int get unreadCount => _history.where((n) => !n.isRead).length;

  static final _listeners = <VoidCallback>[];
  static void addListener(VoidCallback cb) => _listeners.add(cb);
  static void removeListener(VoidCallback cb) => _listeners.remove(cb);
  static void _notifyListeners() {
    for (final cb in List.of(_listeners)) {
      cb();
    }
  }

  static Future<void> init() async {
    // Load persisted history first so badge shows immediately on login
    await _loadHistory();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

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

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

      // Foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n != null) {
          show(title: n.title ?? 'KuboChain', body: n.body ?? '');
        }
      });

      // App opened from background via notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (message.data.isNotEmpty) {
          _onNotificationTap?.call(Map<String, dynamic>.from(message.data));
        }
        final n = message.notification;
        if (n != null) show(title: n.title ?? 'KuboChain', body: n.body ?? '');
      });

      // App launched from terminated state via notification tap
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        if (initial.data.isNotEmpty) {
          // Delay to let the app finish initializing before navigating
          Future.delayed(const Duration(seconds: 1), () {
            _onNotificationTap?.call(Map<String, dynamic>.from(initial.data));
          });
        }
        final n = initial.notification;
        if (n != null) show(title: n.title ?? 'KuboChain', body: n.body ?? '');
      }

      final token = await messaging.getToken();
      if (token != null) await _saveToken(token);
      messaging.onTokenRefresh.listen((t) => _saveToken(t));
    } catch (e) {
      debugPrint('Firebase messaging not available: $e');
    }
  }

  static Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _history.clear();
        _history.addAll(list.map((e) => AppNotification.fromJson(e)));
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load notification history: $e');
    }
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefKey, jsonEncode(_history.map((n) => n.toJson()).toList()));
    } catch (_) {}
  }

  static Future<void> _saveToken(String token) async {
    try {
      if (StorageService.isLoggedIn()) {
        await ApiService.updateFcmToken(token);
      }
    } catch (_) {}
  }

  /// Show a local notification and persist it
  static Future<void> show({
    required String title,
    required String body,
    String? type,
  }) async {
    _history.insert(
        0, AppNotification(title: title, body: body, time: DateTime.now(), type: type));
    if (_history.length > 50) _history.removeRange(50, _history.length);
    await _persist();
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

  /// Mark all notifications as read (call when user opens the notifications screen)
  static Future<void> markAllRead() async {
    for (int i = 0; i < _history.length; i++) {
      _history[i] = _history[i].copyWith(isRead: true);
    }
    await _persist();
    _notifyListeners();
  }

  static Future<void> clearHistory() async {
    _history.clear();
    await _persist();
    _notifyListeners();
  }
}
