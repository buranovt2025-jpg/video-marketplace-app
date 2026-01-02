import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/controllers/favorites_controller.dart';
import 'package:tiktok_tutorial/utils/responsive_helper.dart';
import 'package:tiktok_tutorial/ui/app_ui.dart';
import 'package:tiktok_tutorial/ui/app_media.dart';
import 'package:tiktok_tutorial/views/screens/seller/create_product_screen.dart';
import 'package:tiktok_tutorial/views/screens/seller/create_reel_screen.dart';
import 'package:tiktok_tutorial/views/screens/seller/create_story_screen.dart';
import 'package:tiktok_tutorial/views/screens/seller/my_products_screen.dart';
import 'package:tiktok_tutorial/views/screens/auth/marketplace_login_screen.dart';
import 'package:tiktok_tutorial/views/screens/buyer/product_detail_screen.dart';
import 'package:tiktok_tutorial/views/screens/buyer/seller_products_screen.dart';
import 'package:tiktok_tutorial/views/screens/buyer/cart_screen.dart';
import 'package:tiktok_tutorial/views/screens/buyer/favorites_screen.dart';
import 'package:tiktok_tutorial/views/screens/buyer/order_history_screen.dart';
import 'package:tiktok_tutorial/views/screens/buyer/smart_search_screen.dart';
import 'package:tiktok_tutorial/views/screens/buyer/order_tracking_screen.dart';
import 'package:tiktok_tutorial/views/screens/chat/chat_screen.dart';
import 'package:tiktok_tutorial/views/screens/profile/edit_profile_screen.dart';
import 'package:tiktok_tutorial/views/screens/stories/story_viewer_screen.dart';
import 'package:tiktok_tutorial/views/screens/cabinets/seller_cabinet_screen.dart';
import 'package:tiktok_tutorial/views/screens/cabinets/buyer_cabinet_screen.dart';
import 'package:tiktok_tutorial/views/screens/buyer/nearby_sellers_screen.dart';
import 'package:tiktok_tutorial/views/screens/common/delete_account_screen.dart';
import 'package:tiktok_tutorial/views/screens/admin/seller_verification_screen.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  final bool isGuestMode;
  
  const MarketplaceHomeScreen({Key? key, this.isGuestMode = false}) : super(key: key);

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  int _currentIndex = 0;
  bool _didScheduleDeferredLoad = false;
  
  bool get _isGuestMode => widget.isGuestMode;
  bool get _isSeller => !_isGuestMode && _controller.currentUser.value?['role'] == 'seller';
  bool get _isBuyer => _isGuestMode || _controller.currentUser.value?['role'] == 'buyer';
  
  // Get max valid index based on role (Guest mode = 3 tabs like buyer)
  int get _maxIndex => _isSeller ? 4 : 2; // Seller: 5 tabs (0-4), Buyer/Guest: 3 tabs (0-2)
  
  // Ensure currentIndex is within bounds
  int get _safeCurrentIndex => _currentIndex > _maxIndex ? _maxIndex : _currentIndex;
  
  // Helper to prompt login for protected actions
  void _promptLogin(String action) {
    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        title: Text('login_required'.tr, style: AppUI.h2),
        content: Text(
          'Войдите, чтобы $action',
          style: AppUI.muted,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: AppUI.muted),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.to(() => const MarketplaceLoginScreen());
            },
            style: AppUI.primaryButton(),
            child: Text('login'.tr),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCriticalData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_didScheduleDeferredLoad) return;
      _didScheduleDeferredLoad = true;
      _loadDeferredData();
    });
  }

  Future<void> _loadCriticalData() async {
    // Stories should appear ASAP (top-most content for buyer/guest).
    await _controller.fetchStories();
  }

  Future<void> _loadDeferredData() async {
    // Defer non-critical requests to reduce long tasks before first frame.
    final futures = <Future<void>>[
      _controller.fetchProducts(),
      _controller.fetchReels(perPage: 8),
      if (_controller.isLoggedIn) _controller.fetchOrders(),
    ];
    await Future.wait(futures);
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
      body: _isGuestMode 
        ? _buildGuestModeBody()
        : Obx(() {
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
              // Buyer/Guest: simplified bottom nav (Feed / Reels / Profile)
              return IndexedStack(
                index: _safeCurrentIndex,
                children: [
                  _buildFeedTab(),
                  _buildReelsTab(),
                  _buildProfileTab(),
                ],
              );
            }
          }),
      bottomNavigationBar: _isGuestMode 
        ? _buildGuestBottomNav()
        : Obx(() => BottomNavigationBar(
            currentIndex: _safeCurrentIndex,
            onTap: (index) {
              // Ensure Reels tab is truly "Reels-only" and has data.
              if (!_isSeller && index == 1) {
                if (_controller.reels.isEmpty) {
                  _controller.fetchReels(perPage: 10);
                }
                if (_controller.products.isEmpty) {
                  _controller.fetchProducts();
                }
              }
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
                icon: const Icon(Icons.play_circle_outline),
                label: 'reels'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: 'profile'.tr,
              ),
            ],
          )),
    );
  }
  
  // Guest mode body - shows feed/reels/profile without login
  Widget _buildGuestModeBody() {
    return IndexedStack(
      index: _safeCurrentIndex,
      children: [
        _buildFeedTab(),
        _buildReelsTab(),
        _buildGuestProfileTab(),
      ],
    );
  }
  
  // Guest mode bottom navigation
  Widget _buildGuestBottomNav() {
    return BottomNavigationBar(
      currentIndex: _safeCurrentIndex,
      onTap: (index) {
        // Ensure Reels tab is truly "Reels-only" and has data.
        if (index == 1) {
          if (_controller.reels.isEmpty) {
            _controller.fetchReels(perPage: 10);
          }
          if (_controller.products.isEmpty) {
            _controller.fetchProducts();
          }
        }
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
          icon: const Icon(Icons.play_circle_outline),
          label: 'reels'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: 'profile'.tr,
        ),
      ],
    );
  }
  
  // Guest profile tab - shows login/register options
  Widget _buildGuestProfileTab() {
    return Center(
      child: Padding(
        padding: AppUI.pagePadding,
        child: Container(
          width: double.infinity,
          padding: AppUI.cardPadding,
          decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: Colors.white.withOpacity(0.08),
                child: Icon(Icons.person_outline, size: 54, color: Colors.white.withOpacity(0.5)),
              ),
              const SizedBox(height: 18),
              Text('Добро пожаловать!', style: AppUI.h1),
              const SizedBox(height: 10),
              Text(
                'Войдите или зарегистрируйтесь,\nчтобы делать покупки',
                style: AppUI.muted.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.to(() => const MarketplaceLoginScreen()),
                  style: AppUI.primaryButton(),
                  child: Text('login'.tr),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.to(() => const MarketplaceLoginScreen()),
                  style: AppUI.outlineButton().copyWith(
                    foregroundColor: const WidgetStatePropertyAll(primaryColor),
                    side: WidgetStatePropertyAll(BorderSide(color: primaryColor.withOpacity(0.6))),
                  ),
                  child: Text('register'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: backgroundColor,
          title: Text('GoGoMarket', style: AppUI.h2),
          bottom: (!_isSeller)
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(110),
                  child: _buildStoriesRow(),
                )
              : null,
          actions: [
            // Search moved out of bottom nav for buyers/guests.
            if (!_isSeller)
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => Get.to(() => const SmartSearchScreen()),
              ),
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
        
        // Stories row moved into AppBar for buyer/guest (top-most content).
        if (_isSeller)
          SliverToBoxAdapter(
            child: _buildStoriesRow(),
          ),

        // Products section (buyer-friendly home)
        SliverToBoxAdapter(
          child: _buildProductsSection(),
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    return Obx(() {
      final products = _controller.products;

      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Товары', style: AppUI.h2),
                  ),
                  TextButton(
                    onPressed: () => Get.to(() => const SmartSearchScreen()),
                    child: Text(
                      'Все',
                      style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: AppUI.cardPadding,
                  decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Каталог пуст', style: AppUI.h2),
                      const SizedBox(height: 6),
                      Text('Попробуйте позже — товары появятся здесь', style: AppUI.muted),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 244,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length > 10 ? 10 : products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildHomeProductCard(product);
                  },
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildHomeProductCard(Map<String, dynamic> product) {
    final rawPrice = product['price'];
    final priceText = rawPrice is num ? rawPrice.toStringAsFixed(0) : (rawPrice?.toString() ?? '0');

    return InkWell(
      onTap: () => Get.to(() => ProductDetailScreen(product: product)),
      borderRadius: BorderRadius.circular(AppUI.radiusL),
      child: Container(
        width: 190,
        decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppUI.radiusL)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  color: surfaceColor,
                  child: product['image_url'] != null
                      ? AppMedia.image(
                          product['image_url'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Center(
                          child: Icon(Icons.inventory_2, color: Colors.white.withOpacity(0.35)),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (product['name'] ?? 'Товар').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$priceText сум',
                    style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Get.to(() => ProductDetailScreen(product: product)),
                      style: AppUI.outlineButton().copyWith(
                        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 10, horizontal: 12)),
                      ),
                      child: const Text('Подробнее'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReelsTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: backgroundColor,
          title: Text(
            'reels'.tr,
            style: AppUI.h2,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => Get.to(() => const SmartSearchScreen()),
            ),
          ],
        ),
        Obx(() {
          final reels = _controller.reels;
          if (reels.isEmpty) {
            return SliverToBoxAdapter(child: _buildReelsEmptyState());
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildReelCard(reels[index]),
              childCount: reels.length,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStoriesRow() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Obx(() {
        final stories = _controller.stories;
        
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          InkWell(
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
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.18), width: 2),
              ),
              child: const Icon(Icons.add, color: primaryColor, size: 30),
            ),
          ),
          const SizedBox(height: 4),
          Text('Добавить', style: AppUI.muted.copyWith(fontSize: 11)),
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
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    accentColor,
                    Colors.white.withOpacity(0.85),
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
                style: AppUI.muted.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReelsFeed({int? limit}) {
    return Obx(() {
      final reels = _controller.reels;
      
      if (reels.isEmpty) {
        return _buildReelsEmptyState();
      }
      
      final count = limit == null ? reels.length : (reels.length > limit ? limit : reels.length);
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (context, index) {
          final reel = reels[index];
          return _buildReelCard(reel);
        },
      );
    });
  }

  Widget _buildReelsEmptyState() {
    return SizedBox(
      height: 320,
      child: Center(
        child: Padding(
          padding: AppUI.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, size: 64, color: Colors.white.withOpacity(0.25)),
              const SizedBox(height: 16),
              Text('Пока нет рилсов', style: AppUI.h2.copyWith(color: Colors.white.withOpacity(0.9))),
              const SizedBox(height: 8),
              Text('Попробуйте позже — здесь появятся видео от продавцов', style: AppUI.muted, textAlign: TextAlign.center),
              if (_controller.isSeller || _controller.isAdmin) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.to(() => const CreateReelScreen()),
                  style: AppUI.primaryButton(),
                  child: const Text('Создать первый рилс'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReelCard(Map<String, dynamic> reel) {
    final productId = reel['product_id'];
    final Map<String, dynamic> linkedProduct = productId == null
        ? const <String, dynamic>{}
        : _controller.products.firstWhere(
            (p) => p['id'] == productId,
            orElse: () => <String, dynamic>{},
          );

    final thumbUrl = reel['thumbnail_url'] ?? reel['image_url'];
    final likesCount = reel['likes_count'] ?? reel['likes'] ?? 0;
    final commentsCount = reel['comments_count'] ?? 0;
    final caption = (reel['caption'] ?? '').toString();
    final sellerId = (linkedProduct['seller_id'] ?? reel['author_id'] ?? reel['seller_id'])?.toString();
    final sellerName = (linkedProduct['seller_name'] ?? reel['author_name'] ?? 'seller'.tr).toString();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: AppUI.cardPadding,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reel['author_name'] ?? 'User',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text('GoGoMarket', style: AppUI.muted.copyWith(fontSize: 11)),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppUI.radiusL),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 9 / 16,
                    child: Container(
                      color: surfaceColor,
                      child: thumbUrl != null
                          ? AppMedia.image(
                              thumbUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                size: 74,
                                color: Colors.white.withOpacity(0.28),
                              ),
                            ),
                    ),
                  ),
                  // subtle gradient for overlay readability
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Play icon overlay
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.10)),
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                  // Linked product badge
                  if (linkedProduct.isNotEmpty)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 210),
                              child: Text(
                                linkedProduct['name'] ?? 'Товар',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Quick stats
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Row(
                      children: [
                        _buildReelStatChip(icon: Icons.favorite, value: '$likesCount', color: Colors.redAccent),
                        const SizedBox(width: 8),
                        _buildReelStatChip(icon: Icons.chat_bubble_outline, value: '$commentsCount'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _buildReelAction(
                  icon: Icons.favorite_border,
                  label: '$likesCount',
                  onTap: () => _controller.likeContent(reel['id']),
                ),
                const SizedBox(width: 10),
                _buildReelAction(
                  icon: Icons.comment_outlined,
                  label: '$commentsCount',
                  onTap: () {},
                ),
                const SizedBox(width: 10),
                _buildReelAction(
                  icon: Icons.share_outlined,
                  label: 'share'.tr,
                  onTap: () {},
                ),
                const Spacer(),
                // Buy / Seller / Share quick actions for reels with linked product
                if (linkedProduct.isNotEmpty) ...[
                  ElevatedButton.icon(
                    onPressed: () => _openProductFromReel(reel),
                    icon: const Icon(Icons.shopping_cart, size: 18),
                    label: Text('buy_now'.tr),
                    style: AppUI.primaryButton().copyWith(
                      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (sellerId != null && sellerId.isNotEmpty) ...[
                    OutlinedButton.icon(
                      onPressed: () => Get.to(
                        () => SellerProductsScreen(
                          sellerId: sellerId,
                          sellerName: sellerName,
                        ),
                      ),
                      icon: const Icon(Icons.store, size: 18),
                      label: Text('seller'.tr),
                      style: AppUI.outlineButton().copyWith(
                        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                        foregroundColor: const WidgetStatePropertyAll(primaryColor),
                        side: WidgetStatePropertyAll(BorderSide(color: primaryColor.withOpacity(0.6))),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: () {
                      // Minimal share: copy identifier (works on web/mobile without extra deps).
                      // TODO: replace with share_plus when backend provides shareable URLs.
                      final id = (linkedProduct['id'] ?? reel['id'] ?? '').toString();
                      _copyToClipboard('GoGoMarket: $id');
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: Text('share'.tr),
                    style: AppUI.outlineButton().copyWith(
                      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Caption
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                caption,
                style: AppUI.body.copyWith(color: Colors.white.withOpacity(0.9)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReelAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReelStatChip({
    required IconData icon,
    required String value,
    Color color = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    try {
      // Clipboard is available on web/mobile.
      // ignore: avoid_web_libraries_in_flutter
      await Clipboard.setData(ClipboardData(text: text));
      Get.snackbar(
        'success'.tr,
        'Скопировано',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    } catch (_) {
      // No-op
    }
  }

  Widget _buildExploreTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: backgroundColor,
          title: InkWell(
            onTap: () => Get.to(() => const SmartSearchScreen()),
            borderRadius: BorderRadius.circular(AppUI.radiusM),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: AppUI.inputDecoration(),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.white.withOpacity(0.55)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Поиск товаров и продавцов',
                      style: AppUI.muted,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Products grid (Instagram Explore style)
        SliverPadding(
          padding: const EdgeInsets.all(2),
          sliver: Obx(() {
            final products = _controller.products;
            
            if (products.isEmpty) {
              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 320,
                  child: Center(
                    child: Padding(
                      padding: AppUI.pagePadding,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2, size: 64, color: Colors.white.withOpacity(0.22)),
                          const SizedBox(height: 16),
                          Text('Пока нет товаров', style: AppUI.h2.copyWith(color: Colors.white.withOpacity(0.9))),
                          const SizedBox(height: 8),
                          Text('Зайдите позже — каталог обновляется', style: AppUI.muted, textAlign: TextAlign.center),
                        ],
                      ),
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

  Widget _buildProductGridItem(Map<String, dynamic> product) {
    final rawPrice = product['price'];
    final priceText = rawPrice is num ? rawPrice.toStringAsFixed(0) : (rawPrice?.toString() ?? '0');

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailScreen(product: product)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppUI.radiusM),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: surfaceColor),
            if (product['image_url'] != null)
              AppMedia.image(product['image_url'], fit: BoxFit.cover)
            else
              Center(
                child: Icon(Icons.inventory_2, color: Colors.white.withOpacity(0.35)),
              ),
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Text(
                  '$priceText сум',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
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
          child: Padding(
            padding: AppUI.pagePadding,
            child: Container(
              width: double.infinity,
              padding: AppUI.cardPadding,
              decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 56, color: Colors.white.withOpacity(0.28)),
                  const SizedBox(height: 14),
                  Text('Только для продавцов', style: AppUI.h2),
                  const SizedBox(height: 8),
                  Text(
                    'Зарегистрируйтесь как продавец,\nчтобы создавать контент',
                    style: AppUI.muted,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }
      
      return Padding(
        padding: AppUI.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text('Создать', style: AppUI.h1),
            const SizedBox(height: 8),
            Text('Выберите что хотите создать', style: AppUI.muted),
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
              style: AppUI.outlineButton(),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppUI.radiusL),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(AppUI.radiusM),
              ),
              child: Icon(icon, color: primaryColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppUI.h2.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppUI.muted.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.35), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: backgroundColor,
          title: Text('Заказы', style: AppUI.h2),
        ),
        
        Obx(() {
          final orders = _controller.orders;
          
          if (orders.isEmpty) {
            return SliverToBoxAdapter(
              child: SizedBox(
                height: 320,
                child: Center(
                  child: Padding(
                    padding: AppUI.pagePadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.white.withOpacity(0.22)),
                        const SizedBox(height: 16),
                        Text('Пока нет заказов', style: AppUI.h2.copyWith(color: Colors.white.withOpacity(0.9))),
                        const SizedBox(height: 8),
                        Text('Когда появятся — они будут здесь', style: AppUI.muted, textAlign: TextAlign.center),
                      ],
                    ),
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
    
      final rawAmount = order['total_amount'];
      final amountText = rawAmount is num ? rawAmount.toStringAsFixed(0) : (rawAmount?.toString() ?? '0');
      
      return GestureDetector(
        onTap: () => Get.to(() => OrderTrackingScreen(order: order)),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColors[status]?.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabels[status] ?? status,
                      style: TextStyle(
                        color: statusColors[status],
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Сумма: $amountText сум',
                style: AppUI.muted,
              ),
              if (order['delivery_address'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.white.withOpacity(0.45)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order['delivery_address'],
                        style: AppUI.muted.copyWith(fontSize: 12),
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
              'profile'.tr,
              style: AppUI.h2,
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
              padding: AppUI.pagePadding,
              child: Column(
                children: [
                  // Header card (avatar + identity)
                  Container(
                    width: double.infinity,
                    padding: AppUI.cardPadding,
                    decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          backgroundImage: _controller.userAvatar.isNotEmpty
                              ? NetworkImage(_controller.userAvatar)
                              : null,
                          child: _controller.userAvatar.isEmpty
                              ? const Icon(Icons.person, size: 26, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_controller.userName, style: AppUI.h2),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: primaryColor.withOpacity(0.35)),
                                    ),
                                    child: Text(
                                      _getRoleLabel(_controller.userRole),
                                      style: const TextStyle(
                                        color: primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(_controller.userEmail, style: AppUI.muted),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  
                  // Stats row
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
                    child: Builder(
                      builder: (context) {
                        final favoritesController = Get.find<FavoritesController>();
                        final cartController = Get.find<CartController>();

                        final buyerOrdersCount = _controller.orders
                            .where((o) => o['buyer_id'] == _controller.userId)
                            .length;

                        final sellerOrdersCount = _controller.orders
                            .where((o) => o['seller_id'] == _controller.userId)
                            .length;

                        final myReelsCount = _controller.reels
                            .where((r) => r['author_id'] == _controller.userId)
                            .length;

                        if (_isBuyer) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem('orders'.tr, buyerOrdersCount.toString()),
                              _buildStatItem('favorites'.tr, favoritesController.count.toString()),
                              _buildStatItem('cart'.tr, cartController.itemCount.toString()),
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem('Товары', _controller.myProducts.length.toString()),
                            _buildStatItem('orders'.tr, sellerOrdersCount.toString()),
                            _buildStatItem('reels'.tr, myReelsCount.toString()),
                          ],
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Buyer: Orders entry point (Orders moved out of bottom nav)
                  if (_isBuyer) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Get.to(() => const OrderHistoryScreen()),
                        icon: const Icon(Icons.receipt_long),
                        label: Text('orders'.tr),
                        style: AppUI.primaryButton(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Get.to(() => const FavoritesScreen()),
                            icon: const Icon(Icons.favorite_border),
                            label: Text('favorites'.tr),
                            style: AppUI.outlineButton(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Get.to(() => const CartScreen()),
                            icon: const Icon(Icons.shopping_cart_outlined),
                            label: Text('cart'.tr),
                            style: AppUI.outlineButton(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  
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
                      style: AppUI.primaryButton(),
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
                      style: AppUI.outlineButton(),
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
                        style: AppUI.outlineButton(),
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
                        style: AppUI.outlineButton(),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
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
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppUI.muted.copyWith(fontSize: 12),
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
