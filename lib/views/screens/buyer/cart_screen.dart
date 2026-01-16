import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/ui/app_ui.dart';
import 'package:tiktok_tutorial/ui/app_media.dart';
import 'package:tiktok_tutorial/views/screens/buyer/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late CartController _cartController;

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
        title: Text('cart'.tr, style: AppUI.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() => _cartController.items.isNotEmpty
              ? TextButton(
                  onPressed: _showClearCartDialog,
                  child: Text(
                    'Очистить',
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
            'empty_cart'.tr,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте товары из каталога',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: AppUI.primaryButton(),
            child: const Text('К покупкам'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    final sellerIds = _cartController.sellerIds;

    return ListView.builder(
      padding: AppUI.pagePadding,
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
    final sellerName = items.isNotEmpty ? items.first.sellerName : 'Продавец';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${_formatPrice(total)} сум',
                  style: TextStyle(
                    color: buttonColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),

          // Items
          ...items.map((item) => _buildCartItem(item)),

          // Checkout button for this seller
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.to(() => CheckoutScreen(sellerId: sellerId)),
                style: AppUI.primaryButton(),
                child: const Text('Оформить заказ'),
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
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppUI.radiusM),
            ),
            child: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppUI.radiusM),
                    child: AppMedia.image(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
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
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatPrice(item.price)} сум',
                  style: AppUI.muted,
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
                      '${_formatPrice(item.total)} сум',
                      style: TextStyle(
                        color: buttonColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
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
          color: surfaceColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
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
                    'Всего:',
                    style: AppUI.muted.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                    '${_formatPrice(_cartController.totalAmount)} сум',
                    style: TextStyle(
                      color: buttonColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  )),
                ],
              ),
            ),
            Obx(() => Text(
              '${_cartController.itemCount} товар(ов)',
              style: AppUI.muted,
            )),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Очистить корзину?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Все товары будут удалены из корзины',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              _cartController.clearCart();
              Get.back();
            },
            child: Text(
              'Очистить',
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
        title: const Text(
          'Удалить товар?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Удалить "${item.productName}" из корзины?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              _cartController.removeFromCart(item.productId);
              Get.back();
            },
            child: Text(
              'Удалить',
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );
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
