import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/screens/buyer/product_detail_screen.dart';
import 'package:tiktok_tutorial/views/screens/common/report_content_screen.dart';
import 'package:tiktok_tutorial/views/widgets/video_player_iten.dart';

class ReelsViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> reels;
  final int initialIndex;

  const ReelsViewerScreen({
    Key? key,
    required this.reels,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<ReelsViewerScreen> createState() => _ReelsViewerScreenState();
}

class _ReelsViewerScreenState extends State<ReelsViewerScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  late final PageController _pageController;
  int _currentIndex = 0;
  final Set<String> _likedContentIds = <String>{};
  final Map<String, int> _likeOverrides = <String, int>{};
  bool _showBigHeart = false;

  Map<String, dynamic>? _findProductForReel(Map<String, dynamic> reel) {
    final productId = reel['product_id']?.toString();
    if (productId == null || productId.isEmpty) return null;
    final product = _controller.products.firstWhere(
      (p) => p['id']?.toString() == productId,
      orElse: () => <String, dynamic>{},
    );
    return product.isEmpty ? null : product;
  }

  int _likesFromReel(Map<String, dynamic> reel) {
    final raw = reel['likes'] ?? reel['likes_count'] ?? 0;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 0;
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
      'success'.tr,
      'link_copied'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  void _openCommentsStub() {
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
              Text(
                'comments'.tr,
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'comments_coming_soon'.tr,
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.check),
                  label: Text('ok'.tr),
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

  void _openMoreSheet(Map<String, dynamic> reel) {
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
                title: Text('copy_link'.tr, style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Get.back();
                  await _copyReelLink(reel);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined, color: Colors.redAccent),
                title: Text('report_content'.tr, style: const TextStyle(color: Colors.white)),
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
                  child: Text('cancel'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _flashBigHeart() {
    if (_showBigHeart) return;
    setState(() => _showBigHeart = true);
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() => _showBigHeart = false);
    });
  }

  void _toggleLike(Map<String, dynamic> reel, {bool fromDoubleTap = false}) {
    final contentId = reel['id']?.toString();
    if (contentId == null || contentId.isEmpty) return;

    final baseLikes = _likeOverrides[contentId] ?? _likesFromReel(reel);
    final isLiked = _likedContentIds.contains(contentId);

    // IG behavior: double tap only likes (doesn't unlike).
    if (fromDoubleTap && isLiked) return;

    final nextLiked = !isLiked;
    final nextLikes = (baseLikes + (nextLiked ? 1 : -1)).clamp(0, 1 << 30);

    setState(() {
      if (nextLiked) {
        _likedContentIds.add(contentId);
      } else {
        _likedContentIds.remove(contentId);
      }
      _likeOverrides[contentId] = nextLikes;
    });

    if (fromDoubleTap) _flashBigHeart();

    _controller.likeContent(contentId);
  }

  void _openProductFromReel(Map<String, dynamic> reel) {
    final productId = reel['product_id']?.toString();
    if (productId == null || productId.isEmpty) return;

    final product = _controller.products.firstWhere(
      (p) => p['id']?.toString() == productId,
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.reels.isNotEmpty ? widget.reels.length - 1 : 0);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: widget.reels.isEmpty
          ? SafeArea(
              child: Center(
                child: Text(
                  'no_reels_yet'.tr,
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            )
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemCount: widget.reels.length,
              itemBuilder: (context, index) {
                final reel = widget.reels[index];
                final videoUrl = (reel['video_url'] ?? reel['media_url']) as String?;
                final authorName = reel['author_name'] ?? 'User';
                final authorAvatar = reel['author_avatar']?.toString();
                final caption = (reel['caption'] ?? '').toString();
                final contentId = reel['id']?.toString();
                final likes = contentId == null
                    ? _likesFromReel(reel)
                    : (_likeOverrides[contentId] ?? _likesFromReel(reel));
                final isLiked = contentId != null && _likedContentIds.contains(contentId);
                final product = _findProductForReel(reel);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (videoUrl != null && videoUrl.isNotEmpty)
                      VideoPlayerItem(
                        videoUrl: videoUrl,
                        onDoubleTap: () => _toggleLike(reel, fromDoubleTap: true),
                      )
                    else
                      Container(
                        color: Colors.black,
                        child: Center(
                          child: Icon(Icons.video_library, size: 64, color: Colors.grey[700]),
                        ),
                      ),

                    // Subtle gradients (IG-like overlays readability)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.35),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.55),
                              ],
                              stops: const [0.0, 0.25, 0.65, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Big heart on double tap
                    Center(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _showBigHeart ? 1 : 0,
                          duration: const Duration(milliseconds: 140),
                          child: AnimatedScale(
                            scale: _showBigHeart ? 1.0 : 0.8,
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

                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Get.back(),
                            ),
                            const SizedBox(width: 4),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[850],
                              backgroundImage: (authorAvatar != null && authorAvatar.isNotEmpty) ? NetworkImage(authorAvatar) : null,
                              child: (authorAvatar == null || authorAvatar.isEmpty)
                                  ? const Icon(Icons.person, color: Colors.white, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                authorName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right actions (IG/TikTok style)
                    Positioned(
                      right: 10,
                      bottom: 110,
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionButton(
                              icon: isLiked ? Icons.favorite : Icons.favorite_border,
                              label: '$likes',
                              color: isLiked ? Colors.red[300]! : Colors.white,
                              onTap: () {
                                _toggleLike(reel);
                              },
                            ),
                            const SizedBox(height: 16),
                            _ActionButton(
                              icon: Icons.comment_outlined,
                              label: '',
                              color: Colors.white,
                              onTap: _openCommentsStub,
                            ),
                            const SizedBox(height: 16),
                            _ActionButton(
                              icon: Icons.share_outlined,
                              label: '',
                              color: Colors.white,
                              onTap: () => _copyReelLink(reel),
                            ),
                            const SizedBox(height: 16),
                            _ActionButton(
                              icon: Icons.more_horiz,
                              label: '',
                              color: Colors.white,
                              onTap: () => _openMoreSheet(reel),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom caption + product CTA
                    Positioned(
                      left: 12,
                      right: 72,
                      bottom: 22,
                      child: SafeArea(
                        top: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (product != null) ...[
                              _ProductMiniCard(
                                product: product,
                                onTap: () => _openProductFromReel(reel),
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (caption.trim().isNotEmpty)
                              Text(
                                caption,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
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
}

class _ProductMiniCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const _ProductMiniCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = (product['name'] ?? 'product'.tr).toString();
    final imageUrl = product['image_url']?.toString();
    final price = product['price'];
    final priceText = (price is num) ? "${price.toStringAsFixed(0)} ${'currency_sum'.tr}" : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.shopping_bag, color: Colors.grey),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    priceText ?? 'open_product'.tr,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'buy_now'.tr,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 34),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
