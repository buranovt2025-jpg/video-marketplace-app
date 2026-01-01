import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/favorites_controller.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/views/widgets/app_network_image.dart';
import 'package:tiktok_tutorial/utils/formatters.dart';
import 'package:tiktok_tutorial/utils/money.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favoritesController = Get.find<FavoritesController>();
    final cartController = Get.find<CartController>();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          'favorites'.tr,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() => favoritesController.favorites.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.white),
                  onPressed: () => _showClearDialog(favoritesController),
                )
              : const SizedBox()),
        ],
      ),
      body: Obx(() {
        if (favoritesController.favorites.isEmpty) {
          return _buildEmptyState();
        }
        return _buildWishlistV2(context, favoritesController, cartController);
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'no_favorites'.tr,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'add_to_favorites'.tr,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(FavoritesController favoritesController, CartController cartController) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favoritesController.favorites.length,
      itemBuilder: (context, index) {
        final product = favoritesController.favorites[index];
        return _buildFavoriteItem(product, favoritesController, cartController);
      },
    );
  }

  Widget _buildWishlistV2(BuildContext context, FavoritesController favoritesController, CartController cartController) {
    final cats = <String>{};
    for (final p in favoritesController.favorites) {
      final c = (p['category'] ?? '').toString().trim();
      if (c.isNotEmpty) cats.add(c);
    }
    final categories = <String>['all', ...cats.toList()..sort()];

    final RxString selected = 'all'.obs;

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, idx) {
              final c = categories[idx];
              final label = (c == 'all') ? 'all'.tr : c.tr;
              return Obx(() {
                final isSelected = selected.value == c;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => selected.value = c,
                  selectedColor: primaryColor,
                  backgroundColor: Colors.grey[850],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                );
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() {
            final c = selected.value;
            final list = favoritesController.favorites.where((p) {
              if (c == 'all') return true;
              return (p['category'] ?? '').toString() == c;
            }).toList();

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final product = list[index];
                return _wishlistItem(product, favoritesController, cartController);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _wishlistItem(
    Map<String, dynamic> product,
    FavoritesController favoritesController,
    CartController cartController,
  ) {
    final name = (product['name'] ?? 'product'.tr).toString();
    final price = _formatPrice(asDouble(product['price']));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              child: AppNetworkImage(
                url: product['image_url']?.toString(),
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: Colors.grey[850],
                  child: Icon(Icons.inventory_2, color: Colors.grey[600]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: TextStyle(color: Colors.grey[300], fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {
                      cartController.addToCart(product, quantity: 1);
                      Get.snackbar(
                        'added'.tr,
                        'added_to_cart_named'.trParams({'name': name}),
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('add_to_cart'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => favoritesController.removeFromFavorites((product['id'] ?? '').toString()),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(
    Map<String, dynamic> product,
    FavoritesController favoritesController,
    CartController cartController,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: SizedBox(
              width: 100,
              height: 100,
              child: product['image_url'] != null
                  ? AppNetworkImage(
                      url: product['image_url']?.toString(),
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: Container(
                        color: Colors.grey[800],
                        child: Icon(Icons.inventory_2, color: Colors.grey[600]),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: Icon(Icons.inventory_2, color: Colors.grey[600]),
                    ),
            ),
          ),
          
          // Product info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Product',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (product['seller_name'] != null)
                    Text(
                      product['seller_name'],
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPrice(asDouble(product['price'])),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Actions
          Column(
            children: [
              // Remove from favorites
              IconButton(
                icon: Icon(Icons.favorite, color: Colors.red[400]),
                onPressed: () => favoritesController.removeFromFavorites((product['id'] ?? '').toString()),
              ),
              // Add to cart
              IconButton(
                icon: Icon(Icons.add_shopping_cart, color: primaryColor),
                onPressed: () {
                  cartController.addToCart(product);
                  Get.snackbar(
                    'cart'.tr,
                    '${product['name']} added',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 1),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return formatShortMoneyWithCurrency(price);
  }

  void _showClearDialog(FavoritesController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'delete'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Clear all favorites?',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              controller.clearFavorites();
              Get.back();
            },
            child: Text(
              'delete'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
