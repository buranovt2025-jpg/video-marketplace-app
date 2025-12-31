import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/screens/buyer/order_tracking_screen.dart';
import 'package:tiktok_tutorial/utils/money.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  String _selectedFilter = 'all';

  final List<String> _filters = ['all', 'pending', 'accepted', 'in_delivery', 'delivered', 'cancelled'];

  @override
  void initState() {
    super.initState();
    // Важно: этот экран не гарантирует, что orders уже загружены.
    // Подгружаем после первой отрисовки, чтобы избежать серого/пустого экрана.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_controller.isLoggedIn) {
        await _controller.fetchOrders();
      }
    });
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'all_orders'.tr;
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
        return filter;
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final orders = _controller.orders;
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
                hintText: 'cancel_reason_hint'.tr,
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
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    backgroundColor: Colors.grey[800],
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
                        style: TextStyle(color: Colors.grey[400], fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _controller.isLoggedIn ? _controller.fetchOrders : null,
                        icon: const Icon(Icons.refresh),
                        label: Text('refresh'.tr),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey[700]!),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  if (_controller.isLoggedIn) {
                    await _controller.fetchOrders();
                  }
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(order);
                  },
                ),
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
    final orderIdStr = (order['id'] ?? '').toString();
    final orderIdShort = orderIdStr.length > 8 ? orderIdStr.substring(0, 8) : orderIdStr;
    final totalNum = (order['total'] is num) ? (order['total'] as num) : (order['total_amount'] is num) ? (order['total_amount'] as num) : 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'order_number_short'.trParams({'id': orderIdShort}),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
                      fontWeight: FontWeight.bold,
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
                  formatMoneyWithCurrency(totalNum),
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order['delivery_address'] ?? 'address_not_specified'.tr,
                  style: TextStyle(color: Colors.grey[400]),
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
                      side: BorderSide(color: Colors.grey[700]!),
                    ),
                    child: Text('details'.tr),
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
