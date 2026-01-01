import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/controllers/favorites_controller.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/utils/responsive_helper.dart';
import 'package:tiktok_tutorial/views/screens/buyer/cart_screen.dart';
import 'package:tiktok_tutorial/views/screens/chat/chat_screen.dart';
import 'package:tiktok_tutorial/views/widgets/app_network_image.dart';
import 'package:tiktok_tutorial/utils/formatters.dart';
import 'package:tiktok_tutorial/utils/money.dart';
import 'package:tiktok_tutorial/utils/share_utils.dart';
import 'package:tiktok_tutorial/utils/feature_flags.dart';
import 'package:tiktok_tutorial/views/widgets/product_reviews_sheet.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final MarketplaceController _marketplaceController = Get.find<MarketplaceController>();
  late CartController _cartController;
  late FavoritesController _favoritesController;
  int _quantity = 1;
  int _imageIndex = 0;
  bool _isFollowingSeller = false;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }
    _cartController = Get.find<CartController>();
    _favoritesController = Get.find<FavoritesController>();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bool inStock = product['in_stock'] ?? true;
    final productId = (product['id'] ?? '').toString();
    final images = _extractImages(product);
    final currentImage = images.isNotEmpty ? images[_imageIndex.clamp(0, images.length - 1)] : null;
    
    // Responsive image height
    final imageHeight = ResponsiveHelper.responsiveValue(
      context,
      mobile: 400.0,
      tablet: 500.0,
      desktop: 550.0,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: imageHeight,
            pinned: true,
            backgroundColor: backgroundColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Get.back(),
            ),
            actions: [
              Obx(() {
                final isFav = _favoritesController.isFavorite(productId);
                return IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? primaryColor : Colors.white),
                  ),
                  onPressed: () => _favoritesController.toggleFavorite(product),
                );
              }),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.white),
                ),
                onPressed: () async {
                  await copyToClipboardWithToast(buildProductShareText(product));
                },
              ),
              Obx(() => Stack(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_cart, color: Colors.white),
                    ),
                    onPressed: () => Get.to(() => const CartScreen()),
                  ),
                  if (_cartController.itemCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: buttonColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_cartController.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              )),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    url: currentImage ?? product['image_url']?.toString(),
                    fit: BoxFit.cover,
                    errorWidget: _buildPlaceholderImage(),
                  ),
                  // right-side thumbnails (Figma-like)
                  if (images.length > 1)
                    Positioned(
                      right: 12,
                      top: 110,
                      child: Column(
                        children: List.generate(images.length.clamp(0, 4), (idx) {
                          final url = images[idx];
                          final selected = idx == _imageIndex;
                          return GestureDetector(
                            onTap: () => setState(() => _imageIndex = idx),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: selected ? primaryColor : Colors.white24, width: selected ? 2 : 1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 54,
                                  height: 54,
                                  child: AppNetworkImage(
                                    url: url,
                                    fit: BoxFit.cover,
                                    errorWidget: Container(
                                      color: Colors.grey[900],
                                      child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  // bottom gradient (readability)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 160,
                    child: IgnorePointer(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black45,
                              Colors.black87,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Product details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderBlock(product, inStock: inStock),
                  const SizedBox(height: 16),

                  _buildInfoLine(product),
                  const SizedBox(height: 16),

                  _buildProductDetailsCard(product),
                  const SizedBox(height: 16),

                  _buildReviewsPreview(product),
                  const SizedBox(height: 16),

                  _buildSellerCardV2(product),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: inStock ? _buildBottomBarV2(product) : _buildOutOfStockBar(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Icon(
          Icons.inventory_2,
          size: 80,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildSellerCard(Map<String, dynamic> product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.store, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['seller_name'] ?? 'seller_fallback'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'seller_on_marketplace'.tr,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: buttonColor),
            onPressed: () {
              if (product['seller_id'] != null) {
                Get.to(() => ChatScreen(
                  userId: product['seller_id'].toString(),
                  userName: product['seller_name'] ?? 'seller_fallback'.tr,
                ));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBlock(Map<String, dynamic> product, {required bool inStock}) {
    final category = (product['category'] ?? '').toString().trim();
    final priceText = _formatPrice(product['price']);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          priceText,
          style: TextStyle(color: primaryColor, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      'free_shipping'.tr,
                      style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        category.tr,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: inStock ? Colors.green.withOpacity(0.16) : Colors.red.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      (inStock ? 'in_stock' : 'out_of_stock').tr,
                      style: TextStyle(color: inStock ? Colors.greenAccent : primaryColor, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                (product['name'] ?? 'product'.tr).toString(),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoLine(Map<String, dynamic> product) {
    final ratingAvg = asDouble(product['rating_avg']);
    final ratingCount = asInt(product['rating_count'] ?? product['reviews_count'] ?? product['review_count'] ?? 0);
    final city = (product['city'] ?? '').toString().trim();
    final country = (product['country'] ?? '').toString().trim();
    final location = [city, country].where((e) => e.isNotEmpty).join(', ');

    return Row(
      children: [
        if (location.isNotEmpty) ...[
          const Icon(Icons.location_on, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              location,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else
          Expanded(child: Text('', style: TextStyle(color: Colors.grey[400], fontSize: 12))),
        if (ratingAvg > 0 || ratingCount > 0) ...[
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 6),
          Text(
            ratingAvg > 0 ? ratingAvg.toStringAsFixed(1) : '-',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(width: 6),
          if (ratingCount > 0)
            Text(
              '($ratingCount)',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
        ],
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
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

  Widget _buildProductDetailsCard(Map<String, dynamic> product) {
    final rows = <MapEntry<String, String>>[
      MapEntry('product'.tr, (product['name'] ?? 'product'.tr).toString()),
      if ((product['category'] ?? '').toString().trim().isNotEmpty) MapEntry('category'.tr, (product['category'] ?? '').toString().tr),
      MapEntry('quantity'.tr, (product['quantity'] ?? '1').toString()),
      MapEntry('in_stock'.tr, ((product['in_stock'] ?? true) == true) ? 'yes'.tr : 'no'.tr),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('product_details'.tr, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildCard(
          child: Column(
            children: rows.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key, style: TextStyle(color: Colors.grey[400], fontSize: 12))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        if ((product['description'] ?? '').toString().trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            (product['description'] ?? '').toString(),
            style: TextStyle(color: Colors.grey[400], height: 1.5),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewsPreview(Map<String, dynamic> product) {
    final productId = (product['id'] ?? '').toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('product_reviews'.tr, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (kEnableProductReviews && productId.trim().isNotEmpty)
              TextButton(
                onPressed: () {
                  Get.bottomSheet(
                    ProductReviewsSheet(
                      productId: productId,
                      productName: (product['name'] ?? 'product'.tr).toString(),
                    ),
                    isScrollControlled: true,
                  );
                },
                child: Text('see_all'.tr, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _buildCard(
          child: Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  height: 64,
                  margin: EdgeInsets.only(right: i == 2 ? 0 : 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSellerCardV2(Map<String, dynamic> product) {
    final sellerName = (product['seller_name'] ?? 'seller_fallback'.tr).toString();
    return _buildCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey[850],
            child: const Icon(Icons.store, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sellerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('seller_on_marketplace'.tr, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => setState(() => _isFollowingSeller = !_isFollowingSeller),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isFollowingSeller ? Colors.white : primaryColor,
              side: BorderSide(color: _isFollowingSeller ? Colors.white24 : primaryColor.withOpacity(0.9)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text((_isFollowingSeller ? 'following' : 'follow').tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: primaryColor),
            onPressed: () {
              if (product['seller_id'] != null) {
                Get.to(() => ChatScreen(
                      userId: product['seller_id'].toString(),
                      userName: sellerName,
                    ));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white),
            onPressed: _quantity > 1
                ? () => setState(() => _quantity--)
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '$_quantity',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBarV2(Map<String, dynamic> product) {
    final total = asDouble(product['price']) * _quantity;
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
        child: Row(
          children: [
            _qtyChip(),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _cartController.addToCart(product, quantity: _quantity);
                  Get.snackbar(
                    'added'.tr,
                    'added_to_cart_named'.trParams({'name': (product['name'] ?? '').toString()}),
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Text(
                  '${'add_to_cart'.tr} • ${_formatPrice(total)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.remove, color: Colors.white, size: 18),
            ),
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text('$_quantity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          GestureDetector(
            onTap: () => setState(() => _quantity++),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractImages(Map<String, dynamic> product) {
    final list = <String>[];
    final main = product['image_url']?.toString();
    if (main != null && main.trim().isNotEmpty) list.add(main.trim());
    final imgs = product['images'];
    if (imgs is List) {
      for (final e in imgs) {
        final s = (e ?? '').toString().trim();
        if (s.isNotEmpty && !list.contains(s)) list.add(s);
      }
    }
    return list;
  }

  Widget _buildOutOfStockBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            'out_of_stock_message'.tr,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    final numPrice = asDouble(price, fallback: 0);
    return formatShortMoneyWithCurrency(numPrice);
  }

  // Category labels are localized via translations, see `app_translations.dart`.
  // Example: 'fruits'.tr, 'vegetables'.tr, etc.
}
