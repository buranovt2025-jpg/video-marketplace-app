import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/widgets/app_network_image.dart';
import 'package:tiktok_tutorial/views/screens/seller/create_product_screen.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({Key? key}) : super(key: key);

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();

  @override
  void initState() {
    super.initState();
    _controller.fetchMyProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Мои товары',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: buttonColor),
            onPressed: () => Get.to(() => const CreateProductScreen()),
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.myProducts.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final products = _controller.myProducts;

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 80, color: Colors.grey[700]),
                const SizedBox(height: 24),
                Text(
                  'У вас пока нет товаров',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Добавьте первый товар, чтобы начать продавать',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Get.to(() => const CreateProductScreen()),
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить товар'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _controller.fetchMyProducts(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product);
            },
          ),
        );
      }),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final inStock = product['in_stock'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 180,
              width: double.infinity,
              color: Colors.grey[800],
              child: product['image_url'] != null
                  ? AppNetworkImage(
                      url: product['image_url']?.toString(),
                      fit: BoxFit.cover,
                      errorWidget: _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product['name'] ?? 'Без названия',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: inStock
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        inStock ? 'В наличии' : 'Нет в наличии',
                        style: TextStyle(
                          color: inStock ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Price
                Text(
                  '${product['price']?.toStringAsFixed(0) ?? '0'} сум',
                  style: TextStyle(
                    color: buttonColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Category
                if (product['category'] != null)
                  Row(
                    children: [
                      Icon(Icons.category, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        _getCategoryLabel(product['category']),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                // Description
                if (product['description'] != null &&
                    product['description'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    product['description'],
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleStock(product),
                        icon: Icon(
                          inStock ? Icons.remove_circle_outline : Icons.add_circle_outline,
                          size: 18,
                        ),
                        label: Text(inStock ? 'Убрать из наличия' : 'Вернуть в наличие'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[400],
                          side: BorderSide(color: Colors.grey[700]!),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showDeleteDialog(product),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(
        Icons.inventory_2,
        size: 48,
        color: Colors.grey[600],
      ),
    );
  }

  String _getCategoryLabel(String category) {
    final categories = {
      'fruits': 'Фрукты',
      'vegetables': 'Овощи',
      'meat': 'Мясо',
      'dairy': 'Молочные продукты',
      'bakery': 'Выпечка',
      'drinks': 'Напитки',
      'spices': 'Специи',
      'clothes': 'Одежда',
      'electronics': 'Электроника',
      'household': 'Товары для дома',
      'other': 'Другое',
    };
    return categories[category] ?? category;
  }

  Future<void> _toggleStock(Map<String, dynamic> product) async {
    final currentStock = product['in_stock'] ?? true;
    await _controller.updateProduct(
      product['id'],
      {'in_stock': !currentStock},
    );
  }

  void _showDeleteDialog(Map<String, dynamic> product) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Удалить товар?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Вы уверены, что хотите удалить "${product['name']}"?',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Отмена',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _controller.deleteProduct(product['id']);
              Get.snackbar(
                'Удалено',
                'Товар "${product['name']}" удалён',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
