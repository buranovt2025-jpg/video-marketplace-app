import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
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
import 'package:tiktok_tutorial/views/screens/reels/reels_viewer_screen.dart';
import 'package:tiktok_tutorial/views/screens/common/report_content_screen.dart';
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
  final Set<String> _likedReelIds = <String>{};
  final Map<String, int> _reelLikeOverrides = <String, int>{};
  final Set<String> _viewedStoryIds = <String>{};
  final Set<String> _savedReelIds = <String>{};
  String? _feedBigHeartReelId;
  bool _feedBigHeartVisible = false;
  
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

  int _likesFromReel(Map<String, dynamic> reel) {
    final raw = reel['likes'] ?? reel['likes_count'] ?? 0;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 0;
  }

  void _toggleReelLike(Map<String, dynamic> reel) {
    final contentId = reel['id']?.toString();
    if (contentId == null || contentId.isEmpty) return;

    final baseLikes = _reelLikeOverrides[contentId] ?? _likesFromReel(reel);
    final isLiked = _likedReelIds.contains(contentId);
    final nextLiked = !isLiked;
    final nextLikes = (baseLikes + (nextLiked ? 1 : -1)).clamp(0, 1 << 30);

    setState(() {
      if (nextLiked) {
        _likedReelIds.add(contentId);
      } else {
        _likedReelIds.remove(contentId);
      }
      _reelLikeOverrides[contentId] = nextLikes;
    });

    _controller.likeContent(contentId);
  }

  String _shareTextForReel(Map<String, dynamic> reel) {
    final id = reel['id']?.toString();
    final videoUrl = (reel['video_url'] ?? reel['media_url'])?.toString();
    if (videoUrl != null && videoUrl.isNotEmpty) return videoUrl;
    if (id != null && id.isNotEmpty) return 'reel:$id';
    return 'reel';
  }

  Future<void> _copyReelLink(Map<String, dynamic> reel) async {
    final text = _shareTextForReel(reel);
    await Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Готово',
      'Ссылка скопирована',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  void _openReelCommentsStub() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Комментарии',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'Скоро добавим комментарии для рилсов в marketplace.',
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.check),
                  label: const Text('Ок'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _openReelMoreSheet(Map<String, dynamic> reel) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.link, color: Colors.white),
                title: const Text('Скопировать ссылку', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Get.back();
                  await _copyReelLink(reel);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined, color: Colors.redAccent),
                title: const Text('Пожаловаться', style: TextStyle(color: Colors.white)),
                onTap: () {
                  final id = reel['id']?.toString();
                  if (id == null || id.isEmpty) return;
                  Get.back();
                  Get.to(() => ReportContentScreen(contentId: id, contentType: 'reel'));
                },
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey[700]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Отмена'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _toggleReelSaved(Map<String, dynamic> reel) {
    final id = reel['id']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() {
      if (_savedReelIds.contains(id)) {
        _savedReelIds.remove(id);
      } else {
        _savedReelIds.add(id);
      }
    });
    Get.snackbar(
      'Сохранено',
      _savedReelIds.contains(id) ? 'Добавлено в сохранённые' : 'Убрано из сохранённых',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  void _flashFeedBigHeart(String reelId) {
    setState(() {
      _feedBigHeartReelId = reelId;
      _feedBigHeartVisible = true;
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _feedBigHeartVisible = false;
        // keep last id to avoid layout jumps; just hide opacity
      });
    });
  }

  void _likeReelFromDoubleTap(Map<String, dynamic> reel) {
    final contentId = reel['id']?.toString();
    if (contentId == null || contentId.isEmpty) return;

    final isLiked = _likedReelIds.contains(contentId);
    if (!isLiked) {
      final baseLikes = _reelLikeOverrides[contentId] ?? _likesFromReel(reel);
      final nextLikes = (baseLikes + 1).clamp(0, 1 << 30);
      setState(() {
        _likedReelIds.add(contentId);
        _reelLikeOverrides[contentId] = nextLikes;
      });
      _controller.likeContent(contentId);
    }

    _flashFeedBigHeart(contentId);
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
    final storyId = story['id']?.toString();
    final isViewed = storyId != null && _viewedStoryIds.contains(storyId);
    final authorAvatar = story['author_avatar']?.toString();
    final hasVideo = (story['video_url']?.toString().isNotEmpty ?? false);

    return GestureDetector(
      onTap: () {
        final stories = _controller.stories;
        final index = stories.indexWhere((s) => s['id'] == story['id']);
        final storiesList = List<Map<String, dynamic>>.from(stories);
        Get.to(
          () => StoryViewerScreen(
            stories: storiesList,
            initialIndex: index >= 0 ? index : 0,
            onIndexChanged: (i) {
              if (i < 0 || i >= storiesList.length) return;
              final id = storiesList[i]['id']?.toString();
              if (id == null || id.isEmpty) return;
              setState(() => _viewedStoryIds.add(id));
            },
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
                gradient: isViewed
                    ? null
                    : const LinearGradient(
                        colors: [
                          Colors.purple,
                          Colors.pink,
                          Colors.orange,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: isViewed ? Border.all(color: Colors.grey[700]!, width: 2) : null,
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor,
                ),
                padding: const EdgeInsets.all(2),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircleAvatar(
                      backgroundImage: (authorAvatar != null && authorAvatar.isNotEmpty)
                          ? NetworkImage(authorAvatar)
                          : null,
                      backgroundColor: Colors.grey[800],
                      child: (authorAvatar == null || authorAvatar.isEmpty)
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    if (hasVideo)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                        ),
                      ),
                  ],
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
          return _buildReelCard(reel, index: index);
        },
      );
    });
  }

  Widget _buildReelCard(Map<String, dynamic> reel, {required int index}) {
    return GestureDetector(
      onTap: () async {
        final reels = List<Map<String, dynamic>>.from(_controller.reels);
        await Get.to(() => ReelsViewerScreen(reels: reels, initialIndex: index));
      },
      onDoubleTap: () => _likeReelFromDoubleTap(reel),
      child: Container(
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
                    child: Text(
                      reel['author_name'] ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () => _openReelMoreSheet(reel),
                  ),
                ],
              ),
            ),

            // Preview (tap to open fullscreen viewer)
            LayoutBuilder(
              builder: (context, constraints) {
                final videoHeight = ResponsiveHelper.responsiveValue(
                  context,
                  mobile: 420.0,
                  tablet: 520.0,
                  desktop: 620.0,
                );
                final thumbUrl = reel['thumbnail_url']?.toString();
                final hasProduct = reel['product_id'] != null;
                final contentId = reel['id']?.toString();
                final likes = contentId == null
                    ? _likesFromReel(reel)
                    : (_reelLikeOverrides[contentId] ?? _likesFromReel(reel));
                final caption = (reel['caption'] ?? '').toString().trim();
                return Container(
                  height: videoHeight,
                  width: double.infinity,
                  color: Colors.black,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (thumbUrl != null && thumbUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: Image.network(
                            thumbUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                          ),
                        )
                      else
                        Container(color: Colors.grey[900]),

                      // Bottom gradient for readability (IG-like)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.15),
                                  Colors.black.withOpacity(0.55),
                                ],
                                stops: const [0.55, 0.75, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Big heart on double tap (IG-like)
                      Center(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: (_feedBigHeartVisible && _feedBigHeartReelId == contentId) ? 1 : 0,
                            duration: const Duration(milliseconds: 140),
                            child: AnimatedScale(
                              scale: (_feedBigHeartVisible && _feedBigHeartReelId == contentId) ? 1.0 : 0.8,
                              duration: const Duration(milliseconds: 140),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white70,
                                size: 110,
                              ),
                            ),
                          ),
                        ),
                      ),

                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 34),
                        ),
                      ),

                      // Top-left badges
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Row(
                          children: [
                            if (hasProduct)
                              _Badge(
                                icon: Icons.shopping_bag_outlined,
                                text: 'Товар',
                              ),
                            if (hasProduct) const SizedBox(width: 8),
                            _Badge(
                              icon: Icons.favorite,
                              text: '$likes',
                              iconColor: Colors.red[300],
                            ),
                          ],
                        ),
                      ),

                      // Bottom caption hint
                      if (caption.isNotEmpty)
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Text(
                            caption,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                  Builder(
                    builder: (context) {
                      final contentId = reel['id']?.toString();
                      final isLiked = contentId != null && _likedReelIds.contains(contentId);
                      final likes = contentId == null
                          ? _likesFromReel(reel)
                          : (_reelLikeOverrides[contentId] ?? _likesFromReel(reel));

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red[300] : Colors.white,
                            ),
                            onPressed: () => _toggleReelLike(reel),
                          ),
                          Text(
                            '$likes',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.comment_outlined, color: Colors.white),
                    onPressed: _openReelCommentsStub,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed: () => _copyReelLink(reel),
                  ),
                  const Spacer(),
                  // Buy button for reels with linked product
                  if (reel['product_id'] != null) ...[
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
                  Builder(
                    builder: (context) {
                      final id = reel['id']?.toString();
                      final isSaved = id != null && _savedReelIds.contains(id);
                      return IconButton(
                        icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.white),
                        onPressed: () => _toggleReelSaved(reel),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Caption is shown in preview overlay (to keep card clean)
          ],
        ),
      ),
    );
  }

  Widget _Badge({required IconData icon, required String text, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
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
                hintText: 'Поиск товаров и продавцов',
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
                          'Пока нет товаров',
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
