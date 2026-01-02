import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../config/theme.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../utils/currency_formatter.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    await context.read<OrderProvider>().fetchOrderById(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final order = orderProvider.selectedOrder;

          if (orderProvider.isLoading || order == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadOrder,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(order),
                  const SizedBox(height: 16),
                  _buildProductCard(order),
                  const SizedBox(height: 16),
                  _buildShippingCard(order),
                  const SizedBox(height: 16),
                  _buildPaymentCard(order),
                  if (_shouldShowQrCode(order, user)) ...[
                    const SizedBox(height: 16),
                    _buildQrCodeCard(order, user),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      bottomSheet: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final order = orderProvider.selectedOrder;
          if (order == null) return const SizedBox.shrink();

          return _buildActionButtons(order, user);
        },
      ),
    );
  }

  Widget _buildStatusCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Placed on ${_formatDate(order.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = AppColors.warning;
        break;
      case OrderStatus.confirmed:
      case OrderStatus.pickedUp:
      case OrderStatus.inTransit:
        color = AppColors.info;
        break;
      case OrderStatus.delivered:
        color = AppColors.success;
        break;
      case OrderStatus.cancelled:
      case OrderStatus.disputed:
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProductCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: order.product?.images.isNotEmpty == true
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            order.product!.images.first,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image, color: AppColors.grey400),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.product?.title ?? 'Product',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qty: ${order.quantity}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(order.unitPrice),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shipping',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on_outlined, order.shippingAddress),
            _buildInfoRow(Icons.location_city_outlined, order.shippingCity),
            _buildInfoRow(Icons.phone_outlined, order.shippingPhone),
            if (order.buyerNote != null && order.buyerNote!.isNotEmpty)
              _buildInfoRow(Icons.note_outlined, order.buyerNote!),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildPaymentRow('Subtotal', CurrencyFormatter.format(order.unitPrice * order.quantity)),
            _buildPaymentRow('Delivery Fee', CurrencyFormatter.format(order.courierFee)),
            const Divider(),
            _buildPaymentRow(
              'Total',
              CurrencyFormatter.format(order.totalAmount),
              isTotal: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getPaymentIcon(order.paymentMethod),
                  size: 20,
                  color: AppColors.grey600,
                ),
                const SizedBox(width: 8),
                Text(
                  order.paymentMethod.name.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                _buildPaymentStatusChip(order.paymentStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodeCard(Order order, User? user) {
    String? qrData;
    String title;

    if (user?.role == UserRole.seller && order.sellerQrCode != null) {
      qrData = order.sellerQrCode;
      title = 'Show this QR to Courier';
    } else if (user?.role == UserRole.buyer && order.courierQrCode != null) {
      qrData = order.courierQrCode;
      title = 'Show this QR to Courier';
    } else {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: qrData!,
              version: QrVersions.auto,
              size: 200,
            ),
            if (order.deliveryCode != null) ...[
              const SizedBox(height: 16),
              Text(
                'Or use code: ${order.deliveryCode}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Order order, User? user) {
    final List<Widget> buttons = [];

    if (user?.role == UserRole.seller && order.status == OrderStatus.pending) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _confirmOrder(order.id),
            child: const Text('Confirm Order'),
          ),
        ),
      );
    }

    if (user?.role == UserRole.courier) {
      if (order.status == OrderStatus.confirmed) {
        buttons.add(
          Expanded(
            child: ElevatedButton(
              onPressed: () => _scanPickupQr(order.id),
              child: const Text('Scan Pickup QR'),
            ),
          ),
        );
      } else if (order.status == OrderStatus.pickedUp || order.status == OrderStatus.inTransit) {
        buttons.add(
          Expanded(
            child: ElevatedButton(
              onPressed: () => _confirmDelivery(order.id),
              child: const Text('Confirm Delivery'),
            ),
          ),
        );
      }
    }

    if (order.canCancel && (user?.role == UserRole.buyer || user?.role == UserRole.seller)) {
      buttons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: () => _cancelOrder(order.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            child: const Text('Cancel'),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: buttons.map((button) {
            final index = buttons.indexOf(button);
            if (index > 0) {
              return Expanded(
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(child: button),
                  ],
                ),
              );
            }
            return button;
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.grey600),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? Theme.of(context).textTheme.titleSmall
                : Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: isTotal
                ? Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  )
                : Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusChip(PaymentStatus status) {
    Color color;
    switch (status) {
      case PaymentStatus.pending:
        color = AppColors.warning;
        break;
      case PaymentStatus.held:
        color = AppColors.info;
        break;
      case PaymentStatus.completed:
        color = AppColors.success;
        break;
      case PaymentStatus.refunded:
      case PaymentStatus.failed:
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.payme:
      case PaymentMethod.click:
        return Icons.payment;
    }
  }

  bool _shouldShowQrCode(Order order, User? user) {
    if (user?.role == UserRole.seller && order.status == OrderStatus.confirmed) {
      return true;
    }
    if (user?.role == UserRole.buyer && 
        (order.status == OrderStatus.pickedUp || order.status == OrderStatus.inTransit)) {
      return true;
    }
    return false;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _confirmOrder(String orderId) async {
    final success = await context.read<OrderProvider>().confirmOrder(orderId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order confirmed!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _scanPickupQr(String orderId) async {
    Navigator.pushNamed(
      context,
      '/qr-scanner',
      arguments: {'orderId': orderId, 'scanType': 'pickup'},
    );
  }

  Future<void> _confirmDelivery(String orderId) async {
    Navigator.pushNamed(
      context,
      '/qr-scanner',
      arguments: {'orderId': orderId, 'scanType': 'delivery'},
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _CancelOrderDialog(),
    );

    if (reason != null && mounted) {
      final success = await context.read<OrderProvider>().cancelOrder(orderId, reason);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }
}

class _CancelOrderDialog extends StatefulWidget {
  @override
  State<_CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<_CancelOrderDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Order'),
      content: TextField(
        controller: _reasonController,
        decoration: const InputDecoration(
          labelText: 'Reason for cancellation',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_reasonController.text.isNotEmpty) {
              Navigator.pop(context, _reasonController.text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: const Text('Cancel Order'),
        ),
      ],
    );
  }
}
