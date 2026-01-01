import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/services/api_service.dart';
import 'package:tiktok_tutorial/views/screens/buyer/cart_screen.dart';
import 'package:tiktok_tutorial/views/screens/buyer/product_detail_screen.dart';
import 'package:tiktok_tutorial/views/widgets/video_player_iten.dart';
import 'package:tiktok_tutorial/utils/formatters.dart';
import 'package:tiktok_tutorial/utils/media_url.dart';
import 'package:tiktok_tutorial/utils/money.dart';
import 'package:tiktok_tutorial/utils/share_utils.dart';
import 'package:tiktok_tutorial/views/widgets/comments_coming_soon_sheet.dart';
import 'package:tiktok_tutorial/views/widgets/product_quick_buy_sheet.dart';
import 'package:tiktok_tutorial/views/widgets/app_network_image.dart';

/// Full-screen vertical reel viewer (TikTok-like).
///
/// Marketplace home currently shows reels as cards; this screen renders them
/// as a vertical PageView with autoplay video + overlays.
class ReelsViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> reels;
  final int initialIndex;

  const ReelsViewerScreen({
    super.key,
    required this.reels,
    this.initialIndex = 0,
  });

  @override
  State<ReelsViewerScreen> createState() => _ReelsViewerScreenState();
}

class _ReelsViewerScreenState extends State<ReelsViewerScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  late final CartController _cartController;
  late final PageController _pageController;
  int _index = 0;
  late List<Map<String, dynamic>> _reels;
  final Set<String> _viewed = <String>{};
  final Set<String> _followingAuthorIds = <String>{};
  String? _likeBurstForReelId;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }
    _cartController = Get.find<CartController>();
    _reels = widget.reels.map((e) => Map<String, dynamic>.from(e)).toList();
    _index = widget.initialIndex.clamp(0, _reels.isEmpty ? 0 : _reels.length - 1);
    _pageController = PageController(initialPage: _index);
    _markViewed(_index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reels.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Text(
              'reels_empty'.tr,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: (i) {
          setState(() => _index = i);
          _markViewed(i);
        },
        itemCount: _reels.length,
        itemBuilder: (context, i) {
          final reel = _reels[i];
          final videoUrl = reel['video_url']?.toString();
          final reelId = reel['id']?.toString() ?? '';
          final authorId = reel['author_id']?.toString() ?? '';
          return Stack(
            fit: StackFit.expand,
            children: [
              if (videoUrl != null && looksLikeVideoUrl(videoUrl))
                VideoPlayerItem(videoUrl: videoUrl.trim())
              else
                Container(
                  color: Colors.grey[900],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_off, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text(
                          (videoUrl == null || videoUrl.trim().isEmpty)
                              ? 'no_video'.tr
                              : 'video_link_not_video'.tr,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (videoUrl != null && videoUrl.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              videoUrl.trim(),
                              style: TextStyle(color: Colors.grey[700], fontSize: 11),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Bottom gradient for readability (behind UI)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 280,
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

              // Like burst animation (on tap like)
              if (_likeBurstForReelId != null && _likeBurstForReelId == reelId)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Icon(Icons.favorite, color: Colors.white70, size: 96),
                    ),
                  ),
                ),

              // Top bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Spacer(),
                      Obx(() {
                        final count = _cartController.itemCount;
                        return Stack(
                          children: [
                            IconButton(
                              onPressed: () => Get.to(() => const CartScreen()),
                              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                            ),
                            if (count > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: buttonColor ?? primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                      IconButton(
                        onPressed: () async {
                          await copyToClipboardWithToast(buildReelShareText(reel));
                        },
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              // Right action column
              Positioned(
                right: 10,
                bottom: 110,
                child: Column(
                  children: [
                    _CircleActionButton(
                      icon: Icons.favorite,
                      label: '${asInt(reel['likes_count'] ?? reel['likes'] ?? 0)}',
                      iconColor: Colors.white,
                      onTap: () async {
                        final id = reel['id']?.toString() ?? '';
                        if (id.trim().isEmpty) return;
                        if (mounted) {
                          setState(() => _likeBurstForReelId = id);
                          Future<void>.delayed(const Duration(milliseconds: 260)).then((_) {
                            if (!mounted) return;
                            if (_likeBurstForReelId == id) setState(() => _likeBurstForReelId = null);
                          });
                        }
                        await _controller.toggleLikeOnReel(id);
                        // Refresh local copy from controller if present.
                        final idx = _controller.reels.indexWhere((r) => r['id']?.toString() == id);
                        if (!mounted) return;
                        setState(() {
                          if (idx != -1) _reels[i] = Map<String, dynamic>.from(_controller.reels[idx]);
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    _CircleActionButton(
                      icon: Icons.comment,
                      label: '${asInt(reel['comments_count'] ?? 0)}',
                      iconColor: Colors.white,
                      onTap: () {
                        Get.bottomSheet(
                          CommentsComingSoonSheet(reel: reel),
                          isScrollControlled: true,
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _CircleActionButton(
                      icon: Icons.share,
                      label: 'share'.tr,
                      iconColor: Colors.white,
                      onTap: () async {
                        await copyToClipboardWithToast(buildReelShareText(reel));
                      },
                    ),
                    const SizedBox(height: 18),
                    _CircleActionButton(
                      icon: Icons.volume_up,
                      label: '',
                      iconColor: Colors.white,
                      onTap: () {
                        // Mute/unmute button is already available inside VideoPlayerItem on bottom-right.
                        // Here we keep a familiar affordance (no-op for now).
                      },
                    ),
                  ],
                ),
              ),

              // Bottom-left meta
              Positioned(
                left: 16,
                right: 90,
                bottom: 28,
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            '@${reel['author_name']?.toString() ?? 'User'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (authorId.trim().isNotEmpty)
                            _FollowButton(
                              isFollowing: _followingAuthorIds.contains(authorId),
                              onTap: () {
                                setState(() {
                                  if (_followingAuthorIds.contains(authorId)) {
                                    _followingAuthorIds.remove(authorId);
                                  } else {
                                    _followingAuthorIds.add(authorId);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if ((reel['caption']?.toString() ?? '').trim().isNotEmpty)
                        Text(
                          reel['caption'].toString(),
                          style: TextStyle(color: Colors.grey[200]),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 10),
                      if (reel['product_id'] != null)
                        _ReelProductCard(
                          badgeText: 'best_product'.tr,
                          product: _findProduct((reel['product_id'] ?? '').toString()),
                          onOpen: () {
                            final productId = reel['product_id']?.toString();
                            if (productId == null || productId.trim().isEmpty) return;
                            final p = _findProduct(productId);
                            if (p == null) {
                              Get.snackbar('product'.tr, 'product_not_found'.tr, snackPosition: SnackPosition.BOTTOM);
                              return;
                            }
                            Get.bottomSheet(
                              ProductQuickBuySheet(product: Map<String, dynamic>.from(p)),
                              isScrollControlled: true,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _markViewed(int index) {
    if (index < 0 || index >= _reels.length) return;
    final id = _reels[index]['id']?.toString().trim();
    if (id == null || id.isEmpty) return;
    if (_viewed.contains(id)) return;
    _viewed.add(id);
    // Fire-and-forget.
    // ignore: discarded_futures
    ApiService.viewContent(id);
  }

  Map<String, dynamic>? _findProduct(String productId) {
    for (final e in _controller.products) {
      if (e['id']?.toString() == productId) {
        return e;
      }
    }
    return null;
  }

  String _productTitleFor(Map<String, dynamic> reel) {
    final productId = reel['product_id']?.toString() ?? '';
    if (productId.trim().isEmpty) return 'product'.tr;
    final p = _findProduct(productId);
    final name = (p?['name'] ?? '').toString().trim();
    return name.isNotEmpty ? name : 'product'.tr;
  }

  String _productSubtitleFor(Map<String, dynamic> reel) {
    final productId = reel['product_id']?.toString() ?? '';
    if (productId.trim().isEmpty) return 'open_product_card'.tr;
    final p = _findProduct(productId);
    if (p == null) return 'open_product_card'.tr;
    final price = formatMoneyWithCurrency(p['price']);
    final avg = asDouble(p['rating_avg']);
    final cnt = asInt(p['rating_count'] ?? p['reviews_count'] ?? p['review_count'] ?? 0);
    if (avg > 0 && cnt > 0) return '$price • ★${avg.toStringAsFixed(1)} ($cnt)';
    if (avg > 0) return '$price • ★${avg.toStringAsFixed(1)}';
    return price;
  }

  Widget? _buildAddToCartTrailing(Map<String, dynamic> reel) {
    final productId = reel['product_id']?.toString() ?? '';
    if (productId.trim().isEmpty) return null;
    final p = _findProduct(productId);
    if (p == null) return null;

    return IconButton(
      onPressed: () {
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
      icon: const Icon(Icons.add_shopping_cart, color: Colors.black),
      tooltip: 'add_to_cart'.tr,
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 6),
          if (label.trim().isNotEmpty)
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;

  const _FollowButton({required this.isFollowing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = isFollowing ? Colors.white12 : primaryColor;
    final fg = isFollowing ? Colors.white : Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isFollowing ? Colors.white24 : Colors.transparent),
        ),
        child: Text(
          (isFollowing ? 'following' : 'follow').tr,
          style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ReelProductCard extends StatelessWidget {
  final String badgeText;
  final Map<String, dynamic>? product;
  final VoidCallback onOpen;

  const _ReelProductCard({
    required this.badgeText,
    required this.product,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    final name = (p?['name'] ?? 'product'.tr).toString();
    final subtitle = p == null ? 'open_product_card'.tr : formatMoneyWithCurrency(p['price']);

    return GestureDetector(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: AppNetworkImage(
                      url: p?['image_url']?.toString(),
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: Colors.grey[850],
                        child: Icon(Icons.inventory_2, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[200], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shopping_cart, color: Colors.black, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

