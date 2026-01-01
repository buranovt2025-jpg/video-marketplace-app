import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/utils/money.dart';

class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
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
    
    return this;
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
      'От $buyerName на ${formatMoneyWithCurrency(amount)}',
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
}
