import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/utils/formatters.dart';
import 'package:tiktok_tutorial/utils/money.dart';
import 'package:tiktok_tutorial/views/screens/buyer/cart_screen.dart';
import 'package:tiktok_tutorial/views/screens/buyer/product_detail_screen.dart';
import 'package:tiktok_tutorial/views/widgets/app_network_image.dart';

class ProductQuickBuySheet extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductQuickBuySheet({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final name = (product['name'] ?? 'product'.tr).toString();
    final priceText = formatMoneyWithCurrency(product['price']);
    final sellerName = (product['seller_name'] ?? 'seller_fallback'.tr).toString();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 84,
                    height: 84,
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
                        priceText,
                        style: TextStyle(color: buttonColor ?? primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sellerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (product['description'] ?? '').toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      cart.addToCart(product, quantity: 1);
                      Get.snackbar(
                        'added'.tr,
                        'added_to_cart_named'.trParams({'name': name}),
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text('add_to_cart'.tr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: (buttonColor ?? primaryColor).withOpacity(0.8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      cart.addToCart(product, quantity: 1);
                      Get.back();
                      Get.to(() => const CartScreen());
                    },
                    icon: const Icon(Icons.flash_on),
                    label: Text('buy_now'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor ?? primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Get.back();
                      Get.to(() => ProductDetailScreen(product: Map<String, dynamic>.from(product)));
                    },
                    child: Text('open_product_card'.tr),
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    final count = cart.itemCount;
                    return TextButton(
                      onPressed: () {
                        Get.back();
                        Get.to(() => const CartScreen());
                      },
                      child: Text('${'cart'.tr}${count > 0 ? ' ($count)' : ''}'),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

