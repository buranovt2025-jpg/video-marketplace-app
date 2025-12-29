import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/utils/responsive_helper.dart';
import 'package:tiktok_tutorial/views/screens/seller/create_product_screen.dart';
import 'package:tiktok_tutorial/views/screens/seller/create_reel_screen.dart';
import 'package:tiktok_tutorial/views/screens/seller/create_story_screen.dart';
import 'package:tiktok_tutorial/views/screens/seller/my_products_screen.dart';
import 'package:tiktok_tutorial/views/screens/auth/marketplace_login_screen.dart';
import 'package:tiktok_tutorial/views/screens/buyer/product_detail_screen.dart';
import 'package:tiktok_tutorial/views/screens/buyer/cart_screen.dart';
import 'package:tiktok_tutorial/views/screens/buyer/order_tracking_screen.dart';
import 'package:tiktok_tutorial/views/screens/chat/chat_screen.dart';
import 'package:tiktok_tutorial/views/screens/profile/edit_profile_screen.dart';
import 'package:tiktok_tutorial/views/screens/stories/story_viewer_screen.dart';
import 'package:tiktok_tutorial/views/screens/cabinets/seller_cabinet_screen.dart';
import 'package:tiktok_tutorial/views/screens/cabinets/buyer_cabinet_screen.dart';
import 'package:tiktok_tutorial/views/screens/buyer/nearby_sellers_screen.dart';
import 'package:tiktok_tutorial/views/screens/common/delete_account_screen.dart';
import 'package:tiktok_tutorial/views/screens/admin/seller_verification_screen.dart';
import 'package:tiktok_tutorial/views/widgets/shimmer_loading.dart';
import 'package:tiktok_tutorial/views/screens/legal/legal_page.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  final bool isGuestMode;
  
  const MarketplaceHomeScreen({Key? key, this.isGuestMode = false}) : super(key: key);

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  int _currentIndex = 0;
  
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _sortBy = 'default'; // default, price_low, price_high, newest
  
  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'Все'},
    {'value': 'electronics', 'label': 'Электроника'},
    {'value': 'clothing', 'label': 'Одежда'},
    {'value': 'food', 'label': 'Продукты'},
    {'value': 'home', 'label': 'Дом и сад'},
    {'value': 'beauty', 'label': 'Красота'},
    {'value': 'sports', 'label': 'Спорт'},
    {'value': 'other', 'label': 'Другое'},
  ];
  
  final List<Map<String, String>> _sortOptions = [
    {'value': 'default', 'label': 'По умолчанию'},
    {'value': 'price_low', 'label': 'Сначала дешевые'},
    {'value': 'price_high', 'label': 'Сначала дорогие'},
    {'value': 'newest', 'label': 'Сначала новые'},
  ];
  
  // Use controller's isGuestMode flag OR widget parameter (for robustness)
  bool get _isGuestMode => widget.isGuestMode || _controller.isGuest;
  bool get _isSeller => !_isGuestMode && _controller.currentUser.value?['role'] == 'seller';
  bool get _isBuyer => _isGuestMode || _controller.currentUser.value?['role'] == 'buyer';
  
  // Get max valid index based on role (Guest mode = 3 tabs like buyer)
  int get _maxIndex => _isSeller ? 4 : 3; // Seller: 5 tabs (0-4), Buyer/Guest: 4 tabs (0-3)
  
  // Ensure currentIndex is within bounds
  int get _safeCurrentIndex => _currentIndex > _maxIndex ? _maxIndex : _currentIndex;
  
  // Helper to prompt login for protected actions
  void _promptLogin(String action) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('login_required'.tr, style: const TextStyle(color: Colors.white)),
        content: Text(
          'Войдите, чтобы $action',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.to(() => const MarketplaceLoginScreen());
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text('login'.tr),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _controller.fetchProducts();
    await _controller.fetchReels();
    await _controller.fetchStories();
    if (_controller.isLoggedIn) {
      await _controller.fetchOrders();
    }
  }

  void _openProductFromReel(Map<String, dynamic> reel) {
    final productId = reel['product_id'];
    if (productId == null) return;
    
    // Find the product in the products list
    final product = _controller.products.firstWhere(
      (p) => p['id'] == productId,
      orElse: () => <String, dynamic>{},
    );
    
    if (product.isNotEmpty) {
      Get.to(() => ProductDetailScreen(product: product));
    } else {
      Get.snackbar(
        'error'.tr,
        'Товар не найден',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Obx(() {
        // Check guest mode reactively from controller
        final isGuest = widget.isGuestMode || _controller.isGuest;
        
        if (isGuest) {
          return _buildGuestModeBody();
        }
        
        if (!_controller.isLoggedIn) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }
        
        // Different tabs for seller vs buyer
        if (_isSeller) {
          return IndexedStack(
            index: _safeCurrentIndex,
            children: [
              _buildFeedTab(),
              _buildExploreTab(),
              _buildCreateTab(),
              _buildOrdersTab(),
              _buildProfileTab(),
            ],
          );
        } else {
          // Buyer: no Create tab
          return IndexedStack(
            index: _safeCurrentIndex,
            children: [
              _buildFeedTab(),
              _buildExploreTab(),
              _buildOrdersTab(),
              _buildProfileTab(),
            ],
          );
        }
      }),
      bottomNavigationBar: Obx(() {
        final isGuest = widget.isGuestMode || _controller.isGuest;
        if (isGuest) {
          return _buildGuestBottomNav();
        }
        return BottomNavigationBar(
            currentIndex: _safeCurrentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.black,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey,
            items: _isSeller ? [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: 'feed'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.search),
                label: 'search'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.add_box),
                label: 'create'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.shopping_bag),
                label: 'orders'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: 'profile'.tr,
              ),
            ] : [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: 'feed'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.search),
                label: 'search'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.shopping_bag),
                label: 'orders'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: 'profile'.tr,
              ),
            ],
          );
      }),
    );
  }
  
  // Guest mode body - shows feed and explore without login
  Widget _buildGuestModeBody() {
    return IndexedStack(
      index: _safeCurrentIndex,
      children: [
        _buildFeedTab(),
        _buildExploreTab(),
        _buildGuestOrdersTab(),
        _buildGuestProfileTab(),
      ],
    );
  }
  
  // Guest mode bottom navigation
  Widget _buildGuestBottomNav() {
    return BottomNavigationBar(
      currentIndex: _safeCurrentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.black,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: 'feed'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.search),
          label: 'search'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_bag),
          label: 'orders'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.login),
          label: 'login'.tr,
        ),
      ],
    );
  }
  
  // Guest orders tab - prompts login
  Widget _buildGuestOrdersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 24),
          Text(
            'Войдите, чтобы видеть заказы',
            style: TextStyle(color: Colors.grey[400], fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.to(() => const MarketplaceLoginScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('login'.tr, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
  
  // Guest profile tab - shows login/register options
  Widget _buildGuestProfileTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[800],
              child: Icon(Icons.person_outline, size: 60, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Text(
              'Добро пожаловать!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Войдите или зарегистрируйтесь,\nчтобы делать покупки',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.to(() => const MarketplaceLoginScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('login'.tr, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.to(() => const MarketplaceLoginScreen()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('register'.tr, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: primaryColor,
      backgroundColor: Colors.grey[900],
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: backgroundColor,
            title: const Text(
              'GoGoMarket',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.message_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          
          // Stories row
          SliverToBoxAdapter(
            child: _buildStoriesRow(),
          ),
          
          // Reels feed
          SliverToBoxAdapter(
            child: _buildReelsFeed(),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesRow() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Obx(() {
        final stories = _controller.stories;
        
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: stories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              // Add story button
              return _buildAddStoryButton();
            }
            
            final story = stories[index - 1];
            return _buildStoryCircle(story);
          },
        );
      }),
    );
  }

  Widget _buildAddStoryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (_controller.isSeller || _controller.isAdmin) {
                Get.to(() => const CreateStoryScreen());
              } else {
                Get.snackbar(
                  'Недоступно',
                  'Только продавцы могут создавать истории',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[700]!, width: 2),
              ),
              child: Icon(
                Icons.add,
                color: buttonColor,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Добавить',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCircle(Map<String, dynamic> story) {
    return GestureDetector(
      onTap: () {
        final stories = _controller.stories;
        final index = stories.indexWhere((s) => s['id'] == story['id']);
        Get.to(
          () => StoryViewerScreen(
            stories: List<Map<String, dynamic>>.from(stories),
            initialIndex: index >= 0 ? index : 0,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.purple,
                    Colors.pink,
                    Colors.orange,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor,
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  backgroundImage: story['image_url'] != null
                      ? NetworkImage(story['image_url'])
                      : null,
                  backgroundColor: Colors.grey[800],
                  child: story['image_url'] == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 70,
              child: Text(
                story['author_name'] ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReelsFeed() {
    return Obx(() {
      final reels = _controller.reels;
      
      if (reels.isEmpty) {
        return Container(
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library, size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  'Пока нет рилсов',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
                if (_controller.isSeller || _controller.isAdmin) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.to(() => const CreateReelScreen()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                    ),
                    child: const Text('Создать первый рилс'),
                  ),
                ],
              ],
            ),
          ),
        );
      }
      
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: reels.length,
        itemBuilder: (context, index) {
          final reel = reels[index];
          return _buildReelCard(reel);
        },
      );
    });
  }

  Widget _buildReelCard(Map<String, dynamic> reel) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[800],
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reel['author_name'] ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          // Video placeholder - responsive height
          LayoutBuilder(
            builder: (context, constraints) {
              final videoHeight = ResponsiveHelper.responsiveValue(
                context,
                mobile: 400.0,
                tablet: 500.0,
                desktop: 600.0,
              );
              return Container(
                height: videoHeight,
                width: double.infinity,
                color: Colors.grey[800],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text(
                        'Видео',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () => _controller.likeContent(reel['id']),
                ),
                Text(
                  '${reel['likes'] ?? 0}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  onPressed: () {},
                ),
                const Spacer(),
                // Buy button for reels with linked product (hidden for sellers)
                if (reel['product_id'] != null && !_controller.isSeller) ...[
                  ElevatedButton.icon(
                    onPressed: () => _openProductFromReel(reel),
                    icon: const Icon(Icons.shopping_cart, size: 18),
                    label: Text('buy_now'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.bookmark_border, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          // Caption
          if (reel['caption'] != null && reel['caption'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                reel['caption'],
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

    Widget _buildExploreTab() {
      return CustomScrollView(
        slivers: [
          // Search bar
          SliverAppBar(
            floating: true,
            backgroundColor: backgroundColor,
            title: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Поиск товаров и продавцов',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[500]),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: _showFilterBottomSheet,
              ),
            ],
          ),
        
          // Category chips
          SliverToBoxAdapter(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['value'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(category['label']!),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category['value']!;
                        });
                      },
                      backgroundColor: Colors.grey[900],
                      selectedColor: buttonColor!.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: isSelected ? buttonColor : Colors.grey[400],
                        fontSize: 12,
                      ),
                      checkmarkColor: buttonColor,
                      side: BorderSide(
                        color: isSelected ? buttonColor! : Colors.grey[700]!,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        
          // Sort indicator
          if (_sortBy != 'default')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.sort, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _sortOptions.firstWhere((s) => s['value'] == _sortBy)['label']!,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _sortBy = 'default';
                        });
                      },
                      child: Icon(Icons.close, size: 16, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
        
          // Products grid (Instagram Explore style)
          SliverPadding(
            padding: const EdgeInsets.all(2),
            sliver: Obx(() {
              var products = _controller.products.toList();
            
              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                products = products.where((p) {
                  final name = (p['name'] ?? '').toString().toLowerCase();
                  final description = (p['description'] ?? '').toString().toLowerCase();
                  final sellerName = (p['seller_name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      description.contains(_searchQuery) ||
                      sellerName.contains(_searchQuery);
                }).toList();
              }
            
              // Apply category filter
              if (_selectedCategory != 'all') {
                products = products.where((p) {
                  final category = (p['category'] ?? '').toString().toLowerCase();
                  return category == _selectedCategory;
                }).toList();
              }
            
              // Apply sorting
              switch (_sortBy) {
                case 'price_low':
                  products.sort((a, b) {
                    final priceA = (a['price'] ?? 0) as num;
                    final priceB = (b['price'] ?? 0) as num;
                    return priceA.compareTo(priceB);
                  });
                  break;
                case 'price_high':
                  products.sort((a, b) {
                    final priceA = (a['price'] ?? 0) as num;
                    final priceB = (b['price'] ?? 0) as num;
                    return priceB.compareTo(priceA);
                  });
                  break;
                case 'newest':
                  products.sort((a, b) {
                    final dateA = a['created_at'] ?? '';
                    final dateB = b['created_at'] ?? '';
                    return dateB.toString().compareTo(dateA.toString());
                  });
                  break;
              }
            
              if (products.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[700]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _selectedCategory != 'all'
                                ? 'Ничего не найдено'
                                : 'Пока нет товаров',
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                          if (_searchQuery.isNotEmpty || _selectedCategory != 'all') ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _selectedCategory = 'all';
                                  _sortBy = 'default';
                                });
                              },
                              child: Text(
                                'Сбросить фильтры',
                                style: TextStyle(color: buttonColor),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }
            
              // Responsive grid columns based on screen size
              final gridColumns = ResponsiveHelper.responsiveValue(
                context,
                mobile: 3,
                tablet: 4,
                desktop: 6,
              );
            
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridColumns,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = products[index];
                    return _buildProductGridItem(product);
                  },
                  childCount: products.length,
                ),
              );
            }),
          ),
        ],
      );
    }
  
    void _showFilterBottomSheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.grey[900],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Фильтры',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = 'all';
                              _sortBy = 'default';
                            });
                            setModalState(() {});
                          },
                          child: Text(
                            'Сбросить',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  
                    // Sort options
                    Text(
                      'Сортировка',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sortOptions.map((option) {
                        final isSelected = _sortBy == option['value'];
                        return ChoiceChip(
                          label: Text(option['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _sortBy = option['value']!;
                            });
                            setModalState(() {});
                          },
                          backgroundColor: Colors.grey[800],
                          selectedColor: buttonColor!.withOpacity(0.3),
                          labelStyle: TextStyle(
                            color: isSelected ? buttonColor : Colors.grey[400],
                            fontSize: 13,
                          ),
                        );
                      }).toList(),
                    ),
                  
                    const SizedBox(height: 24),
                  
                    // Category options
                    Text(
                      'Категория',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category['value'];
                        return ChoiceChip(
                          label: Text(category['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category['value']!;
                            });
                            setModalState(() {});
                          },
                          backgroundColor: Colors.grey[800],
                          selectedColor: buttonColor!.withOpacity(0.3),
                          labelStyle: TextStyle(
                            color: isSelected ? buttonColor : Colors.grey[400],
                            fontSize: 13,
                          ),
                        );
                      }).toList(),
                    ),
                  
                    const SizedBox(height: 24),
                  
                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Применить',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    Widget _buildProductGridItem(Map<String, dynamic> product) {
      return GestureDetector(
        onTap: () {
          Get.to(() => ProductDetailScreen(product: product));
        },
      child: Container(
        color: Colors.grey[900],
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (product['image_url'] != null)
              Image.network(
                product['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[800],
                  child: Icon(Icons.image, color: Colors.grey[600]),
                ),
              )
            else
              Container(
                color: Colors.grey[800],
                child: Icon(Icons.inventory_2, color: Colors.grey[600]),
              ),
            
            // Price tag
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${product['price']?.toStringAsFixed(0) ?? '0'} сум',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return Obx(() {
      if (!_controller.isSeller && !_controller.isAdmin) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey[700]),
              const SizedBox(height: 16),
              Text(
                'Только для продавцов',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Зарегистрируйтесь как продавец,\nчтобы создавать контент',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Создать',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Выберите что хотите создать',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 32),
            
            _buildCreateOption(
              icon: Icons.inventory_2,
              title: 'Товар',
              description: 'Добавьте новый товар в каталог',
              onTap: () => Get.to(() => const CreateProductScreen()),
            ),
            const SizedBox(height: 16),
            
            _buildCreateOption(
              icon: Icons.video_library,
              title: 'Рилс',
              description: 'Создайте видео о вашем товаре',
              onTap: () => Get.to(() => const CreateReelScreen()),
            ),
            const SizedBox(height: 16),
            
            _buildCreateOption(
              icon: Icons.auto_stories,
              title: 'История',
              description: 'Поделитесь моментом с покупателями',
              onTap: () => Get.to(() => const CreateStoryScreen()),
            ),
            
            const Spacer(),
            
            // My products button
            OutlinedButton.icon(
              onPressed: () => Get.to(() => const MyProductsScreen()),
              icon: const Icon(Icons.list),
              label: const Text('Мои товары'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.grey[700]!),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCreateOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: buttonColor!.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: buttonColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          backgroundColor: backgroundColor,
          title: Text(
            'Заказы',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        
        Obx(() {
          final orders = _controller.orders;
          
          if (orders.isEmpty) {
            return SliverToBoxAdapter(
              child: Container(
                height: 400,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        'Пока нет заказов',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final order = orders[index];
                return _buildOrderCard(order);
              },
              childCount: orders.length,
            ),
          );
        }),
      ],
    );
  }

    Widget _buildOrderCard(Map<String, dynamic> order) {
      final statusColors = {
        'created': Colors.blue,
        'accepted': Colors.orange,
        'ready': Colors.purple,
        'picked_up': Colors.indigo,
        'in_transit': Colors.cyan,
        'delivered': Colors.green,
        'completed': Colors.green,
        'cancelled': Colors.red,
      };
    
      final statusLabels = {
        'created': 'Создан',
        'accepted': 'Принят',
        'ready': 'Готов',
        'picked_up': 'Забран',
        'in_transit': 'В пути',
        'delivered': 'Доставлен',
        'completed': 'Завершён',
        'cancelled': 'Отменён',
      };
    
      final status = order['status'] ?? 'created';
    
      return GestureDetector(
        onTap: () => Get.to(() => OrderTrackingScreen(order: order)),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Заказ #${order['id']?.substring(0, 8) ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColors[status]?.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabels[status] ?? status,
                      style: TextStyle(
                        color: statusColors[status],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Сумма: ${order['total_amount']?.toStringAsFixed(0) ?? '0'} сум',
                style: TextStyle(color: Colors.grey[400]),
              ),
              if (order['delivery_address'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order['delivery_address'],
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    Widget _buildProfileTab() {
    return Obx(() {
      return CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: backgroundColor,
            title: Text(
              _controller.userName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => Get.to(() => const EditProfileScreen()),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await _controller.logout();
                  Get.offAll(() => const MarketplaceLoginScreen());
                },
              ),
            ],
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: _controller.userAvatar.isNotEmpty
                        ? NetworkImage(_controller.userAvatar)
                        : null,
                    child: _controller.userAvatar.isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    _controller.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: buttonColor!.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getRoleLabel(_controller.userRole),
                      style: TextStyle(
                        color: buttonColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Email
                  Text(
                    _controller.userEmail,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Товары', _controller.myProducts.length.toString()),
                      _buildStatItem('Заказы', _controller.orders.length.toString()),
                      _buildStatItem('Рилсы', _controller.reels.where((r) => r['author_id'] == _controller.userId).length.toString()),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // My Cabinet button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_isSeller) {
                          Get.to(() => const SellerCabinetScreen());
                        } else {
                          Get.to(() => const BuyerCabinetScreen());
                        }
                      },
                      icon: const Icon(Icons.dashboard),
                      label: Text('my_cabinet'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Settings button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showLanguageDialog();
                      },
                      icon: const Icon(Icons.language),
                      label: Text('language'.tr),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Nearby Sellers button (for buyers)
                  if (_isBuyer)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Get.to(() => const NearbySellersScreen()),
                        icon: const Icon(Icons.location_on),
                        label: Text('nearby_sellers'.tr),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey[700]!),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  
                  // Seller Verification button (for admin)
                  if (_controller.userRole == 'admin') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Get.to(() => const SellerVerificationScreen()),
                        icon: const Icon(Icons.verified_user),
                        label: Text('seller_verification'.tr),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey[700]!),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                    const SizedBox(height: 32),
                  
                    // Legal documents section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Документы',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildLegalLink(
                            icon: Icons.description,
                            title: 'Публичная оферта',
                            onTap: () => Get.to(() => const OfferPage()),
                          ),
                          _buildLegalLink(
                            icon: Icons.privacy_tip,
                            title: 'Политика конфиденциальности',
                            onTap: () => Get.to(() => const PrivacyPolicyPage()),
                          ),
                          _buildLegalLink(
                            icon: Icons.gavel,
                            title: 'Пользовательское соглашение',
                            onTap: () => Get.to(() => const UserAgreementPage()),
                          ),
                        ],
                      ),
                    ),
                  
                    const SizedBox(height: 24),
                  
                    // Delete Account button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Get.to(() => const DeleteAccountScreen()),
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        label: Text('delete_account'.tr, style: const TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      });
    }
  
    Widget _buildLegalLink({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[500], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
            ],
          ),
        ),
      );
    }
  
  void _showLanguageDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        title: Text('language'.tr, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇷🇺', style: TextStyle(fontSize: 24)),
              title: const Text('Русский', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.updateLocale(const Locale('ru', 'RU'));
                Get.back();
              },
            ),
            ListTile(
              leading: const Text('🇺🇿', style: TextStyle(fontSize: 24)),
              title: const Text('O\'zbekcha', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.updateLocale(const Locale('uz', 'UZ'));
                Get.back();
              },
            ),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.updateLocale(const Locale('en', 'US'));
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500]),
        ),
      ],
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'seller':
        return 'Продавец';
      case 'buyer':
        return 'Покупатель';
      case 'courier':
        return 'Курьер';
      case 'admin':
        return 'Администратор';
      default:
        return role;
    }
  }
}
