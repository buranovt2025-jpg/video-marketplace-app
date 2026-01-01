import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/widgets/app_network_image.dart';
import 'package:tiktok_tutorial/views/screens/buyer/order_success_screen.dart';
import 'package:tiktok_tutorial/views/screens/common/location_picker_screen.dart';
import 'package:tiktok_tutorial/utils/money.dart';
import 'package:tiktok_tutorial/views/screens/auth/marketplace_login_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String sellerId;

  const CheckoutScreen({Key? key, required this.sellerId}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final MarketplaceController _marketplaceController = Get.find<MarketplaceController>();
  late CartController _cartController;
  
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _promoController = TextEditingController();
  String? _promoCode;
  
  bool _isLoading = false;
  
  // Default coordinates for Tashkent
  double _latitude = 41.2995;
  double _longitude = 69.2401;
  
  // Delivery tariff options
  String _selectedTariff = 'standard'; // standard, express
  static const double _standardDeliveryFee = 15000; // 15,000 UZS
  static const double _expressDeliveryFee = 30000; // 30,000 UZS
  static const double _freeDeliveryThreshold = 500000; // Free delivery over 500,000 UZS

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
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_marketplaceController.isLoggedIn) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          title: Text('checkout'.tr, style: const TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  'login_required'.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'login_to_continue'.tr,
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.to(() => const MarketplaceLoginScreen()),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  child: Text('login'.tr),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final items = _cartController.getItemsBySeller(widget.sellerId);
    final total = _cartController.getTotalBySeller(widget.sellerId);
    final sellerName = items.isNotEmpty ? items.first.sellerName : 'seller_fallback'.tr;

    if (items.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          title: Text('checkout'.tr, style: const TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'cart_empty'.tr,
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('delivery_address'.tr),
            const SizedBox(height: 10),
            _buildDeliveryLocationCard(),
            const SizedBox(height: 18),

            _sectionTitle('order_items'.tr),
            const SizedBox(height: 10),
            _buildOrderInfoCard(items),
            const SizedBox(height: 18),

            _buildPromoRow(),
            const SizedBox(height: 18),

            _buildTotalsCard(itemsTotal: total),
            const SizedBox(height: 18),

            _sectionTitle('payment_type'.tr),
            const SizedBox(height: 10),
            _buildPaymentMethodCard(),
            const SizedBox(height: 18),

            _sectionTitle('delivery_tariff'.tr),
            const SizedBox(height: 10),
            _buildDeliveryTariff(total),
            const SizedBox(height: 18),

            _sectionTitle('order_notes'.tr),
            const SizedBox(height: 10),
            _buildNotesCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(total),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _cardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _buildDeliveryLocationCard() {
    final address = _addressController.text.trim();
    return _cardContainer(
      child: InkWell(
        onTap: () async {
          await _editDeliveryLocation();
          if (mounted) setState(() {});
        },
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.location_on, color: primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.isEmpty ? 'enter_full_address'.tr : address,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'courier_location_info'.tr,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Future<void> _editDeliveryLocation() async {
    await Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text('delivery_address'.tr, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'enter_full_address'.tr,
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _openLocationPicker();
                    if (Get.isBottomSheetOpen == true) {
                      // keep open; user can close when done
                    }
                  },
                  icon: const Icon(Icons.map, color: primaryColor),
                  label: Text('select_location'.tr, style: const TextStyle(color: primaryColor)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor.withOpacity(0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('save'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildOrderInfoCard(List<CartItem> items) {
    return _cardContainer(
      child: Column(
        children: [
          for (final item in items) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.productName} x${item.quantity}',
                    style: const TextStyle(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(_formatPrice(item.total), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildPromoRow() {
    return _cardContainer(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promoController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'enter_promo_code'.tr,
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final v = _promoController.text.trim();
              if (v.isEmpty) return;
              setState(() => _promoCode = v);
              Get.snackbar('promo_code'.tr, v, snackPosition: SnackPosition.BOTTOM);
            },
            child: Text('add'.tr, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard({required double itemsTotal}) {
    final deliveryFee = _getDeliveryFee(itemsTotal);
    final shippingText = deliveryFee == 0 ? 'free'.tr : _formatPrice(deliveryFee);
    final total = itemsTotal + deliveryFee;
    return _cardContainer(
      child: Column(
        children: [
          _rowKV('sub_total'.tr, _formatPrice(itemsTotal)),
          const SizedBox(height: 10),
          _rowKV('shipping'.tr, shippingText, valueColor: deliveryFee == 0 ? primaryColor : Colors.white),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          _rowKV('total'.tr, _formatPrice(total), isBold: true),
          if (_promoCode != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${'promo_code'.tr}: $_promoCode',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rowKV(String k, String v, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        Text(
          v,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard() {
    return _cardContainer(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.money, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'cash_on_delivery'.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('payment_on_delivery'.tr, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: primaryColor),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return _cardContainer(
      child: TextField(
        controller: _notesController,
        style: const TextStyle(color: Colors.white),
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'order_notes_hint_optional'.tr,
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
        ),
      ),
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

  // Payment card is rendered by `_buildPaymentMethodCard()` to match the new checkout layout.

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
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_shipping, color: accentColor),
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
                        'delivery_time_standard'.tr,
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
                        'delivery_time_express'.tr,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _placeOrder(grandTotal: grandTotal),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                    '${'pay_now'.tr} • ${_formatPrice(grandTotal)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder({required double grandTotal}) async {
    final addr = _addressController.text.trim();
    if (addr.isEmpty) {
      Get.snackbar('delivery_address'.tr, 'enter_address'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final items = _cartController.getItemsBySeller(widget.sellerId);
      final orderItems = items.map((item) => item.toOrderItem()).toList();

      final order = await _marketplaceController.createOrder(
        sellerId: widget.sellerId,
        items: orderItems,
        deliveryAddress: addr,
        deliveryLatitude: _latitude,
        deliveryLongitude: _longitude,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (order != null) {
        // Clear items from this seller
        _cartController.clearSellerItems(widget.sellerId);

        // First, stop loading (so we don't stay in a "stuck" state),
        // then navigate to success and clear the stack to avoid returning to checkout with a loader.
        if (mounted) setState(() => _isLoading = false);
        Get.offAll(() => OrderSuccessScreen(order: order));
      } else {
        Get.snackbar(
          'error'.tr,
          _marketplaceController.error.value.isNotEmpty 
              ? _marketplaceController.error.value 
              : 'create_order_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
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
