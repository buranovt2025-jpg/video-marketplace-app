import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'type': 'order',
      'order_id': '12345',
      'time_minutes': 5,
      'read': false,
    },
    {
      'id': '2',
      'type': 'delivery',
      'order_id': '12344',
      'time_hours': 1,
      'read': true,
    },
    {
      'id': '3',
      'type': 'review',
      'time_hours': 2,
      'read': true,
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
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_notifications.any((n) => n['read'] == false))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'mark_all_read'.tr,
                style: const TextStyle(color: primaryColor),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'no_notifications'.tr,
                    style: TextStyle(color: Colors.grey[400], fontSize: 18),
                  ),
                ],
              ),
            )
          : ListView.builder(
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
    final type = notification['type']?.toString() ?? 'order';
    final orderId = notification['order_id']?.toString();
    final minutes = notification['time_minutes'];
    final hours = notification['time_hours'];

    final title = switch (type) {
      'order' => 'notif_new_order_title'.tr,
      'delivery' => 'notif_order_delivered_title'.tr,
      'review' => 'notif_new_review_title'.tr,
      _ => 'notifications'.tr,
    };

    final message = switch (type) {
      'order' => 'notif_new_order_message'.trParams({'id': orderId ?? ''}),
      'delivery' => 'notif_order_delivered_message'.trParams({'id': orderId ?? ''}),
      'review' => 'notif_new_review_message'.tr,
      _ => '',
    };

    final timeText = (minutes is int)
        ? 'time_minutes_ago'.trParams({'n': '$minutes'})
        : (hours is int)
            ? 'time_hours_ago'.trParams({'n': '$hours'})
            : 'time_recent'.tr;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[900] : Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: isRead ? null : Border.all(color: primaryColor.withOpacity(0.3)),
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
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
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
              message,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 4),
            Text(
              timeText,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
