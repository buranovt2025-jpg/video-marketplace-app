import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/screens/buyer/product_detail_screen.dart';
import 'package:tiktok_tutorial/views/widgets/video_player_iten.dart';
import 'package:tiktok_tutorial/utils/formatters.dart';
import 'package:tiktok_tutorial/utils/media_url.dart';

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
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.reels.isEmpty ? 0 : widget.reels.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reels.isEmpty) {
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
        onPageChanged: (i) => setState(() => _index = i),
        itemCount: widget.reels.length,
        itemBuilder: (context, i) {
          final reel = widget.reels[i];
          final videoUrl = reel['video_url']?.toString();
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
                      IconButton(
                        onPressed: () {},
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
                    _ActionButton(
                      icon: Icons.favorite,
                      label: '${asInt(reel['likes_count'] ?? reel['likes'] ?? 0)}',
                      color: Colors.white,
                      onTap: () => _controller.likeContent(reel['id']?.toString() ?? ''),
                    ),
                    const SizedBox(height: 18),
                    _ActionButton(
                      icon: Icons.comment,
                      label: '${asInt(reel['comments_count'] ?? 0)}',
                      color: Colors.white,
                      onTap: () {},
                    ),
                    const SizedBox(height: 18),
                    _ActionButton(
                      icon: Icons.share,
                      label: 'share'.tr,
                      color: Colors.white,
                      onTap: () {},
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
                      // readability gradient
                      // (kept in front via padding below; video stays behind)
                      Text(
                        reel['author_name']?.toString() ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if ((reel['caption']?.toString() ?? '').trim().isNotEmpty)
                        Text(
                          reel['caption'].toString(),
                          style: TextStyle(color: Colors.grey[200]),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 10),
                      if (reel['product_id'] != null)
                        _ProductPill(
                          title: 'product'.tr,
                          subtitle: 'open_product_card'.tr,
                          onTap: () {
                            final productId = reel['product_id']?.toString();
                            if (productId == null || productId.isEmpty) return;
                            // Best effort: find product in loaded list.
                            Map<String, dynamic>? p;
                            for (final e in _controller.products) {
                              if (e['id']?.toString() == productId) {
                                p = e;
                                break;
                              }
                            }
                            if (p != null) {
                              Get.to(() => ProductDetailScreen(product: Map<String, dynamic>.from(p!)));
                            } else {
                              Get.snackbar(
                                'product'.tr,
                                'product_number'.trParams({'id': productId}),
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.white,
                                colorText: Colors.black,
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom gradient for readability
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 240,
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black54,
                          Colors.black87,
                        ],
                      ),
                    ),
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 6),
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

class _ProductPill extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProductPill({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(subtitle, style: TextStyle(color: Colors.grey[700], fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

