import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/ui/app_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Новый заказ',
      'message': 'Вы получили новый заказ #12345',
      'time': '5 мин назад',
      'read': false,
      'type': 'order',
    },
    {
      'id': '2',
      'title': 'Заказ доставлен',
      'message': 'Ваш заказ #12344 успешно доставлен',
      'time': '1 час назад',
      'read': true,
      'type': 'delivery',
    },
    {
      'id': '3',
      'title': 'Новый отзыв',
      'message': 'Покупатель оставил отзыв на ваш товар',
      'time': '2 часа назад',
      'read': true,
      'type': 'review',
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
    });
    Get.snackbar(
      'success'.tr,
      'mark_all_read'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag;
      case 'delivery':
        return Icons.local_shipping;
      case 'review':
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'delivery':
        return Colors.green;
      case 'review':
        return Colors.amber;
      default:
        return primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'notifications'.tr,
          style: AppUI.h2,
        ),
        actions: [
          if (_notifications.any((n) => n['read'] == false))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'mark_all_read'.tr,
                style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.white.withOpacity(0.22)),
                  const SizedBox(height: 16),
                  Text(
                    'no_notifications'.tr,
                    style: AppUI.h2.copyWith(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: AppUI.pagePadding,
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationItem(notification);
              },
            ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['read'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppUI.cardDecoration(radius: AppUI.radiusL).copyWith(
        color: isRead ? cardColor : const Color(0xFF202020),
        border: Border.all(color: isRead ? Colors.white.withOpacity(0.06) : primaryColor.withOpacity(0.25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification['type']).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getNotificationIcon(notification['type']),
            color: _getNotificationColor(notification['type']),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification['title'],
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification['message'],
              style: AppUI.muted,
            ),
            const SizedBox(height: 4),
            Text(
              notification['time'],
              style: AppUI.muted.copyWith(fontSize: 12),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            notification['read'] = true;
          });
        },
      ),
    );
  }
}
