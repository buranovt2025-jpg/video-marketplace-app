import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/screens/buyer/product_detail_screen.dart';
import 'package:video_player/video_player.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;

  const StoryViewerScreen({
    Key? key,
    required this.stories,
    this.initialIndex = 0,
    this.onIndexChanged,
  }) : super(key: key);

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentIndex = 0;
  bool _isPaused = false;
  VideoPlayerController? _videoController;
  Future<void>? _videoInit;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _progressController.addStatusListener(_onProgressComplete);
    _prepareCurrentStory();
    widget.onIndexChanged?.call(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _disposeVideoController();
    super.dispose();
  }

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _nextStory();
    }
  }

  void _startProgress() {
    _progressController.reset();
    _progressController.forward();
  }

  void _disposeVideoController() {
    final ctrl = _videoController;
    _videoController = null;
    _videoInit = null;
    ctrl?.dispose();
  }

  Duration _normalizeStoryDuration(Duration d) {
    // Keep IG-like feel: too short feels like a flash, too long feels stuck.
    const min = Duration(seconds: 2);
    const max = Duration(seconds: 15);
    if (d <= Duration.zero) return const Duration(seconds: 5);
    if (d < min) return min;
    if (d > max) return max;
    return d;
  }

  Future<void> _prepareCurrentStory() async {
    _progressController.stop();
    _disposeVideoController();

    final story = widget.stories[_currentIndex];
    final videoUrl = story['video_url']?.toString();
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

    if (!hasVideo) {
      _progressController.duration = const Duration(seconds: 5);
      if (!_isPaused) _startProgress();
      return;
    }

    final controller = VideoPlayerController.network(videoUrl);
    _videoController = controller;
    _videoInit = controller.initialize();

    try {
      await _videoInit;
      if (!mounted) return;

      await controller.setLooping(false);
      await controller.setVolume(1);
      final d = _normalizeStoryDuration(controller.value.duration);
      _progressController.duration = d;

      if (!_isPaused) {
        await controller.play();
        _startProgress();
      }
      setState(() {});
    } catch (_) {
      // If video fails, keep UX moving.
      _progressController.duration = const Duration(seconds: 5);
      if (!_isPaused) _startProgress();
      setState(() {});
    }
  }

  void _openProductFromStory(Map<String, dynamic> story) {
    final productId = story['product_id']?.toString();
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

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      widget.onIndexChanged?.call(_currentIndex);
    } else {
      Get.back();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      widget.onIndexChanged?.call(_currentIndex);
    }
  }

  void _onTapDown(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition.dx;

    if (tapPosition < screenWidth / 3) {
      _previousStory();
    } else if (tapPosition > screenWidth * 2 / 3) {
      _nextStory();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
    _videoController?.pause();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    setState(() {
      _isPaused = false;
    });
    _videoController?.play();
    _progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        child: Stack(
          children: [
            // Story content
            PageView.builder(
              controller: _pageController,
              physics: const PageScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _prepareCurrentStory();
                widget.onIndexChanged?.call(_currentIndex);
              },
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return _buildStoryContent(story);
              },
            ),

            // Top overlay (progress bars + user info)
            SafeArea(
              child: Column(
                children: [
                  // Progress bars
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: List.generate(
                        widget.stories.length,
                        (index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _buildProgressBar(index),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // User info and close button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // User avatar
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: widget.stories[_currentIndex]['author_avatar'] != null
                              ? NetworkImage(widget.stories[_currentIndex]['author_avatar'])
                              : null,
                          child: widget.stories[_currentIndex]['author_avatar'] == null
                              ? const Icon(Icons.person, color: Colors.white, size: 18)
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // User name and time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.stories[_currentIndex]['author_name'] ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _getTimeAgo(widget.stories[_currentIndex]['created_at']),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Close button
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Paused indicator
            if (_isPaused)
              const Center(
                child: Icon(
                  Icons.pause_circle_filled,
                  color: Colors.white54,
                  size: 80,
                ),
              ),

            // Bottom overlay (product link if available)
            if (widget.stories[_currentIndex]['product_id'] != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    child: _buildProductLink(widget.stories[_currentIndex]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 3,
        child: index < _currentIndex
            ? Container(color: Colors.white)
            : index == _currentIndex
                ? AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      );
                    },
                  )
                : Container(color: Colors.white30),
      ),
    );
  }

  Widget _buildStoryContent(Map<String, dynamic> story) {
    final imageUrl = story['image_url']?.toString();
    final videoUrl = story['video_url']?.toString();

    return Container(
      color: Colors.black,
      child: (imageUrl != null && imageUrl.isNotEmpty)
          ? Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'image_load_failed'.tr,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  );
                },
              ),
            )
          : (videoUrl != null && videoUrl.isNotEmpty)
              ? _buildVideoStory()
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'no_content'.tr,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildVideoStory() {
    final init = _videoInit;
    final controller = _videoController;

    if (init == null || controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return FutureBuilder<void>(
      future: init,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !controller.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        return Center(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductLink(Map<String, dynamic> story) {
    final productId = story['product_id']?.toString();
    final product = productId == null
        ? null
        : _controller.products.firstWhere(
            (p) => p['id']?.toString() == productId,
            orElse: () => <String, dynamic>{},
          );

    final hasProduct = product != null && product.isNotEmpty;
    final productName = hasProduct ? (product['name'] ?? 'product'.tr).toString() : 'open_product'.tr;
    final productImage = hasProduct ? product['image_url']?.toString() : null;
    final price = hasProduct ? product['price'] : null;
    final priceText = (price is num) ? "${price.toStringAsFixed(0)} ${'currency_sum'.tr}" : null;

    return GestureDetector(
      onTap: () {
        _openProductFromStory(story);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: (productImage != null && productImage.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        productImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.shopping_bag, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    priceText ?? 'tap_to_open'.tr,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  String _getTimeAgo(String? dateString) {
    if (dateString == null) return 'Недавно';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Только что';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} мин назад';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ч назад';
      } else {
        return '${difference.inDays} дн назад';
      }
    } catch (e) {
      return 'Недавно';
    }
  }
}
