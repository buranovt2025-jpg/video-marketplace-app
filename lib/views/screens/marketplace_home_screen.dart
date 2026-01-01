import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
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
import 'package:tiktok_tutorial/views/screens/reels/reels_viewer_screen.dart';
import 'package:tiktok_tutorial/views/widgets/app_network_image.dart';
import 'package:tiktok_tutorial/utils/web_image_policy.dart';
import 'package:tiktok_tutorial/utils/formatters.dart';
import 'package:tiktok_tutorial/utils/money.dart';
import 'package:tiktok_tutorial/utils/share_utils.dart';
import 'package:tiktok_tutorial/views/screens/chat/conversations_screen.dart';
import 'package:tiktok_tutorial/views/screens/common/notifications_screen.dart';
import 'package:tiktok_tutorial/views/widgets/comments_coming_soon_sheet.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  final bool isGuestMode;
  
  const MarketplaceHomeScreen({Key? key, this.isGuestMode = false}) : super(key: key);

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  late final CartController _cartController;
  int _currentIndex = 0;
  final String _gitSha = const String.fromEnvironment('GIT_SHA', defaultValue: '');
  
  bool get _isGuestMode => widget.isGuestMode;
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
          'login_to_action'.trParams({'action': action}),
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
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }
    _cartController = Get.find<CartController>();
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
        'product_not_found'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Map<String, dynamic>? _findProductById(String productId) {
    for (final p in _controller.products) {
      if (p['id']?.toString() == productId) return p;
    }
    return null;
  }

  Future<Map<String, String>> _fetchBuildInfo() async {
    final info = <String, String>{};

    // Prefer server-provided stamps on web: version.json + .last_build_id.
    if (kIsWeb) {
      try {
        final versionUri = Uri.base.resolve('version.json');
        final r = await http.get(versionUri).timeout(const Duration(seconds: 5));
        if (r.statusCode == 200) {
          final data = jsonDecode(r.body);
          final version = data['version']?.toString();
          final build = data['build_number']?.toString();
          if (version != null && version.isNotEmpty) info['version'] = version;
          if (build != null && build.isNotEmpty) info['build_number'] = build;
        }
      } catch (_) {
        // ignore
      }

      try {
        final shaUri = Uri.base.resolve('.last_build_id');
        final r = await http.get(shaUri).timeout(const Duration(seconds: 5));
        if (r.statusCode == 200) {
          final sha = r.body.trim();
          if (sha.isNotEmpty) info['commit'] = sha;
        }
      } catch (_) {
        // ignore
      }
    } else if (_gitSha.isNotEmpty) {
      info['commit'] = _gitSha;
    }

    return info;
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
      bottomNavigationBar: _isGuestMode 
        ? _buildGuestBottomNav()
        : Obx(() => BottomNavigationBar(
            currentIndex: _safeCurrentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });

              // Important: when user opens Orders tab for the first time,
              // the list may be empty if fetchOrders wasn't called yet.
              // Fetch orders when entering the tab.
              final isOrdersTab = _isSeller ? index == 3 : index == 2;
              if (isOrdersTab && _controller.isLoggedIn) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _controller.fetchOrders();
                });
              }
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
          )),
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
            'login_to_view_orders'.tr,
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
            'welcome'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
            'login_or_register_to_shop'.tr,
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
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: backgroundColor,
          title: const Text(
            'Video Marketplace',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () => Get.to(() => const NotificationsScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.message_outlined, color: Colors.white),
              onPressed: () {
                if (_controller.isLoggedIn) {
                  Get.to(() => const ConversationsScreen());
                } else {
                  _promptLogin('chat'.tr);
                }
              },
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
                  'unavailable'.tr,
                  'only_sellers_can_create_stories'.tr,
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
          Text('add'.tr, style: const TextStyle(color: Colors.white, fontSize: 11)),
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
                      ? networkImageProviderOrNull(story['image_url'])
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
                  'no_reels_yet'.tr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
                if (_controller.isSeller || _controller.isAdmin) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.to(() => const CreateReelScreen()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                    ),
                    child: Text('create_first_reel'.tr),
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
          return _buildReelCard(reel, index: index);
        },
      );
    });
  }

  Widget _buildReelCard(Map<String, dynamic> reel, {required int index}) {
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
              final width = constraints.maxWidth;
              final videoHeight = (width * 16 / 9).clamp(280.0, 640.0);
              final thumbUrl = reel['thumbnail_url']?.toString();
              return Container(
                height: videoHeight,
                width: double.infinity,
                color: Colors.grey[850],
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumbUrl != null && thumbUrl.trim().isNotEmpty)
                      AppNetworkImage(
                        url: thumbUrl,
                        fit: BoxFit.cover,
                        errorWidget: Center(
                          child: Icon(Icons.video_library, size: 48, color: Colors.grey[600]),
                        ),
                      )
                    else
                      Center(
                        child: Icon(Icons.video_library, size: 48, color: Colors.grey[600]),
                      ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '${asInt(reel['likes_count'] ?? reel['likes'] ?? 0)}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                  onPressed: () => _controller.toggleLikeOnReel(reel['id']?.toString() ?? ''),
                ),
                Text(
                  '${asInt(reel['likes_count'] ?? reel['likes'] ?? 0)}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined, color: Colors.white),
                  onPressed: () {
                    Get.bottomSheet(
                      CommentsComingSoonSheet(reel: reel),
                      isScrollControlled: true,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  onPressed: () async {
                    await copyToClipboardWithToast(buildReelShareText(reel));
                  },
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    final reels = List<Map<String, dynamic>>.from(_controller.reels);
                    Get.to(() => ReelsViewerScreen(reels: reels, initialIndex: index));
                  },
                  child: Text('watch'.tr, style: const TextStyle(color: Colors.white)),
                ),
                // Buy button for reels with linked product
                if (reel['product_id'] != null) ...[
                  IconButton(
                    onPressed: () {
                      final productId = reel['product_id']?.toString() ?? '';
                      final p = productId.trim().isEmpty ? null : _findProductById(productId);
                      if (p == null) {
                        _openProductFromReel(reel);
                        return;
                      }
                      _cartController.addToCart(p, quantity: 1);
                      Get.snackbar(
                        'added'.tr,
                        'added_to_cart_named'.trParams({'name': (p['name'] ?? '').toString()}),
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                    tooltip: 'add_to_cart'.tr,
                  ),
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
                  onPressed: () {
                    Get.snackbar(
                      'coming_soon'.tr,
                      'favorites_coming_soon'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
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
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'search_products_and_sellers'.tr,
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                child: Container(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 64, color: Colors.grey[700]),
                        const SizedBox(height: 16),
                        Text(
                          'no_products'.tr,
                          style: TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
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
            AppNetworkImage(
              url: product['image_url']?.toString(),
              fit: BoxFit.cover,
              errorWidget: Container(
                color: Colors.grey[800],
                child: Icon(Icons.inventory_2, color: Colors.grey[600]),
              ),
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
                  formatMoneyWithCurrency(product['price']),
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
                'sellers_only'.tr,
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'register_as_seller_to_create_content'.tr,
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
            Text(
              'create'.tr,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'choose_what_to_create'.tr,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 32),
            
            _buildCreateOption(
              icon: Icons.inventory_2,
              title: 'create_option_product_title'.tr,
              description: 'create_option_product_desc'.tr,
              onTap: () => Get.to(() => const CreateProductScreen()),
            ),
            const SizedBox(height: 16),
            
            _buildCreateOption(
              icon: Icons.video_library,
              title: 'create_option_reel_title'.tr,
              description: 'create_option_reel_desc'.tr,
              onTap: () => Get.to(() => const CreateReelScreen()),
            ),
            const SizedBox(height: 16),
            
            _buildCreateOption(
              icon: Icons.auto_stories,
              title: 'create_option_story_title'.tr,
              description: 'create_option_story_desc'.tr,
              onTap: () => Get.to(() => const CreateStoryScreen()),
            ),
            
            const Spacer(),
            
            // My products button
            OutlinedButton.icon(
              onPressed: () => Get.to(() => const MyProductsScreen()),
              icon: const Icon(Icons.list),
              label: Text('my_products'.tr),
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
        SliverAppBar(
          floating: true,
          backgroundColor: backgroundColor,
          title: Text('orders'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _controller.isLoggedIn ? _controller.fetchOrders : null,
              tooltip: 'refresh'.tr,
            ),
          ],
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
                        'no_orders'.tr,
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _controller.isLoggedIn ? _controller.fetchOrders : null,
                        icon: const Icon(Icons.refresh),
                        label: Text('refresh'.tr),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey[700]!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          
          return SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: () async {
                if (_controller.isLoggedIn) {
                  await _controller.fetchOrders();
                }
              },
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildOrderCard(order);
                },
              ),
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
    
      final status = order['status'] ?? 'created';
    
      final orderIdStr = (order['id'] ?? '').toString();
      final orderIdShort = orderIdStr.length > 8 ? orderIdStr.substring(0, 8) : orderIdStr;
      final totalAmountNum = (order['total_amount'] is num) ? (order['total_amount'] as num) : 0;

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
                    'order_number_short'.trParams({'id': orderIdShort}),
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
                      _getOrderStatusLabel(status.toString()),
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
                '${'amount'.tr}: ${formatMoneyWithCurrency(totalAmountNum)}',
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
                        ? networkImageProviderOrNull(_controller.userAvatar)
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

                  // Build / version stamp (hotfix debug)
                  const SizedBox(height: 8),
                  FutureBuilder<Map<String, String>>(
                    future: _fetchBuildInfo(),
                    builder: (context, snap) {
                      final info = snap.data ?? const <String, String>{};
                      final version = info['version'];
                      final build = info['build_number'];
                      final commit = info['commit'];

                      final parts = <String>[];
                      if (version != null && version.isNotEmpty) {
                        parts.add('v$version${build != null && build.isNotEmpty ? '+$build' : ''}');
                      }
                      if (commit != null && commit.isNotEmpty) {
                        parts.add('commit ${commit.length > 8 ? commit.substring(0, 8) : commit}');
                      }

                      if (parts.isEmpty) return const SizedBox.shrink();

                      return Text(
                        parts.join(' • '),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('products'.tr, _controller.myProducts.length.toString()),
                      _buildStatItem('orders'.tr, _controller.orders.length.toString()),
                      _buildStatItem('reels'.tr, _controller.reels.where((r) => r['author_id'] == _controller.userId).length.toString()),
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
              title: Text('russian'.tr, style: const TextStyle(color: Colors.white)),
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
        return 'seller'.tr;
      case 'buyer':
        return 'buyer'.tr;
      case 'courier':
        return 'courier'.tr;
      case 'admin':
        return 'admin'.tr;
      default:
        return role;
    }
  }

  String _getOrderStatusLabel(String status) {
    switch (status) {
      case 'created':
        return 'status_created'.tr;
      case 'accepted':
        return 'status_accepted'.tr;
      case 'ready':
        return 'status_ready'.tr;
      case 'picked_up':
        return 'status_picked_up'.tr;
      case 'in_transit':
        return 'status_in_transit'.tr;
      case 'delivered':
        return 'status_delivered'.tr;
      case 'completed':
        return 'status_completed'.tr;
      case 'cancelled':
        return 'status_cancelled'.tr;
      default:
        return status;
    }
  }
}
