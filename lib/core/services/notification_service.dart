import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  } catch (_) {
    // Native Firebase configuration is required for background delivery.
  }
}

class NotificationService {
  NotificationService({required this.firebaseReady});

  final bool firebaseReady;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final StreamController<String> _orderClicks =
      StreamController<String>.broadcast();
  String? _pendingOrderId;
  bool _permissionsRequested = false;

  Stream<String> get orderClicks => _orderClicks.stream;

  String? takePendingOrderId() {
    final value = _pendingOrderId;
    _pendingOrderId = null;
    return value;
  }

  static const _channel = AndroidNotificationChannel(
    'mazboot_orders',
    'تحديثات الطلبات',
    description: 'قبول الطلب ووصول الفني وتحديثات حالة الخدمة',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final orderId = response.payload;
        if (orderId != null && orderId.isNotEmpty) _emitOrderClick(orderId);
      },
    );
    final localLaunch = await _local.getNotificationAppLaunchDetails();
    final localOrderId = localLaunch?.notificationResponse?.payload;
    if (localLaunch?.didNotificationLaunchApp == true &&
        localOrderId != null &&
        localOrderId.isNotEmpty) {
      _emitOrderClick(localOrderId);
    }
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channel);
    if (!firebaseReady) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(showRemoteMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteOpen);
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleRemoteOpen(initialMessage);
  }

  Future<void> requestPermissions() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    if (firebaseReady) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<String?> token() async {
    if (!firebaseReady) return null;
    return FirebaseMessaging.instance.getToken();
  }

  Future<void> showRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      notification.hashCode,
      notification.title ?? 'Mazboot',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mazboot_orders',
          'تحديثات الطلبات',
          channelDescription: 'قبول الطلب ووصول الفني وتحديثات حالة الخدمة',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['orderId']?.toString(),
    );
  }

  void _handleRemoteOpen(RemoteMessage message) {
    final orderId = message.data['orderId']?.toString();
    if (orderId != null && orderId.isNotEmpty) _emitOrderClick(orderId);
  }

  void _emitOrderClick(String orderId) {
    if (_orderClicks.hasListener) {
      _orderClicks.add(orderId);
    } else {
      _pendingOrderId = orderId;
    }
  }
}
