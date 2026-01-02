import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/favorites_controller.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/ui/app_ui.dart';
import 'package:tiktok_tutorial/ui/app_media.dart';

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
          style: AppUI.h2,
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
        return _buildFavoritesList(favoritesController, cartController);
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
            style: AppUI.h2.copyWith(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 8),
          Text(
            'add_to_favorites'.tr,
            style: AppUI.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(FavoritesController favoritesController, CartController cartController) {
    return ListView.builder(
      padding: AppUI.pagePadding,
      itemCount: favoritesController.favorites.length,
      itemBuilder: (context, index) {
        final product = favoritesController.favorites[index];
        return _buildFavoriteItem(product, favoritesController, cartController);
      },
    );
  }

  Widget _buildFavoriteItem(
    Map<String, dynamic> product,
    FavoritesController favoritesController,
    CartController cartController,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppUI.radiusL),
              bottomLeft: Radius.circular(AppUI.radiusL),
            ),
            child: SizedBox(
              width: 100,
              height: 100,
              child: AppMedia.image(
                product['image_url'],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
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
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (product['seller_name'] != null)
                    Text(
                      product['seller_name'],
                      style: AppUI.muted.copyWith(fontSize: 12),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatPrice(product['price']?.toDouble() ?? 0)} сум',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
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
                onPressed: () => favoritesController.removeFromFavorites(product['id']),
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
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  void _showClearDialog(FavoritesController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'delete'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Очистить избранное?',
          style: AppUI.muted,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: const TextStyle(color: textSecondaryColor)),
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
