import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gogomarket/constants.dart';
import 'package:gogomarket/controllers/marketplace_controller.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  String _filterStatus = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    await _controller.fetchOrders();
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final orders = _controller.orders;
    if (_filterStatus == 'all') return orders;
    return orders.where((o) => o['status'] == _filterStatus).toList();
  }

  // Calculate totals for summary
  double get _totalRevenue {
    return _controller.orders.fold(0.0, (sum, order) {
      if (order['status'] != 'cancelled') {
        return sum + (order['total_amount'] ?? 0.0);
      }
      return sum;
    });
  }

  int get _completedOrders {
    return _controller.orders.where((o) => 
      o['status'] == 'delivered' || o['status'] == 'completed'
    ).length;
  }

  int get _pendingOrders {
    return _controller.orders.where((o) => 
      o['status'] != 'delivered' && o['status'] != 'completed' && o['status'] != 'cancelled'
    ).length;
  }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          title: const Text(
            'Транзакции',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadOrders,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryColor))
            : Column(
          children: [
            // Summary cards
            _buildSummarySection(),
          
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('Все', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Новые', 'created'),
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
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[700]),
                        const SizedBox(height: 16),
                        Text(
                          'Нет транзакций',
                          style: TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
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

    Widget _buildSummarySection() {
      return Obx(() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildSummaryCard(
                  'Общая выручка',
                  '${_formatPrice(_totalRevenue)} сум',
                  Icons.account_balance_wallet,
                  Colors.green,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard(
                  'Всего заказов',
                  '${_controller.orders.length}',
                  Icons.receipt_long,
                  Colors.blue,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSummaryCard(
                  'Выполнено',
                  '$_completedOrders',
                  Icons.check_circle,
                  Colors.green,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard(
                  'В процессе',
                  '$_pendingOrders',
                  Icons.pending,
                  Colors.orange,
                )),
              ],
            ),
          ],
        ),
      ));
    }

    Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    String _formatPrice(double price) {
      if (price >= 1000000) {
        return '${(price / 1000000).toStringAsFixed(1)}M';
      } else if (price >= 1000) {
        return '${(price / 1000).toStringAsFixed(0)}K';
      }
      return price.toStringAsFixed(0);
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
        'created': 'Новый',
        'accepted': 'Принят',
        'ready': 'Готов',
        'picked_up': 'Забран',
        'in_transit': 'В пути',
        'delivered': 'Доставлен',
        'completed': 'Завершён',
        'cancelled': 'Отменён',
      };

      final paymentLabels = {
        'cash': 'Наличные',
        'card': 'Карта',
        'click': 'Click',
        'payme': 'Payme',
      };

      final status = order['status'] ?? 'created';
      final totalAmount = (order['total_amount'] ?? 0.0) is int 
          ? (order['total_amount'] as int).toDouble() 
          : (order['total_amount'] ?? 0.0);
      final items = order['items'] as List? ?? [];
      final paymentMethod = order['payment_method'] ?? 'cash';
      final createdAt = order['created_at'];

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
              // Header with order ID and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Заказ #${order['id']?.toString().substring(0, 8) ?? ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                    ],
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

              // Participants row
              Row(
                children: [
                  // Buyer
                  Expanded(
                    child: _buildParticipantChip(
                      Icons.person,
                      order['buyer_name'] ?? 'Покупатель',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Seller
                  Expanded(
                    child: _buildParticipantChip(
                      Icons.store,
                      order['seller_name'] ?? 'Продавец',
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Courier
                  Expanded(
                    child: _buildParticipantChip(
                      Icons.delivery_dining,
                      order['courier_name'] ?? 'Не назначен',
                      order['courier_name'] != null ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Amount and payment method
              Row(
                children: [
                  Icon(Icons.payments_outlined, size: 18, color: Colors.green[400]),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatPrice(totalAmount)} сум',
                    style: TextStyle(
                      color: Colors.green[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      paymentLabels[paymentMethod] ?? paymentMethod,
                      style: const TextStyle(color: Colors.purple, fontSize: 11),
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

    Widget _buildParticipantChip(IconData icon, String name, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                name,
                style: TextStyle(color: color, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    String _formatDate(dynamic dateValue) {
      try {
        DateTime date;
        if (dateValue is String) {
          date = DateTime.parse(dateValue);
        } else {
          return '';
        }
        return DateFormat('dd.MM.yyyy HH:mm').format(date);
      } catch (e) {
        return '';
      }
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
      final paymentLabels = {
        'cash': 'Наличные',
        'card': 'Карта',
        'click': 'Click',
        'payme': 'Payme',
      };
      final totalAmount = (order['total_amount'] ?? 0.0) is int 
          ? (order['total_amount'] as int).toDouble() 
          : (order['total_amount'] ?? 0.0);
    
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
              
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Заказ #${order['id']?.toString().substring(0, 8) ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (order['created_at'] != null)
                      Text(
                        _formatDate(order['created_at']),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              
                // Participants section
                const Text(
                  'Участники сделки:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
              
                // Buyer info
                _buildParticipantRow(
                  Icons.person,
                  'Покупатель',
                  order['buyer_name'] ?? 'Не указан',
                  order['buyer_email'],
                  order['buyer_phone'],
                  Colors.blue,
                ),
                const SizedBox(height: 8),
              
                // Seller info
                _buildParticipantRow(
                  Icons.store,
                  'Продавец',
                  order['seller_name'] ?? 'Не указан',
                  order['seller_email'],
                  null,
                  Colors.orange,
                ),
                const SizedBox(height: 8),
              
                // Courier info
                _buildParticipantRow(
                  Icons.delivery_dining,
                  'Курьер',
                  order['courier_name'] ?? 'Не назначен',
                  null,
                  null,
                  order['courier_name'] != null ? Colors.green : Colors.grey,
                ),
              
                const SizedBox(height: 16),
                const Divider(color: Colors.grey),
                const SizedBox(height: 16),
              
                // Delivery info
                _buildDetailRow('Адрес доставки', order['delivery_address'] ?? 'Не указан'),
                _buildDetailRow('Способ оплаты', paymentLabels[order['payment_method']] ?? 'Наличные'),
              
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
                          '${item['product_name'] ?? item['name'] ?? 'Товар'} x${item['quantity'] ?? 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Text(
                        '${_formatPrice(((item['price'] ?? 0) * (item['quantity'] ?? 1)).toDouble())} сум',
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
                      '${_formatPrice(totalAmount)} сум',
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

    Widget _buildParticipantRow(IconData icon, String role, String name, String? email, String? phone, Color color) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  Text(
                    name,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  if (email != null)
                    Text(
                      email,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  if (phone != null)
                    Text(
                      phone,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
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
