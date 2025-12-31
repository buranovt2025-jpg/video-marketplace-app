import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/views/screens/buyer/order_tracking_screen.dart';
import 'package:tiktok_tutorial/views/screens/marketplace_home_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderSuccessScreen({Key? key, required this.order}) : super(key: key);

  String _shortId(dynamic id) {
    final s = id?.toString() ?? '';
    if (s.isEmpty) return 'N/A';
    return s.length > 8 ? s.substring(0, 8) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
              const SizedBox(height: 32),

              // Success message
              Text(
                'order_placed'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'order_number_label'.trParams({'id': _shortId(order['id'])}),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),

              // Order info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.attach_money,
                      'order_total'.tr,
                      "${_formatPrice(order['total_amount'])} ${'currency_sum'.tr}",
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.location_on,
                      'address'.tr,
                      order['delivery_address'] ?? 'address_not_specified'.tr,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.payment,
                      'payment'.tr,
                      'cash_to_courier'.tr,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.local_shipping,
                      'order_status_title'.tr,
                      _getStatusText(order['status']),
                      valueColor: _getStatusColor(order['status']),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: buttonColor!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: buttonColor!.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: buttonColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'seller_got_order_info'.tr,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.off(() => OrderTrackingScreen(order: order)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('track_order'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.offAll(() => const MarketplaceHomeScreen()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('to_home'.tr, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.grey[400], size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
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
    final key = switch (status) {
      'created' => 'status_created',
      'accepted' => 'status_accepted',
      'ready' => 'status_ready',
      'picked_up' => 'status_picked_up',
      'in_transit' => 'status_in_transit',
      'delivered' => 'status_delivered',
      'completed' => 'status_completed',
      'cancelled' => 'status_cancelled',
      _ => null,
    };
    return key == null ? (status?.toString() ?? '-') : key.tr;
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
