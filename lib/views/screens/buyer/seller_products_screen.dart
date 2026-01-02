import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/ui/app_ui.dart';
import 'package:tiktok_tutorial/ui/app_media.dart';
import 'package:tiktok_tutorial/views/screens/buyer/product_detail_screen.dart';
import 'package:tiktok_tutorial/views/screens/chat/chat_screen.dart';

class SellerProductsScreen extends StatelessWidget {
  final String sellerId;
  final String sellerName;

  const SellerProductsScreen({
    Key? key,
    required this.sellerId,
    required this.sellerName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceController>();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(sellerName, style: AppUI.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () => Get.to(() => ChatScreen(userId: sellerId, userName: sellerName)),
          ),
        ],
      ),
      body: Obx(() {
        final products = controller.products.where((p) => p['seller_id']?.toString() == sellerId).toList();

        if (products.isEmpty) {
          return Center(
            child: Padding(
              padding: AppUI.pagePadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 64, color: Colors.white.withOpacity(0.22)),
                  const SizedBox(height: 16),
                  Text('Нет товаров', style: AppUI.h2.copyWith(color: Colors.white.withOpacity(0.9))),
                  const SizedBox(height: 8),
                  Text('У этого продавца пока нет товаров', style: AppUI.muted, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: AppUI.pagePadding,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final rawPrice = product['price'];
            final priceText = rawPrice is num ? rawPrice.toStringAsFixed(0) : (rawPrice?.toString() ?? '0');

            return InkWell(
              onTap: () => Get.to(() => ProductDetailScreen(product: product)),
              borderRadius: BorderRadius.circular(AppUI.radiusL),
              child: Container(
                decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppUI.radiusL)),
                        child: AppMedia.image(
                          product['image_url'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (product['name'] ?? 'Товар').toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.2),
                            ),
                            const Spacer(),
                            Text(
                              '$priceText сум',
                              style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

