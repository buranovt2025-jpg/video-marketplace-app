import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/widgets/app_network_image.dart';
import 'package:tiktok_tutorial/utils/formatters.dart';
import 'package:tiktok_tutorial/views/screens/seller/my_products_screen.dart';
import 'package:tiktok_tutorial/views/screens/common/qr_code_screen.dart';
import 'package:tiktok_tutorial/views/screens/seller/seller_analytics_screen.dart';

class SellerCabinetScreen extends StatefulWidget {
  const SellerCabinetScreen({Key? key}) : super(key: key);

  @override
  State<SellerCabinetScreen> createState() => _SellerCabinetScreenState();
}

class _SellerCabinetScreenState extends State<SellerCabinetScreen> with SingleTickerProviderStateMixin {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  late TabController _tabController;
  
  // Order acceptance timer - 5 minutes to accept
  static const int _orderAcceptanceTimeSeconds = 300; // 5 minutes
  final Map<String, int> _orderTimers = {}; // orderId -> remaining seconds
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }
  
  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        final keysToRemove = <String>[];
        _orderTimers.forEach((orderId, seconds) {
          if (seconds > 0) {
            _orderTimers[orderId] = seconds - 1;
          } else {
            keysToRemove.add(orderId);
            // Auto-reject order when timer expires
            _autoRejectOrder(orderId);
          }
        });
        for (var key in keysToRemove) {
          _orderTimers.remove(key);
        }
      });
    });
  }
  
  void _initializeOrderTimer(String orderId) {
    if (!_orderTimers.containsKey(orderId)) {
      _orderTimers[orderId] = _orderAcceptanceTimeSeconds;
    }
  }
  
  Future<void> _autoRejectOrder(String orderId) async {
    try {
      await _controller.updateOrderStatus(orderId, 'rejected');
      Get.snackbar(
        'Время истекло',
        'Заказ автоматически отклонён',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      // Ignore errors
    }
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    await _controller.fetchOrders();
    await _controller.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text('my_cabinet'.tr, style: const TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'orders'.tr),
            Tab(text: 'statistics'.tr),
            Tab(text: 'Товары'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab(),
          _buildStatisticsTab(),
          _buildInventoryTab(),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Obx(() {
      final orders = _controller.orders.where((o) {
        final sellerId = _controller.currentUser.value?['id'];
        return o['seller_id'] == sellerId;
      }).toList();

      if (orders.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey[700]),
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
        onRefresh: _loadData,
        color: primaryColor,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        ),
      );
    });
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final isPending = status == 'pending';
    final orderId = order['id']?.toString() ?? '';
    
    // Initialize timer for pending orders
    if (isPending && orderId.isNotEmpty) {
      _initializeOrderTimer(orderId);
    }
    
    Color statusColor;
    String statusText;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Ожидает';
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusText = 'Принят';
        break;
      case 'ready':
        statusColor = Colors.green;
        statusText = 'Готов к выдаче';
        break;
      case 'delivered':
        statusColor = Colors.grey;
        statusText = 'Доставлен';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Отклонён';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Заказ #${orderId.length >= 8 ? orderId.substring(0, 8) : orderId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            
            // Timer for pending orders
            if (isPending && _orderTimers.containsKey(orderId)) ...[
              const SizedBox(height: 12),
              _buildTimerWidget(orderId),
            ],
            
            const SizedBox(height: 12),
            Text(
              'Сумма: ${formatMoney(order['total_amount'], suffix: 'сум')}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              'Адрес: ${order['delivery_address'] ?? 'Не указан'}',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptOrder(orderId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('accept'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectOrder(orderId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: Text('reject'.tr),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'accepted') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _markReady(orderId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Готов к выдаче'),
                ),
              ),
            ],
            // Show QR button for ready orders
            if (status == 'ready') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPickupQR(orderId),
                  icon: const Icon(Icons.qr_code),
                  label: Text('show_qr'.tr + ' - ' + 'pickup_qr'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimerWidget(String orderId) {
    final remainingSeconds = _orderTimers[orderId] ?? 0;
    final isUrgent = remainingSeconds < 60; // Less than 1 minute
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.withOpacity(0.2) : primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUrgent ? Colors.red : primaryColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: isUrgent ? Colors.red : primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Осталось: ${_formatTime(remainingSeconds)}',
            style: TextStyle(
              color: isUrgent ? Colors.red : primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (isUrgent) ...[
            const SizedBox(width: 8),
            const Text(
              'Срочно!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _acceptOrder(String? orderId) async {
    if (orderId == null || orderId.isEmpty) return;
    try {
      await _controller.updateOrderStatus(orderId, 'accepted');
      _orderTimers.remove(orderId); // Remove timer when accepted
      Get.snackbar('success'.tr, 'Заказ принят', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('error'.tr, 'Не удалось принять заказ', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _rejectOrder(String? orderId) async {
    if (orderId == null || orderId.isEmpty) return;
    try {
      await _controller.updateOrderStatus(orderId, 'rejected');
      _orderTimers.remove(orderId); // Remove timer when rejected
      Get.snackbar('success'.tr, 'Заказ отклонён', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('error'.tr, 'Не удалось отклонить заказ', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _markReady(String? orderId) async {
    if (orderId == null) return;
    try {
      await _controller.updateOrderStatus(orderId, 'ready');
      Get.snackbar('success'.tr, 'Заказ готов к выдаче', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('error'.tr, 'Не удалось обновить статус', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showPickupQR(String orderId) {
    Get.to(() => QRCodeScreen(
      orderId: orderId,
      type: 'pickup',
      title: 'show_qr'.tr,
      subtitle: 'Курьер должен отсканировать этот QR-код',
    ));
  }

  Widget _buildStatisticsTab() {
    return Obx(() {
      final orders = _controller.orders.where((o) {
        final sellerId = _controller.currentUser.value?['id'];
        return o['seller_id'] == sellerId;
      }).toList();

      final completedOrders = orders.where((o) => o['status'] == 'delivered').toList();
      final totalRevenue = completedOrders.fold<double>(
        0,
        (sum, order) => sum + asDouble(order['total_amount']),
      );
      final pendingOrders = orders.where((o) => o['status'] == 'pending').length;
      final activeOrders = orders.where((o) => 
        o['status'] == 'accepted' || o['status'] == 'ready'
      ).length;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'statistics'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Выручка',
                    '${totalRevenue.toStringAsFixed(0)} сум',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Заказов',
                    '${completedOrders.length}',
                    Icons.shopping_bag,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Ожидают',
                    '$pendingOrders',
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Активные',
                    '$activeOrders',
                    Icons.local_shipping,
                    primaryColor,
                  ),
                ),
              ],
            ),
            
              const SizedBox(height: 24),
            
              // Detailed analytics button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Get.to(() => const SellerAnalyticsScreen()),
                  icon: const Icon(Icons.analytics),
                  label: Text('detailed_analytics'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            
              const SizedBox(height: 32),
              const Text(
                'Топ товары',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTopProducts(),
            ],
          ),
        );
      });
    }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    return Obx(() {
      final products = _controller.products.where((p) {
        final sellerId = _controller.currentUser.value?['id'];
        return p['seller_id'] == sellerId;
      }).take(5).toList();

      if (products.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Нет товаров',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        );
      }

      return Column(
        children: products.map((product) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product['image_url'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppNetworkImage(
                            url: product['image_url']?.toString(),
                            fit: BoxFit.cover,
                            errorWidget: Icon(Icons.inventory_2, color: Colors.grey[600]),
                          ),
                        )
                      : Icon(Icons.inventory_2, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? 'Товар',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        formatMoney(product['price'], suffix: 'сум'),
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  'В наличии: ${product['quantity'] ?? 0}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildInventoryTab() {
    return Obx(() {
      final products = _controller.products.where((p) {
        final sellerId = _controller.currentUser.value?['id'];
        return p['seller_id'] == sellerId;
      }).toList();

      if (products.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2, size: 64, color: Colors.grey[700]),
              const SizedBox(height: 16),
              Text(
                'Нет товаров',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.to(() => const MyProductsScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                child: const Text('Добавить товар'),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _loadData,
        color: primaryColor,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildInventoryCard(product);
          },
        ),
      );
    });
  }

  Widget _buildInventoryCard(Map<String, dynamic> product) {
    final quantity = product['quantity'] ?? 0;
    final isLowStock = quantity < 5;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: product['image_url'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppNetworkImage(
                        url: product['image_url']?.toString(),
                        fit: BoxFit.cover,
                        errorWidget: Icon(Icons.inventory_2, color: Colors.grey[600]),
                      ),
                    )
                  : Icon(Icons.inventory_2, color: Colors.grey[600]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Товар',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatMoney(product['price'], suffix: 'сум'),
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLowStock ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$quantity шт',
                    style: TextStyle(
                      color: isLowStock ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isLowStock)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Мало!',
                      style: TextStyle(color: Colors.red[300], fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
