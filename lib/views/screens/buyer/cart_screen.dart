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

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }
    _cartController = Get.find<CartController>();
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
        return _buildCartContent();
      }),
      bottomNavigationBar: Obx(() {
        if (_cartController.isEmpty) {
          return const SizedBox();
        }
        return _buildBottomBar();
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

  Widget _buildCartContent() {
    final sellerIds = _cartController.sellerIds;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sellerIds.length,
      itemBuilder: (context, index) {
        final sellerId = sellerIds[index];
        final items = _cartController.getItemsBySeller(sellerId);
        final sellerTotal = _cartController.getTotalBySeller(sellerId);

        return _buildSellerSection(sellerId, items, sellerTotal);
      },
    );
  }

  Widget _buildSellerSection(String sellerId, List<CartItem> items, double total) {
    final sellerName = items.isNotEmpty ? items.first.sellerName : 'seller_fallback'.tr;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[800],
                  child: const Icon(Icons.store, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sellerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatPrice(total),
                  style: TextStyle(
                    color: buttonColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey, height: 1),

          // Items
          ...items.map((item) => _buildCartItem(item)),

          // Checkout button for this seller
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _marketplaceController.isLoggedIn
                    ? () => Get.to(() => CheckoutScreen(sellerId: sellerId))
                    : () {
                        Get.snackbar(
                          'login_required'.tr,
                          'login_to_continue'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('checkout'.tr),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Container(
            width: 80,
            height: 80,
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
                      errorWidget: Icon(Icons.inventory_2, color: Colors.grey[600]),
                    ),
                  )
                : Icon(
                    Icons.inventory_2,
                    color: Colors.grey[600],
                  ),
          ),
          const SizedBox(width: 12),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(item.price),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),

                // Quantity controls
                Row(
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onPressed: () => _cartController.decrementQuantity(item.productId),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add,
                      onPressed: () => _cartController.incrementQuantity(item.productId),
                    ),
                    const Spacer(),
                    Text(
                      _formatPrice(item.total),
                      style: TextStyle(
                        color: buttonColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
            onPressed: () => _showDeleteItemDialog(item),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildBottomBar() {
    final canCheckout = _marketplaceController.isLoggedIn;
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'total'.tr}:',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                    _formatPrice(_cartController.totalAmount),
                    style: TextStyle(
                      color: buttonColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Obx(() => Text(
                  'items_count'.trParams({'count': _cartController.itemCount.toString()}),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                )),
            const SizedBox(width: 12),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () async {
                  if (!canCheckout) {
                    Get.snackbar(
                      'login_required'.tr,
                      'login_to_continue'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    Get.to(() => const MarketplaceLoginScreen());
                    return;
                  }
                  await _openCheckoutSelector();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('checkout'.tr),
              ),
            ),
          ],
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
