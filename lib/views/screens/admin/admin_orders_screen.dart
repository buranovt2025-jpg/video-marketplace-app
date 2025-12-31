import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/utils/formatters.dart';
import 'package:tiktok_tutorial/utils/money.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _controller.fetchOrders();
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final orders = _controller.orders;
    if (_filterStatus == 'all') return orders;
    return orders.where((o) => o['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text(
          'Заказы',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _controller.fetchOrders(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Все', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Создан', 'created'),
                const SizedBox(width: 8),
                _buildFilterChip('Принят', 'accepted'),
                const SizedBox(width: 8),
                _buildFilterChip('Готов', 'ready'),
                const SizedBox(width: 8),
                _buildFilterChip('В пути', 'in_transit'),
                const SizedBox(width: 8),
                _buildFilterChip('Доставлен', 'delivered'),
                const SizedBox(width: 8),
                _buildFilterChip('Отменён', 'cancelled'),
              ],
            ),
          ),
          
          // Orders list
          Expanded(
            child: Obx(() {
              final orders = _filteredOrders;
              
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        'Нет заказов',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () => _controller.fetchOrders(),
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

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _filterStatus == status;
    final statusColors = {
      'all': buttonColor,
      'created': Colors.blue,
      'accepted': Colors.orange,
      'ready': Colors.purple,
      'picked_up': Colors.indigo,
      'in_transit': Colors.cyan,
      'delivered': Colors.green,
      'completed': Colors.green,
      'cancelled': Colors.red,
    };
    
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? statusColors[status] : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final statusColors = {
      'created': Colors.blue,
      'accepted': Colors.orange,
      'ready': Colors.purple,
      'picked_up': Colors.indigo,
      'in_transit': Colors.cyan,
      'delivered': Colors.green,
      'completed': Colors.green,
      'cancelled': Colors.red,
    };

    final statusLabels = {
      'created': 'Создан',
      'accepted': 'Принят',
      'ready': 'Готов',
      'picked_up': 'Забран',
      'in_transit': 'В пути',
      'delivered': 'Доставлен',
      'completed': 'Завершён',
      'cancelled': 'Отменён',
    };

    final status = order['status'] ?? 'created';
    final totalAmount = order['total_amount'] ?? 0.0;
    final items = order['items'] as List? ?? [];

    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Заказ #${order['id']?.substring(0, 8) ?? ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColors[status]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabels[status] ?? status,
                    style: TextStyle(
                      color: statusColors[status],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount
            Row(
              children: [
                Icon(Icons.payments_outlined, size: 18, color: Colors.green[400]),
                const SizedBox(width: 8),
                Text(
                  formatMoneyWithCurrency(totalAmount),
                  style: TextStyle(
                    color: Colors.green[400],
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length} товар(ов)',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Delivery address
            if (order['delivery_address'] != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order['delivery_address'],
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Status change buttons
            const SizedBox(height: 12),
            _buildStatusChangeButtons(order, status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChangeButtons(Map<String, dynamic> order, String currentStatus) {
    final nextStatuses = <String, String>{
      'created': 'accepted',
      'accepted': 'ready',
      'ready': 'picked_up',
      'picked_up': 'in_transit',
      'in_transit': 'delivered',
      'delivered': 'completed',
    };

    final statusLabels = {
      'accepted': 'Принять',
      'ready': 'Готов к выдаче',
      'picked_up': 'Забран',
      'in_transit': 'В пути',
      'delivered': 'Доставлен',
      'completed': 'Завершить',
      'cancelled': 'Отменить',
    };

    if (currentStatus == 'completed' || currentStatus == 'cancelled') {
      return const SizedBox.shrink();
    }

    final nextStatus = nextStatuses[currentStatus];

    return Row(
      children: [
        if (nextStatus != null)
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateOrderStatus(order['id'], nextStatus),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(statusLabels[nextStatus] ?? nextStatus),
            ),
          ),
        if (nextStatus != null && currentStatus != 'delivered')
          const SizedBox(width: 8),
        if (currentStatus != 'delivered' && currentStatus != 'completed')
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateOrderStatus(order['id'], 'cancelled'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Отменить'),
            ),
          ),
      ],
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    final success = await _controller.updateOrderStatus(orderId, newStatus);
    if (success) {
      Get.snackbar(
        'Успешно',
        'Статус заказа обновлён',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Ошибка',
        'Не удалось обновить статус',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final items = order['items'] as List? ?? [];
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Заказ #${order['id']?.substring(0, 8) ?? ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Buyer info
              _buildDetailRow('Покупатель', order['buyer_name'] ?? 'Не указан'),
              _buildDetailRow('Адрес доставки', order['delivery_address'] ?? 'Не указан'),
              _buildDetailRow('Телефон', order['buyer_phone'] ?? 'Не указан'),
              
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 16),
              
              // Items
              const Text(
                'Товары:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item['name'] ?? 'Товар'} x${item['quantity'] ?? 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Text(
                      formatMoneyWithCurrency(asDouble(item['price']) * asInt(item['quantity'], fallback: 1)),
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              )).toList(),
              
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 16),
              
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Итого:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    formatMoneyWithCurrency(order['total_amount']),
                    style: TextStyle(
                      color: Colors.green[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
