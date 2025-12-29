import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gogomarket/constants.dart';
import 'package:gogomarket/controllers/cart_controller.dart';
import 'package:gogomarket/controllers/marketplace_controller.dart';
import 'package:gogomarket/views/screens/buyer/order_success_screen.dart';
import 'package:gogomarket/views/screens/buyer/payment_screen.dart';
import 'package:gogomarket/views/screens/common/location_picker_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String sellerId;

  const CheckoutScreen({Key? key, required this.sellerId}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final MarketplaceController _marketplaceController = Get.find<MarketplaceController>();
  late CartController _cartController;
  
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  
  // Default coordinates for Tashkent
  double _latitude = 41.2995;
  double _longitude = 69.2401;
  
  // Delivery tariff options
  String _selectedTariff = 'standard'; // standard, express
  static const double _standardDeliveryFee = 15000; // 15,000 сум
  static const double _expressDeliveryFee = 30000; // 30,000 сум
  static const double _freeDeliveryThreshold = 500000; // Free delivery over 500K сум
  
  // Payment method
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _cartController = Get.find<CartController>();
    
    // Pre-fill address from user profile if available
    final user = _marketplaceController.currentUser.value;
    if (user != null && user['address'] != null) {
      _addressController.text = user['address'];
      if (user['latitude'] != null) _latitude = user['latitude'];
      if (user['longitude'] != null) _longitude = user['longitude'];
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _cartController.getItemsBySeller(widget.sellerId);
    final total = _cartController.getTotalBySeller(widget.sellerId);
    final sellerName = items.isNotEmpty ? items.first.sellerName : 'Продавец';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text(
          'Оформление заказа',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seller info
              _buildSellerCard(sellerName),
              const SizedBox(height: 24),

              // Order items
              const Text(
                'Товары',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildOrderItems(items),
              const SizedBox(height: 24),

              // Delivery address
              const Text(
                'Адрес доставки',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildAddressField(),
              const SizedBox(height: 16),
              _buildLocationInfo(),
              const SizedBox(height: 24),

              // Notes
              const Text(
                'Комментарий к заказу',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildNotesField(),
              const SizedBox(height: 24),

              // Delivery tariff
              const Text(
                'Тариф доставки',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildDeliveryTariff(total),
              const SizedBox(height: 24),

              // Payment method
              const Text(
                'Способ оплаты',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildPaymentMethod(),
              const SizedBox(height: 24),

              // Order summary
              _buildOrderSummary(items, total),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(total),
    );
  }

  Widget _buildSellerCard(String sellerName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.store, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sellerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Продавец',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(List<CartItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.map((item) => _buildOrderItem(item)).toList(),
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
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
            child: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.inventory_2,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  )
                : Icon(
                    Icons.inventory_2,
                    color: Colors.grey[600],
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.quantity} x ${_formatPrice(item.price)} сум',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatPrice(item.total)} сум',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField() {
    return Column(
      children: [
        TextFormField(
          controller: _addressController,
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'enter_full_address'.tr,
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.location_on, color: buttonColor),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'enter_address'.tr;
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openLocationPicker,
            icon: Icon(Icons.map, color: primaryColor),
            label: Text(
              'select_location'.tr,
              style: TextStyle(color: primaryColor),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primaryColor.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await Get.to<Map<String, dynamic>>(() => LocationPickerScreen(
      initialAddress: _addressController.text,
      initialLatitude: _latitude,
      initialLongitude: _longitude,
    ));
    
    if (result != null) {
      setState(() {
        _addressController.text = result['address'] ?? '';
        _latitude = result['latitude'] ?? _latitude;
        _longitude = result['longitude'] ?? _longitude;
      });
    }
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[500], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Курьер увидит ваш адрес и сможет открыть навигатор для маршрута',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      style: const TextStyle(color: Colors.white),
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Комментарий для курьера (необязательно)',
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Column(
      children: [
        _buildPaymentMethodTile(
          PaymentMethod.card,
          'Банковская карта',
          'Visa, Mastercard, Uzcard, Humo',
          Icons.credit_card,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodTile(
          PaymentMethod.click,
          'Click',
          'Оплата через Click',
          Icons.touch_app,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodTile(
          PaymentMethod.payme,
          'Payme',
          'Оплата через Payme',
          Icons.account_balance_wallet,
          Colors.cyan,
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodTile(
          PaymentMethod.cash,
          'Наличными',
          'Оплата при получении',
          Icons.money,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(
    PaymentMethod method,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: primaryColor)
            else
              Icon(Icons.circle_outlined, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTariff(double itemsTotal) {
    final isFreeDelivery = itemsTotal >= _freeDeliveryThreshold;
    
    return Column(
      children: [
        // Standard delivery
        GestureDetector(
          onTap: () => setState(() => _selectedTariff = 'standard'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedTariff == 'standard' ? primaryColor : Colors.grey[800]!,
                width: _selectedTariff == 'standard' ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_shipping, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Стандартная доставка',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '60-90 минут',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  isFreeDelivery ? 'Бесплатно' : '${_formatPrice(_standardDeliveryFee)} сум',
                  style: TextStyle(
                    color: isFreeDelivery ? Colors.green : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedTariff == 'standard')
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_circle, color: primaryColor),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Express delivery
        GestureDetector(
          onTap: () => setState(() => _selectedTariff = 'express'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedTariff == 'express' ? primaryColor : Colors.grey[800]!,
                width: _selectedTariff == 'express' ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.flash_on, color: primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Экспресс доставка',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '30-45 минут',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_formatPrice(_expressDeliveryFee)} сум',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedTariff == 'express')
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_circle, color: primaryColor),
                  ),
              ],
            ),
          ),
        ),
        
        // Free delivery info
        if (!isFreeDelivery)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Бесплатная доставка от ${_formatPrice(_freeDeliveryThreshold)} сум',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  double _getDeliveryFee(double itemsTotal) {
    if (itemsTotal >= _freeDeliveryThreshold && _selectedTariff == 'standard') {
      return 0;
    }
    return _selectedTariff == 'express' ? _expressDeliveryFee : _standardDeliveryFee;
  }

  Widget _buildOrderSummary(List<CartItem> items, double total) {
    final itemsTotal = total;
    final deliveryFee = _getDeliveryFee(itemsTotal);
    final grandTotal = itemsTotal + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Товары (${items.length})', '${_formatPrice(itemsTotal)} сум'),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Доставка (${_selectedTariff == 'express' ? 'экспресс' : 'стандарт'})',
            deliveryFee == 0 ? 'Бесплатно' : '${_formatPrice(deliveryFee)} сум',
            valueColor: deliveryFee == 0 ? Colors.green : null,
          ),
          const Divider(color: Colors.grey, height: 24),
          _buildSummaryRow(
            'Итого',
            '${_formatPrice(grandTotal)} сум',
            isBold: true,
            valueColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? Colors.white : Colors.grey[400],
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(double total) {
    final deliveryFee = _getDeliveryFee(total);
    final grandTotal = total + deliveryFee;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey[700],
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Заказать за ${_formatPrice(grandTotal)} сум',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final items = _cartController.getItemsBySeller(widget.sellerId);
      final orderItems = items.map((item) => item.toOrderItem()).toList();
      final total = _cartController.getTotalBySeller(widget.sellerId);
      final deliveryFee = _getDeliveryFee(total);
      final grandTotal = total + deliveryFee;

      // Create order first
      final order = await _marketplaceController.createOrder(
        sellerId: widget.sellerId,
        items: orderItems,
        deliveryAddress: _addressController.text,
        deliveryLatitude: _latitude,
        deliveryLongitude: _longitude,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        paymentMethod: _selectedPaymentMethod.name,
      );

      if (order != null) {
        // If payment method is not cash, navigate to payment screen
        if (_selectedPaymentMethod != PaymentMethod.cash) {
          final orderId = order['id']?.toString() ?? '0';
          Get.to(() => PaymentScreen(
            amount: grandTotal,
            orderId: orderId,
            onPaymentComplete: (success, transactionId) {
              if (success) {
                // Clear items from this seller
                _cartController.clearSellerItems(widget.sellerId);
                // Navigate to success screen
                Get.off(() => OrderSuccessScreen(order: order));
              }
            },
          ));
        } else {
          // Cash payment - go directly to success
          _cartController.clearSellerItems(widget.sellerId);
          Get.off(() => OrderSuccessScreen(order: order));
        }
      } else {
        Get.snackbar(
          'Ошибка',
          _marketplaceController.error.value.isNotEmpty 
              ? _marketplaceController.error.value 
              : 'Не удалось создать заказ',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }
}
