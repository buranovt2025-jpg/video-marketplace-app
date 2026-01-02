import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/ui/app_ui.dart';
import 'package:tiktok_tutorial/views/screens/buyer/order_tracking_screen.dart';
import 'package:tiktok_tutorial/views/screens/marketplace_home_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderSuccessScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: AppUI.pagePadding,
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
              Text('Заказ оформлен!', style: AppUI.h1.copyWith(fontSize: 26)),
              const SizedBox(height: 12),
              Text(
                'Номер заказа: ${order['id']?.substring(0, 8) ?? 'N/A'}',
                style: AppUI.muted.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Order info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.attach_money,
                      'Сумма',
                      '${_formatPrice(order['total_amount'])} сум',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.location_on,
                      'Адрес',
                      order['delivery_address'] ?? 'Не указан',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.payment,
                      'Оплата',
                      'Наличными курьеру',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.local_shipping,
                      'Статус',
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
                  color: primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppUI.radiusL),
                  border: Border.all(color: primaryColor.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Продавец получил ваш заказ. Курьер скоро заберёт его и доставит вам.',
                        style: AppUI.body.copyWith(color: Colors.white.withOpacity(0.85)),
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
                  style: AppUI.primaryButton(),
                  child: const Text('Отследить заказ'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.offAll(() => const MarketplaceHomeScreen()),
                  style: AppUI.outlineButton(),
                  child: const Text(
                    'На главную',
                    style: TextStyle(fontSize: 16),
                  ),
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
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppUI.radiusM),
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
                style: AppUI.muted.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
    final statuses = {
      'created': 'Создан',
      'accepted': 'Принят продавцом',
      'ready': 'Готов к отправке',
      'picked_up': 'Забран курьером',
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
