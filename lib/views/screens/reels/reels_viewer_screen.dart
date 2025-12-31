import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/screens/buyer/product_detail_screen.dart';
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
        'Товар не найден',
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
                  'Пока нет рилсов',
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
                final caption = (reel['caption'] ?? '').toString();
                final likes = reel['likes'] ?? reel['likes_count'] ?? 0;
                final contentId = reel['id']?.toString();

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (videoUrl != null && videoUrl.isNotEmpty)
                      VideoPlayerItem(videoUrl: videoUrl)
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
                              icon: Icons.favorite,
                              label: '$likes',
                              color: Colors.white,
                              onTap: () {
                                if (contentId == null || contentId.isEmpty) return;
                                _controller.likeContent(contentId);
                              },
                            ),
                            const SizedBox(height: 16),
                            _ActionButton(
                              icon: Icons.comment_outlined,
                              label: '',
                              color: Colors.white,
                              onTap: () {},
                            ),
                            const SizedBox(height: 16),
                            _ActionButton(
                              icon: Icons.share_outlined,
                              label: '',
                              color: Colors.white,
                              onTap: () {},
                            ),
                            const SizedBox(height: 16),
                            _ActionButton(
                              icon: Icons.more_horiz,
                              label: '',
                              color: Colors.white,
                              onTap: () {},
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
                            if (caption.trim().isNotEmpty)
                              Text(
                                caption,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (reel['product_id'] != null) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 42,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _openProductFromReel(reel);
                                  },
                                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                                  label: Text('buy_now'.tr),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                  ),
                                ),
                              ),
                            ],
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
