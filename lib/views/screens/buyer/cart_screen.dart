import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/widgets/app_network_image.dart';
import 'package:tiktok_tutorial/views/screens/buyer/checkout_screen.dart';
import 'package:tiktok_tutorial/views/screens/auth/marketplace_login_screen.dart';
import 'package:tiktok_tutorial/utils/money.dart';

class CartScreen extends StatefulWidget {
  final bool embedded;
  const CartScreen({Key? key, this.embedded = false}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late CartController _cartController;
  final MarketplaceController _marketplaceController = Get.find<MarketplaceController>();
  final _promoController = TextEditingController();
  String? _promoCode;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }
    _cartController = Get.find<CartController>();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          'cart'.tr,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
        actions: [
          Obx(() => _cartController.items.isNotEmpty
              ? TextButton(
                  onPressed: _showClearCartDialog,
                  child: Text(
                    'clear'.tr,
                    style: TextStyle(color: Colors.red[400]),
                  ),
                )
              : const SizedBox()),
        ],
      ),
      body: Obx(() {
        if (_cartController.isEmpty) {
          return _buildEmptyCart();
        }
        return _buildCartContentV2();
      }),
      bottomNavigationBar: Obx(() {
        if (_cartController.isEmpty) {
          return const SizedBox();
        }
        return _buildBottomBarV2();
      }),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'cart_empty'.tr,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'add_from_catalog'.tr,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          if (!widget.embedded)
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text('to_shopping'.tr),
            ),
        ],
      ),
    );
  }

  Widget _buildCartContentV2() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      children: [
        ..._cartController.items.map(_buildCartItemV2),
        const SizedBox(height: 18),
        _buildPromoRow(),
        const SizedBox(height: 18),
        _buildTotalsCard(),
      ],
    );
  }

  Widget _buildCartItemV2(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 70,
              height: 70,
              child: item.imageUrl != null
                  ? AppNetworkImage(
                      url: item.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: Colors.grey[850],
                        child: Icon(Icons.inventory_2, color: Colors.grey[600]),
                      ),
                    )
                  : Container(
                      color: Colors.grey[850],
                      child: Icon(Icons.inventory_2, color: Colors.grey[600]),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _formatPrice(item.price),
                  style: TextStyle(color: Colors.grey[300], fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _qtyButton(icon: Icons.remove, onTap: () => _cartController.decrementQuantity(item.productId)),
                    Container(
                      width: 44,
                      alignment: Alignment.center,
                      child: Text(
                        item.quantity.toString().padLeft(2, '0'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _qtyButton(icon: Icons.add, onTap: () => _cartController.incrementQuantity(item.productId)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              IconButton(
                onPressed: () => _showDeleteItemDialog(item),
                icon: Icon(Icons.delete_outline, color: Colors.red[400]),
              ),
              Text(
                _formatPrice(item.total),
                style: TextStyle(color: buttonColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildPromoRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
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

  Widget _buildTotalsCard() {
    final subTotal = _cartController.totalAmount;
    final shippingText = 'free'.tr;
    final total = subTotal; // promo/shipping not implemented yet
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _rowKV('sub_total'.tr, _formatPrice(subTotal)),
          const SizedBox(height: 10),
          _rowKV('shipping'.tr, shippingText, valueColor: primaryColor),
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

  Widget _buildBottomBarV2() {
    final canCheckout = _marketplaceController.isLoggedIn;
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
            onPressed: () async {
              if (!canCheckout) {
                Get.snackbar('login_required'.tr, 'login_to_continue'.tr, snackPosition: SnackPosition.BOTTOM);
                Get.to(() => const MarketplaceLoginScreen());
                return;
              }
              await _openCheckoutSelector();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text('checkout'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Future<void> _openCheckoutSelector() async {
    final sellerIds = _cartController.sellerIds;
    if (sellerIds.isEmpty) return;

    if (sellerIds.length == 1) {
      Get.to(() => CheckoutScreen(sellerId: sellerIds.first));
      return;
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'choose_seller_for_checkout'.tr,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...sellerIds.map((sellerId) {
                final items = _cartController.getItemsBySeller(sellerId);
                final total = _cartController.getTotalBySeller(sellerId);
                final sellerName = items.isNotEmpty ? items.first.sellerName : 'seller_fallback'.tr;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[800],
                    child: const Icon(Icons.store, color: Colors.white, size: 18),
                  ),
                  title: Text(sellerName, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'items_title'.trParams({'count': items.length.toString()}),
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  trailing: Text(_formatPrice(total), style: TextStyle(color: buttonColor, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Get.back();
                    Get.to(() => CheckoutScreen(sellerId: sellerId));
                  },
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey[700]!),
                  ),
                  child: Text('cancel'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showClearCartDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('clear_cart_question'.tr, style: const TextStyle(color: Colors.white)),
        content: Text('clear_cart_confirm'.tr, style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              _cartController.clearCart();
              Get.back();
            },
            child: Text(
              'clear'.tr,
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteItemDialog(CartItem item) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('delete_item_question'.tr, style: const TextStyle(color: Colors.white)),
        content: Text(
          'delete_item_from_cart_confirm'.trParams({'name': item.productName}),
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              _cartController.removeFromCart(item.productId);
              Get.back();
            },
            child: Text(
              'delete'.tr,
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return formatShortMoneyWithCurrency(price);
  }
}
