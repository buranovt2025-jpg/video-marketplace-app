import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/ui/app_ui.dart';
import 'package:tiktok_tutorial/views/screens/buyer/order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  String _selectedFilter = 'all';

  // Align with backend statuses used across the app (created/accepted/ready/picked_up/in_transit/delivered/cancelled).
  final List<String> _filters = ['all', 'created', 'accepted', 'ready', 'in_transit', 'delivered', 'cancelled'];

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'all_orders'.tr;
      case 'created':
        return 'new_orders'.tr;
      case 'accepted':
        return 'active_orders'.tr;
      case 'ready':
        return 'pickup'.tr;
      case 'in_transit':
        return 'deliver'.tr;
      case 'delivered':
        return 'completed_orders'.tr;
      case 'cancelled':
        return 'order_cancelled'.tr;
      default:
        return filter;
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final orders = _controller.orders.where((o) {
      // Defense-in-depth: ensure buyers see only their orders (API may already filter).
      if (_controller.userRole == 'buyer') {
        return o['buyer_id'] == _controller.userId;
      }
      return true;
    }).toList();
    if (_selectedFilter == 'all') {
      return orders;
    }
    return orders.where((o) => o['status'] == _selectedFilter).toList();
  }

  void _showCancelDialog(Map<String, dynamic> order) {
    final status = order['status'];
    if (status != 'pending' && status != 'accepted') {
      Get.snackbar(
        'error'.tr,
        'cannot_cancel'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final TextEditingController reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('cancel_order'.tr, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'cancel_reason'.tr,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Укажите причину отмены...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _cancelOrder(order, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  void _cancelOrder(Map<String, dynamic> order, String reason) {
    // In real app, call API to cancel order
    Get.snackbar(
      'success'.tr,
      'order_cancelled'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_delivery':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'new_orders'.tr;
      case 'accepted':
        return 'active_orders'.tr;
      case 'in_delivery':
        return 'deliver'.tr;
      case 'delivered':
        return 'completed_orders'.tr;
      case 'cancelled':
        return 'order_cancelled'.tr;
      default:
        return status;
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
          'order_history'.tr,
          style: AppUI.h2,
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(_getFilterLabel(filter)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: surfaceColor,
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                    ),
                    checkmarkColor: Colors.white,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          
          // Orders list
          Expanded(
            child: Obx(() {
              final orders = _filteredOrders;
              
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 80, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'no_results'.tr,
                        style: AppUI.h2.copyWith(color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: AppUI.pagePadding,
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildOrderCard(order);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final canCancel = status == 'pending' || status == 'accepted';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Заказ #${order['id']?.substring(0, 8) ?? ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  '${order['total_amount']?.toStringAsFixed(0) ?? '0'} сум',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order['delivery_address'] ?? 'Адрес не указан',
                  style: AppUI.muted,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            onTap: () => Get.to(() => OrderTrackingScreen(order: order)),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.to(() => OrderTrackingScreen(order: order)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.16)),
                    ),
                    child: Text('Подробнее'),
                  ),
                ),
                if (canCancel) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCancelDialog(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: Text('cancel_order'.tr),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
