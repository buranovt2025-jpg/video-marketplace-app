import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/services/api_service.dart';
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
  
  // Social features state
  bool _isLiked = false;
  int _likesCount = 0;
  List<dynamic> _comments = [];
  List<dynamic> _reviews = [];
  double _averageRating = 0.0;
  int _reviewsCount = 0;
  bool _isLoadingSocial = true;
  
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 5;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }
    _cartController = Get.find<CartController>();
    _loadSocialData();
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    _reviewController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSocialData() async {
    final productId = widget.product['id'];
    if (productId == null) {
      setState(() => _isLoadingSocial = false);
      return;
    }
    
    try {
      final results = await Future.wait([
        ApiService.getProductLikes(productId),
        ApiService.getProductComments(productId),
        ApiService.getProductReviews(productId),
      ]);
      
      setState(() {
        final likesData = results[0] as Map<String, dynamic>;
        _likesCount = likesData['likes_count'] ?? 0;
        _isLiked = likesData['user_liked'] ?? false;
        
        _comments = results[1] as List<dynamic>;
        
        final reviewsData = results[2] as Map<String, dynamic>;
        _reviews = reviewsData['reviews'] ?? [];
        _averageRating = (reviewsData['stats']?['average'] ?? 0.0).toDouble();
        _reviewsCount = reviewsData['stats']?['count'] ?? 0;
        
        _isLoadingSocial = false;
      });
    } catch (e) {
      setState(() => _isLoadingSocial = false);
    }
  }
  
  Future<void> _toggleLike() async {
    if (!ApiService.isLoggedIn) {
      Get.snackbar('Ошибка', 'Войдите чтобы поставить лайк',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      final result = await ApiService.likeProduct(widget.product['id']);
      setState(() {
        _isLiked = result['liked'];
        _likesCount = result['likes_count'];
      });
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось поставить лайк',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> _addComment() async {
    if (!ApiService.isLoggedIn) {
      Get.snackbar('Ошибка', 'Войдите чтобы оставить комментарий',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    
    try {
      final comment = await ApiService.createProductComment(
        productId: widget.product['id'],
        content: content,
      );
      setState(() {
        _comments.insert(0, comment);
        _commentController.clear();
      });
      Get.snackbar('Успешно', 'Комментарий добавлен',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось добавить комментарий',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> _addReview() async {
    if (!ApiService.isLoggedIn) {
      Get.snackbar('Ошибка', 'Войдите чтобы оставить отзыв',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      final review = await ApiService.createReview(
        productId: widget.product['id'],
        rating: _selectedRating,
        comment: _reviewController.text.trim().isNotEmpty ? _reviewController.text.trim() : null,
      );
      await _loadSocialData();
      _reviewController.clear();
      Get.back();
      Get.snackbar('Успешно', 'Отзыв добавлен',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось добавить отзыв',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  void _shareProduct() {
    final product = widget.product;
    final text = '${product['name']}\n${_formatPrice(product['price'])} сум\n\nСмотри на GoGoMarket!';
    Share.share(text);
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
                onPressed: _shareProduct,
              ),
              // Hide cart icon for sellers - they cannot purchase products
              if (!_marketplaceController.isSeller)
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
                  const SizedBox(height: 16),
                  
                  // Social bar (likes, comments, reviews, share)
                  _buildSocialBar(),
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

                  // Reviews section
                  _buildReviewsSection(),
                  const SizedBox(height: 24),
                  
                  // Comments section
                  _buildCommentsSection(),

                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _marketplaceController.isSeller 
          ? _buildSellerRestrictionBar() 
          : (product['is_admin_content'] == true 
              ? _buildAdminContentBar()
              : (inStock ? _buildBottomBar(product) : _buildOutOfStockBar())),
    );
  }
  
  Widget _buildSocialBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Like button
          InkWell(
            onTap: _toggleLike,
            child: Row(
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 6),
                Text(
                  '$_likesCount',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          
          // Comments button
          InkWell(
            onTap: () => _showCommentsSheet(),
            child: Row(
              children: [
                const Icon(Icons.comment_outlined, color: Colors.white, size: 24),
                const SizedBox(width: 6),
                Text(
                  '${_comments.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          
          // Reviews button
          InkWell(
            onTap: () => _showReviewDialog(),
            child: Row(
              children: [
                const Icon(Icons.star_border, color: Colors.amber, size: 24),
                const SizedBox(width: 6),
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  ' ($_reviewsCount)',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Share button
          InkWell(
            onTap: _shareProduct,
            child: const Icon(Icons.share_outlined, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Отзывы',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showReviewDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Написать'),
              style: TextButton.styleFrom(foregroundColor: buttonColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Rating summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    _averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _averageRating.round() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_reviewsCount отзывов',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _reviews.isEmpty
                    ? Text(
                        'Пока нет отзывов.\nБудьте первым!',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      )
                    : Column(
                        children: _reviews.take(2).map((review) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < (review['rating'] ?? 0) ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 12,
                                    );
                                  }),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    review['user_name'] ?? 'Пользователь',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Комментарии (${_comments.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _showCommentsSheet(),
              child: Text('Все', style: TextStyle(color: buttonColor)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Comment input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Написать комментарий...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: _addComment,
                icon: Icon(Icons.send, color: buttonColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Recent comments
        if (_comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Пока нет комментариев',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          )
        else
          ...(_comments.take(3).map((comment) => _buildCommentItem(comment)).toList()),
      ],
    );
  }
  
  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey[800],
                backgroundImage: comment['user_avatar'] != null
                    ? NetworkImage(comment['user_avatar'])
                    : null,
                child: comment['user_avatar'] == null
                    ? const Icon(Icons.person, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                comment['user_name'] ?? 'Пользователь',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(comment['created_at']),
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment['content'] ?? '',
            style: TextStyle(color: Colors.grey[300], fontSize: 13),
          ),
        ],
      ),
    );
  }
  
  void _showCommentsSheet() {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Комментарии (${_comments.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _comments.isEmpty
                  ? Center(
                      child: Text(
                        'Пока нет комментариев',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _comments.length,
                      itemBuilder: (context, index) => _buildCommentItem(_comments[index]),
                    ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Написать комментарий...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _addComment();
                      Get.back();
                    },
                    icon: Icon(Icons.send, color: buttonColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
  
  void _showReviewDialog() {
    _selectedRating = 5;
    _reviewController.clear();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Оставить отзыв',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (context, setDialogState) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setDialogState(() => _selectedRating = index + 1);
                      },
                      icon: Icon(
                        index < _selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ваш отзыв (необязательно)',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Отмена', style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: _addReview,
            style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 1) return 'сейчас';
      if (diff.inMinutes < 60) return '${diff.inMinutes} мин';
      if (diff.inHours < 24) return '${diff.inHours} ч';
      if (diff.inDays < 7) return '${diff.inDays} дн';
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return '';
    }
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

  Widget _buildSellerRestrictionBar() {
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Продавцы не могут покупать товары.\nВы можете только выставлять товары и следить за продажами.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminContentBar() {
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, color: Colors.purple, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Официальный контент администрации.\nЭтот контент нельзя купить - только просмотр.',
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
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
