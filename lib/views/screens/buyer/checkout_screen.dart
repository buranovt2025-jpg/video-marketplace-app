import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/widgets/app_network_image.dart';
import 'package:tiktok_tutorial/views/screens/buyer/order_success_screen.dart';
import 'package:tiktok_tutorial/views/screens/common/location_picker_screen.dart';
import 'package:tiktok_tutorial/utils/money.dart';

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
    final sellerName = items.isNotEmpty ? items.first.sellerName : 'seller_fallback'.tr;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          'checkout'.tr,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              Text(
                'items_title'.trParams({'count': items.length.toString()}),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildOrderItems(items),
              const SizedBox(height: 24),

              // Delivery address
              Text(
                'delivery_address'.tr,
                style: const TextStyle(
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
              Text(
                'order_notes'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildNotesField(),
              const SizedBox(height: 24),

              // Delivery tariff
              Text(
                'delivery_tariff'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildDeliveryTariff(total),
              const SizedBox(height: 24),

              // Payment method
              Text(
                'payment_type'.tr,
                style: const TextStyle(
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
                  'seller'.tr,
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
                    child: AppNetworkImage(
                      url: item.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: Icon(Icons.inventory_2, color: Colors.grey[600], size: 20),
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
                  '${item.quantity} x ${_formatPrice(item.price)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatPrice(item.total),
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
              'courier_location_info'.tr,
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
        hintText: 'order_notes_hint_optional'.tr,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: buttonColor!, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: buttonColor!.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.money, color: buttonColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'cash_on_delivery'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'payment_on_delivery'.tr,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: buttonColor),
        ],
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
                      Text(
                        'standard_delivery'.tr,
                        style: const TextStyle(
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
                  isFreeDelivery ? 'free'.tr : _formatPrice(_standardDeliveryFee),
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
                      Text(
                        'express_delivery'.tr,
                        style: const TextStyle(
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
                  _formatPrice(_expressDeliveryFee),
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
                      'free_delivery_from'.trParams({'amount': _formatPrice(_freeDeliveryThreshold)}),
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
          _buildSummaryRow(
            'items_title'.trParams({'count': items.length.toString()}),
            _formatPrice(itemsTotal),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'delivery_summary'.trParams({
              'type': _selectedTariff == 'express' ? 'express_short'.tr : 'standard_short'.tr,
            }),
            deliveryFee == 0 ? 'free'.tr : _formatPrice(deliveryFee),
            valueColor: deliveryFee == 0 ? Colors.green : null,
          ),
          const Divider(color: Colors.grey, height: 24),
          _buildSummaryRow(
            'total'.tr,
            _formatPrice(grandTotal),
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
                    'place_order_for'.trParams({'amount': _formatPrice(grandTotal)}),
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

      final order = await _marketplaceController.createOrder(
        sellerId: widget.sellerId,
        items: orderItems,
        deliveryAddress: _addressController.text,
        deliveryLatitude: _latitude,
        deliveryLongitude: _longitude,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (order != null) {
        // Clear items from this seller
        _cartController.clearSellerItems(widget.sellerId);

        // Сначала снимаем loading (чтобы не оставаться в "зависшем" состоянии),
        // затем уходим на success и чистим стек, чтобы не вернуться на checkout с loader'ом.
        if (mounted) setState(() => _isLoading = false);
        Get.offAll(() => OrderSuccessScreen(order: order));
      } else {
        Get.snackbar(
          'error'.tr,
          _marketplaceController.error.value.isNotEmpty 
              ? _marketplaceController.error.value 
              : 'create_order_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatPrice(double price) {
    return formatShortMoneyWithCurrency(price);
  }
}
