import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/screens/courier/courier_order_detail_screen.dart';
import 'package:tiktok_tutorial/views/screens/auth/marketplace_login_screen.dart';

class CourierHomeScreen extends StatefulWidget {
  const CourierHomeScreen({Key? key}) : super(key: key);

  @override
  State<CourierHomeScreen> createState() => _CourierHomeScreenState();
}

class _CourierHomeScreenState extends State<CourierHomeScreen> with SingleTickerProviderStateMixin {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    await _controller.fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text(
          'Курьер',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadOrders,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _controller.logout();
              Get.offAll(() => const MarketplaceLoginScreen());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: buttonColor,
          labelColor: buttonColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Доступные'),
            Tab(text: 'Активные'),
            Tab(text: 'История'),
          ],
        ),
      ),
      body: Obx(() {
        final orders = _controller.orders;
        
        // Filter orders by status
        final availableOrders = orders.where((o) => 
          o['status'] == 'ready' && o['courier_id'] == null
        ).toList();
        
        final activeOrders = orders.where((o) => 
          o['courier_id'] == _controller.userId &&
          ['picked_up', 'in_transit'].contains(o['status'])
        ).toList();
        
        final completedOrders = orders.where((o) => 
          o['courier_id'] == _controller.userId &&
          ['delivered', 'completed'].contains(o['status'])
        ).toList();

        return TabBarView(
          controller: _tabController,
          children: [
            _buildOrdersList(availableOrders, 'available'),
            _buildOrdersList(activeOrders, 'active'),
            _buildOrdersList(completedOrders, 'completed'),
          ],
        );
      }),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders, String type) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'available' ? Icons.local_shipping_outlined :
              type == 'active' ? Icons.directions_bike_outlined :
              Icons.history,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'available' ? 'Нет доступных заказов' :
              type == 'active' ? 'Нет активных заказов' :
              'История пуста',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            if (type == 'available') ...[
              const SizedBox(height: 8),
              Text(
                'Заказы появятся, когда продавцы\nподготовят товары к выдаче',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order, type);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, String type) {
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
      'ready': 'Готов к выдаче',
      'picked_up': 'Забран',
      'in_transit': 'В пути',
      'delivered': 'Доставлен',
      'completed': 'Завершён',
      'cancelled': 'Отменён',
    };

    final status = order['status'] ?? 'created';
    final totalAmount = order['total_amount'] ?? 0.0;

    return GestureDetector(
      onTap: () => Get.to(() => CourierOrderDetailScreen(order: order)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: type == 'available' 
            ? Border.all(color: Colors.purple.withOpacity(0.5), width: 1)
            : null,
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
                  '${totalAmount.toStringAsFixed(0)} сум (наличка)',
                  style: TextStyle(
                    color: Colors.green[400],
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Seller address (pickup)
            if (order['seller_address'] != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.store, size: 18, color: Colors.orange[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Забрать:',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        Text(
                          order['seller_address'] ?? 'Адрес продавца',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Delivery address
            if (order['delivery_address'] != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.blue[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Доставить:',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        Text(
                          order['delivery_address'],
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Items count
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  '${(order['items'] as List?)?.length ?? 0} товар(ов)',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),

            // Action button for available orders
            if (type == 'available') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _acceptOrder(order),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Взять заказ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Взять заказ?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Вы берёте заказ #${order['id']?.substring(0, 8)} на сумму ${order['total_amount']?.toStringAsFixed(0)} сум',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Отмена', style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Взять'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _controller.updateOrderStatus(order['id'], 'picked_up');
      if (success) {
        Get.snackbar(
          'Заказ принят',
          'Теперь заберите товар у продавца',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _tabController.animateTo(1); // Switch to active tab
      } else {
        Get.snackbar(
          'Ошибка',
          'Не удалось взять заказ',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
}
