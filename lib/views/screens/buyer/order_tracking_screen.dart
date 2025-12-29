import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gogomarket/constants.dart';
import 'package:gogomarket/controllers/marketplace_controller.dart';
import 'package:gogomarket/views/screens/buyer/delivery_map_screen.dart';
import 'package:gogomarket/views/screens/chat/chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderTrackingScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  late Map<String, dynamic> _order;

  final List<Map<String, dynamic>> _statusSteps = [
    {'status': 'created', 'title': 'Заказ создан', 'icon': Icons.receipt_long},
    {'status': 'accepted', 'title': 'Принят продавцом', 'icon': Icons.store},
    {'status': 'ready', 'title': 'Готов к отправке', 'icon': Icons.inventory},
    {'status': 'picked_up', 'title': 'Забран курьером', 'icon': Icons.local_shipping},
    {'status': 'in_transit', 'title': 'В пути', 'icon': Icons.directions_bike},
    {'status': 'delivered', 'title': 'Доставлен', 'icon': Icons.check_circle},
  ];

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  int _getCurrentStepIndex() {
    final status = _order['status'];
    if (status == 'completed') return _statusSteps.length;
    if (status == 'cancelled') return -1;
    
    final index = _statusSteps.indexWhere((step) => step['status'] == status);
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _getCurrentStepIndex();
    final isCancelled = _order['status'] == 'cancelled';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text(
          'Отслеживание заказа',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshOrder,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            _buildOrderHeader(),
            const SizedBox(height: 24),

            // Status timeline
            if (!isCancelled) ...[
              const Text(
                'Статус заказа',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatusTimeline(currentStep),
            ] else
              _buildCancelledStatus(),
            const SizedBox(height: 24),

            // Delivery info
            _buildDeliveryInfo(),
            const SizedBox(height: 24),

            // Order items
            const Text(
              'Товары в заказе',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildOrderItems(),
            const SizedBox(height: 24),

            // Contact buttons
            _buildContactButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Заказ #${_order['id']?.substring(0, 8) ?? 'N/A'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_order['status']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(_order['status']),
                  style: TextStyle(
                    color: _getStatusColor(_order['status']),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Сумма:',
                style: TextStyle(color: Colors.grey[400]),
              ),
              Text(
                '${_formatPrice(_order['total_amount'])} сум',
                style: TextStyle(
                  color: buttonColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(int currentStep) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(_statusSteps.length, (index) {
          final step = _statusSteps[index];
          final isCompleted = index <= currentStep;
          final isCurrent = index == currentStep;

          return _buildTimelineStep(
            icon: step['icon'],
            title: step['title'],
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isLast: index == _statusSteps.length - 1,
          );
        }),
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    final color = isCompleted ? Colors.green : Colors.grey[600];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.withOpacity(0.2) : Colors.grey[800],
                shape: BoxShape.circle,
                border: isCurrent ? Border.all(color: Colors.green, width: 2) : null,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted ? Colors.green : Colors.grey[700],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isCompleted ? Colors.white : Colors.grey[500],
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isCurrent)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Текущий статус',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ),
                SizedBox(height: isLast ? 0 : 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCancelledStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel, color: Colors.red, size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Заказ отменён',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Свяжитесь с продавцом для уточнения деталей',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    final isInTransit = _order['status'] == 'in_transit' || 
                        _order['status'] == 'picked_up' ||
                        _order['status'] == 'delivering';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Доставка',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, color: buttonColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _order['delivery_address'] ?? 'Адрес не указан',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Live tracking button (shown when courier is delivering)
          if (isInTransit || _order['courier_id'] != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => DeliveryMapScreen(order: _order)),
                icon: const Icon(Icons.location_searching),
                label: const Text('Отслеживать курьера на карте'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openInMaps,
              icon: const Icon(Icons.map),
              label: const Text('Открыть в навигаторе'),
              style: OutlinedButton.styleFrom(
                foregroundColor: buttonColor,
                side: BorderSide(color: buttonColor ?? Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    final items = _order['items'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.inventory_2, color: Colors.grey[600], size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['product_name'] ?? 'Товар',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        '${item['quantity']} x ${_formatPrice(item['price'])} сум',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_formatPrice((item['quantity'] ?? 1) * (item['price'] ?? 0))} сум',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactButtons() {
    return Column(
      children: [
        // Chat buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  if (_order['seller_id'] != null) {
                    Get.to(() => ChatScreen(
                      userId: _order['seller_id'],
                      userName: _order['seller_name'] ?? 'Продавец',
                    ));
                  }
                },
                icon: const Icon(Icons.chat),
                label: const Text('Чат с продавцом'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  if (_order['courier_id'] != null) {
                    Get.to(() => ChatScreen(
                      userId: _order['courier_id'],
                      userName: _order['courier_name'] ?? 'Курьер',
                    ));
                  } else {
                    Get.snackbar(
                      'Курьер не назначен',
                      'Курьер ещё не принял заказ',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                icon: const Icon(Icons.chat),
                label: const Text('Чат с курьером'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Call buttons row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _callPhone(_order['seller_phone'] ?? '+998901234567'),
                icon: const Icon(Icons.phone),
                label: const Text('Позвонить продавцу'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_order['courier_id'] != null) {
                    _callPhone(_order['courier_phone'] ?? '+998901234568');
                  } else {
                    Get.snackbar(
                      'Курьер не назначен',
                      'Курьер ещё не принял заказ',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                icon: const Icon(Icons.phone),
                label: const Text('Позвонить курьеру'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _order['courier_id'] != null ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _callPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        Get.snackbar(
          'Ошибка',
          'Не удалось открыть приложение для звонков',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось позвонить: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _refreshOrder() async {
    await _controller.fetchOrders();
    final updatedOrder = _controller.orders.firstWhereOrNull(
      (o) => o['id'] == _order['id'],
    );
    if (updatedOrder != null) {
      setState(() => _order = updatedOrder);
    }
  }

  Future<void> _openInMaps() async {
    final lat = _order['delivery_latitude'];
    final lng = _order['delivery_longitude'];
    
    if (lat == null || lng == null) {
      Get.snackbar(
        'Ошибка',
        'Координаты не указаны',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Try Google Maps first, then Yandex Maps
    final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    final yandexMapsUrl = 'yandexmaps://maps.yandex.ru/?pt=$lng,$lat&z=17';
    
    try {
      if (await canLaunchUrl(Uri.parse(yandexMapsUrl))) {
        await launchUrl(Uri.parse(yandexMapsUrl));
      } else if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось открыть навигатор',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final numPrice = (price as num).toDouble();
    if (numPrice >= 1000000) {
      return '${(numPrice / 1000000).toStringAsFixed(1)}M';
    } else if (numPrice >= 1000) {
      return '${(numPrice / 1000).toStringAsFixed(0)}K';
    }
    return numPrice.toStringAsFixed(0);
  }

  String _getStatusText(String? status) {
    final statuses = {
      'created': 'Создан',
      'accepted': 'Принят',
      'ready': 'Готов',
      'picked_up': 'Забран',
      'in_transit': 'В пути',
      'delivered': 'Доставлен',
      'completed': 'Завершён',
      'cancelled': 'Отменён',
    };
    return statuses[status] ?? status ?? 'Неизвестно';
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'created':
        return Colors.blue;
      case 'accepted':
      case 'ready':
        return Colors.orange;
      case 'picked_up':
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
