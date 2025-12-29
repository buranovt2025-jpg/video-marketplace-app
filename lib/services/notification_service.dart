import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/services/api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}

class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  
  Future<NotificationService> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Request permissions on Android 13+
    await _requestPermissions();
    
    // Initialize Firebase Cloud Messaging
    await _initFirebaseMessaging();
    
    return this;
  }
  
  Future<void> _initFirebaseMessaging() async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    print('FCM permission status: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $_fcmToken');
      
      // Register token with backend if user is logged in
      if (_fcmToken != null) {
        _registerTokenWithBackend(_fcmToken!);
      }
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM Token refreshed: $newToken');
        _registerTokenWithBackend(newToken);
      });
      
      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    }
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      _notifications.show(
        notification.hashCode,
        notification.title ?? 'GoGoMarket',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_channel',
            'Push уведомления',
            channelDescription: 'Уведомления от сервера',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['type'] ?? '',
      );
    }
  }
  
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    
    if (type == 'order') {
      Get.toNamed('/orders');
    } else if (type == 'chat') {
      Get.toNamed('/chat');
    }
  }
  
  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }
  
  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - navigate to relevant screen
    final payload = response.payload;
    if (payload != null) {
      if (payload.startsWith('order:')) {
        // Navigate to order details
        Get.toNamed('/orders');
      }
    }
  }
  
  // Show new order notification (for sellers)
  Future<void> showNewOrderNotification({
    required String orderId,
    required String buyerName,
    required double amount,
  }) async {
    await _notifications.show(
      orderId.hashCode,
      'Новый заказ!',
      'От $buyerName на ${amount.toStringAsFixed(0)} сум',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'orders_channel',
          'Заказы',
          channelDescription: 'Уведомления о новых заказах',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'order:$orderId',
    );
  }
  
  // Show order status update notification (for buyers)
  Future<void> showOrderStatusNotification({
    required String orderId,
    required String status,
  }) async {
    String title;
    String body;
    
    switch (status) {
      case 'accepted':
        title = 'Заказ принят!';
        body = 'Продавец принял ваш заказ и начал подготовку';
        break;
      case 'ready':
        title = 'Заказ готов!';
        body = 'Ваш заказ готов и ожидает курьера';
        break;
      case 'picked_up':
        title = 'Курьер забрал заказ';
        body = 'Ваш заказ в пути к вам';
        break;
      case 'delivered':
        title = 'Заказ доставлен!';
        body = 'Спасибо за покупку!';
        break;
      case 'rejected':
        title = 'Заказ отклонён';
        body = 'К сожалению, продавец отклонил ваш заказ';
        break;
      default:
        title = 'Обновление заказа';
        body = 'Статус заказа изменён на: $status';
    }
    
    await _notifications.show(
      orderId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'order_updates_channel',
          'Обновления заказов',
          channelDescription: 'Уведомления об изменении статуса заказов',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'order:$orderId',
    );
  }
  
  // Show courier assignment notification (for couriers)
  Future<void> showCourierAssignmentNotification({
    required String orderId,
    required String address,
  }) async {
    await _notifications.show(
      orderId.hashCode,
      'Новая доставка!',
      'Адрес: $address',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'courier_channel',
          'Доставки',
          channelDescription: 'Уведомления о новых доставках',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'order:$orderId',
    );
  }
  
  // Show timer warning notification
  Future<void> showTimerWarningNotification({
    required String orderId,
    required int minutesLeft,
  }) async {
    await _notifications.show(
      'timer_$orderId'.hashCode,
      'Время истекает!',
      'Осталось $minutesLeft мин. на принятие заказа',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'timer_channel',
          'Таймеры',
          channelDescription: 'Уведомления о таймерах заказов',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'order:$orderId',
    );
  }
  
  // Cancel notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
  
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
  
  // Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      await ApiService.registerFcmToken(token);
      print('FCM token registered with backend');
    } catch (e) {
      print('Failed to register FCM token with backend: $e');
      // Token registration failed, but don't block the app
    }
  }
  
  // Public method to register token (call after login)
  Future<void> registerTokenAfterLogin() async {
    if (_fcmToken != null) {
      await _registerTokenWithBackend(_fcmToken!);
    }
  }
  
  // Unregister token on logout
  Future<void> unregisterTokenOnLogout() async {
    if (_fcmToken != null) {
      try {
        await ApiService.unregisterFcmToken(_fcmToken!);
        print('FCM token unregistered from backend');
      } catch (e) {
        print('Failed to unregister FCM token: $e');
      }
    }
  }
}
