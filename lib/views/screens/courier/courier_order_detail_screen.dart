import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/services/location_service.dart';
import 'package:tiktok_tutorial/services/notification_service.dart';
import 'package:tiktok_tutorial/views/screens/chat/chat_screen.dart';
import 'package:tiktok_tutorial/views/screens/common/qr_code_screen.dart';
import 'package:tiktok_tutorial/views/screens/common/qr_scanner_export.dart';
import 'package:tiktok_tutorial/views/widgets/app_network_image.dart';
import 'package:tiktok_tutorial/utils/formatters.dart';
import 'package:tiktok_tutorial/utils/money.dart';

class CourierOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const CourierOrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<CourierOrderDetailScreen> createState() => _CourierOrderDetailScreenState();
}

class _CourierOrderDetailScreenState extends State<CourierOrderDetailScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  final LocationService _locationService = Get.find<LocationService>();
  late Map<String, dynamic> _order;
  bool _isUpdating = false;
  String? _distanceToSeller;
  String? _distanceToBuyer;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    _calculateDistances();
  }
  
  Future<void> _calculateDistances() async {
    final currentPosition = await _locationService.getCurrentLocation();
    if (currentPosition == null) return;
    
    // Calculate distance to seller
    final sellerLat = tryNum(_order['seller_latitude'])?.toDouble();
    final sellerLng = tryNum(_order['seller_longitude'])?.toDouble();
    if (sellerLat != null && sellerLng != null) {
      final distance = _locationService.calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        sellerLat,
        sellerLng,
      );
      setState(() {
        _distanceToSeller = _locationService.formatDistance(distance);
      });
    }
    
    // Calculate distance to buyer
    final buyerLat = tryNum(_order['delivery_latitude'])?.toDouble();
    final buyerLng = tryNum(_order['delivery_longitude'])?.toDouble();
    if (buyerLat != null && buyerLng != null) {
      final distance = _locationService.calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        buyerLat,
        buyerLng,
      );
      setState(() {
        _distanceToBuyer = _locationService.formatDistance(distance);
      });
    }
  }

  Future<void> _openNavigation(double? lat, double? lng, String address) async {
    if (lat == null || lng == null) {
      Get.snackbar(
        'error'.tr,
        'coordinates_missing'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
      return;
    }

    await _locationService.openNavigation(
      destinationLat: lat,
      destinationLng: lng,
      destinationName: address,
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    
    final success = await _controller.updateOrderStatus(_order['id'], newStatus);
    
    if (success) {
      setState(() {
        _order['status'] = newStatus;
      });
      
      String message = '';
      switch (newStatus) {
        case 'picked_up':
          message = 'picked_up_message'.tr;
          break;
        case 'in_transit':
          message = 'in_transit_message'.tr;
          break;
        case 'delivered':
          message = 'delivered_message'.tr;
          break;
      }
      
      Get.snackbar(
        'status_updated'.tr,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        'status_update_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    }
    
    setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    final status = _order['status'] ?? 'created';
    final items = _order['items'] as List? ?? [];
    final totalAmount = _order['total_amount'] ?? 0.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'order_number_short'.trParams({
            'id': (_order['id']?.toString() ?? '').substring(0, 8),
          }),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              await _controller.fetchOrders();
              final updated = _controller.orders.firstWhereOrNull(
                (o) => o['id'] == _order['id']
              );
              if (updated != null) {
                setState(() => _order = Map<String, dynamic>.from(updated));
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            _buildStatusCard(status),
            const SizedBox(height: 16),

            // Pickup location (Seller)
            _buildLocationCard(
              title: 'pickup_from_seller_title'.tr,
              icon: Icons.store,
              iconColor: Colors.orange,
              address: _order['seller_address'] ?? 'address_not_specified'.tr,
              name: _order['seller_name'] ?? 'seller'.tr,
              phone: _order['seller_phone'],
              latitude: tryNum(_order['seller_latitude'])?.toDouble(),
              longitude: tryNum(_order['seller_longitude'])?.toDouble(),
              userId: _order['seller_id'],
              showNavigation: status == 'picked_up' || status == 'ready',
              distance: _distanceToSeller,
            ),
            const SizedBox(height: 12),

            // Delivery location (Buyer)
            _buildLocationCard(
              title: 'deliver_to_buyer_title'.tr,
              icon: Icons.location_on,
              iconColor: accentColor,
              address: _order['delivery_address'] ?? 'address_not_specified'.tr,
              name: _order['buyer_name'] ?? 'buyer'.tr,
              phone: _order['buyer_phone'],
              latitude: tryNum(_order['delivery_latitude'])?.toDouble(),
              longitude: tryNum(_order['delivery_longitude'])?.toDouble(),
              userId: _order['buyer_id'],
              showNavigation: status == 'in_transit',
              distance: _distanceToBuyer,
            ),
            const SizedBox(height: 16),

            // Order items
            _buildItemsCard(items),
            const SizedBox(height: 16),

            // Payment info
            _buildPaymentCard(totalAmount),
            const SizedBox(height: 16),

            // Notes
            if (_order['notes'] != null && _order['notes'].toString().isNotEmpty) ...[
              _buildNotesCard(_order['notes']),
              const SizedBox(height: 16),
            ],

            // Action buttons
            _buildActionButtons(status),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    final statusColors = {
      'created': Colors.grey,
      'accepted': accentColor,
      'ready': primaryColor,
      'picked_up': primaryColor,
      'in_transit': accentColor,
      'delivered': Colors.green,
      'completed': Colors.green,
      'cancelled': Colors.grey,
    };

    final statusLabels = {
      'created': 'status_created'.tr,
      'accepted': 'status_accepted_by_seller'.tr,
      'ready': 'status_ready'.tr,
      'picked_up': 'status_picked_up_by_courier'.tr,
      'in_transit': 'status_in_transit'.tr,
      'delivered': 'status_delivered'.tr,
      'completed': 'status_completed'.tr,
      'cancelled': 'status_cancelled'.tr,
    };

    final statusInstructions = {
      'ready': 'status_ready_pickup_hint'.tr,
      'picked_up': 'status_picked_up_hint'.tr,
      'in_transit': 'status_in_transit_hint'.tr,
      'delivered': 'status_delivered_hint'.tr,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColors[status]?.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColors[status]?.withOpacity(0.5) ?? Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status == 'delivered' || status == 'completed' 
                  ? Icons.check_circle 
                  : Icons.local_shipping,
                color: statusColors[status],
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'order_status'.tr,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    Text(
                      statusLabels[status] ?? status,
                      style: TextStyle(
                        color: statusColors[status],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (statusInstructions[status] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[400], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusInstructions[status]!,
                      style: TextStyle(color: Colors.grey[300], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String address,
    required String name,
    String? phone,
    double? latitude,
    double? longitude,
    String? userId,
    bool showNavigation = false,
    String? distance,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: showNavigation 
          ? Border.all(color: iconColor.withOpacity(0.5), width: 2)
          : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (distance != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.near_me, color: Colors.grey[400], size: 12),
                      const SizedBox(width: 4),
                      Text(
                        distance,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (showNavigation) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'now_badge'.tr,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          
          // Name
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          
          // Address
          Text(
            address,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          
          // Phone
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phone,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              // Navigate button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openNavigation(latitude, longitude, address),
                  icon: Icon(Icons.navigation, color: iconColor, size: 18),
                  label: Text(
                    'navigation'.tr,
                    style: TextStyle(color: iconColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: iconColor.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Chat button
              if (userId != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Get.to(() => ChatScreen(
                      userId: userId.toString(),
                      userName: name,
                    )),
                    icon: Icon(Icons.chat_bubble_outline, color: Colors.grey[400], size: 18),
                    label: Text(
                      'chat'.tr,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[700]!),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(List items) {
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
            children: [
              Icon(Icons.inventory_2_outlined, color: Colors.grey[400], size: 20),
              const SizedBox(width: 8),
              Text(
                'items_title'.trParams({'count': items.length.toString()}),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: item['image_url'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppNetworkImage(
                          url: item['image_url']?.toString(),
                          fit: BoxFit.cover,
                          errorWidget: Icon(Icons.inventory_2, color: Colors.grey[600], size: 20),
                        ),
                      )
                    : Icon(Icons.inventory_2, color: Colors.grey[600], size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'product'.tr,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        '${item['quantity'] ?? 1} ${'pcs'.tr} x ${formatMoneyWithCurrency(item['price'])}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.payments, color: Colors.green[400], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'cash_to_collect'.tr,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                Text(
                  formatMoneyWithCurrency(totalAmount),
                  style: TextStyle(
                    color: Colors.green[400],
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.money, color: Colors.green[400], size: 32),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String notes) {
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
            children: [
              Icon(Icons.note_outlined, color: Colors.grey[400], size: 20),
              const SizedBox(width: 8),
              Text(
                'note'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    if (status == 'delivered' || status == 'completed' || status == 'cancelled') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (status == 'ready') ...[
          // Scan QR from seller to confirm pickup
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUpdating ? null : _scanPickupQR,
              icon: _isUpdating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.qr_code_scanner),
              label: Text('scan_qr'.tr + ' - ' + 'confirm_pickup'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        
        if (status == 'picked_up') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUpdating ? null : () => _updateStatus('in_transit'),
              icon: _isUpdating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.directions_bike),
              label: Text('in_transit_to_buyer'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        
        if (status == 'in_transit') ...[
          // Show QR for buyer to scan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showDeliveryQR,
              icon: const Icon(Icons.qr_code),
              label: Text('show_qr'.tr + ' - ' + 'confirm_delivery'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Manual delivery confirmation
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUpdating ? null : () => _updateStatus('delivered'),
              icon: _isUpdating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                  )
                : const Icon(Icons.check_circle, color: Colors.green),
              label: Text(
                'confirm_without_qr'.tr,
                style: TextStyle(color: Colors.green[400]),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.green.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _scanPickupQR() {
    Get.to(() => QRScannerScreen(
      expectedType: 'pickup',
      expectedOrderId: _order['id'],
      onScanned: (orderId, type) {
        _updateStatus('picked_up');
        Get.snackbar(
          'item_received'.tr,
          'item_received_from_seller'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    ));
  }

  void _showDeliveryQR() {
    Get.to(() => QRCodeScreen(
      orderId: _order['id'] ?? '',
      type: 'delivery',
      title: 'show_qr'.tr,
      subtitle: 'buyer_should_scan_qr'.tr,
    ));
  }
}
