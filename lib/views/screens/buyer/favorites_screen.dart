import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/favorites_controller.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

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
                  ? CachedNetworkImage(
                      imageUrl: product['image_url'],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
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
                    '${_formatPrice(product['price']?.toDouble() ?? 0)} сум',
                    style: const TextStyle(
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
                onPressed: () => favoritesController.removeFromFavorites(product['id']),
              ),
              // Add to cart
              IconButton(
                icon: const Icon(Icons.add_shopping_cart, color: primaryColor),
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
