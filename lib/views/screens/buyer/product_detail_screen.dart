import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/utils/responsive_helper.dart';
import 'package:tiktok_tutorial/views/screens/buyer/cart_screen.dart';
import 'package:tiktok_tutorial/views/screens/chat/chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final MarketplaceController _marketplaceController = Get.find<MarketplaceController>();
  late CartController _cartController;
  int _quantity = 1;

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
    final product = widget.product;
    final bool inStock = product['in_stock'] ?? true;
    
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
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.white),
                ),
                onPressed: () {},
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
              background: product['image_url'] != null
                  ? Image.network(
                      product['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
          ),

          // Product details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  if (product['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: buttonColor!.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getCategoryName(product['category']),
                        style: TextStyle(
                          color: buttonColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Product name
                  Text(
                    product['name'] ?? 'Товар',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    '${_formatPrice(product['price'])} сум',
                    style: TextStyle(
                      color: buttonColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stock status
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: inStock ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        inStock ? 'В наличии' : 'Нет в наличии',
                        style: TextStyle(
                          color: inStock ? Colors.green : Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Seller info
                  _buildSellerCard(product),
                  const SizedBox(height: 24),

                  // Description
                  if (product['description'] != null && product['description'].isNotEmpty) ...[
                    const Text(
                      'Описание',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product['description'],
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Quantity selector
                  if (inStock) ...[
                    const Text(
                      'Количество',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuantitySelector(),
                    const SizedBox(height: 24),
                  ],

                  // Total
                  if (inStock)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Итого:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${_formatPrice((product['price'] as num).toDouble() * _quantity)} сум',
                            style: TextStyle(
                              color: buttonColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: inStock ? _buildBottomBar(product) : _buildOutOfStockBar(),
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
                  product['seller_name'] ?? 'Продавец',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Продавец на маркетплейсе',
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
                  userId: product['seller_id'],
                  userName: product['seller_name'] ?? 'Продавец',
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

  Widget _buildBottomBar(Map<String, dynamic> product) {
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
            // Add to cart button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _cartController.addToCart(product, quantity: _quantity);
                  Get.snackbar(
                    'Добавлено',
                    '${product['name']} добавлен в корзину',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('В корзину'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: buttonColor!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Buy now button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _cartController.addToCart(product, quantity: _quantity);
                  Get.to(() => const CartScreen());
                },
                icon: const Icon(Icons.flash_on),
                label: const Text('Купить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          child: const Text(
            'Нет в наличии',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final numPrice = (price as num).toDouble();
    if (numPrice >= 1000000) {
      return '${(numPrice / 1000000).toStringAsFixed(1)}M';
    } else if (numPrice >= 1000) {
      return '${(numPrice / 1000).toStringAsFixed(0)}K';
    }
    return numPrice.toStringAsFixed(0);
  }

  String _getCategoryName(String category) {
    final categories = {
      'fruits': 'Фрукты',
      'vegetables': 'Овощи',
      'meat': 'Мясо',
      'dairy': 'Молочные',
      'bakery': 'Выпечка',
      'drinks': 'Напитки',
      'spices': 'Специи',
      'clothes': 'Одежда',
      'electronics': 'Электроника',
      'household': 'Для дома',
      'other': 'Другое',
    };
    return categories[category] ?? category;
  }
}
