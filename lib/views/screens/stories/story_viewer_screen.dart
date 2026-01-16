import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/widgets/app_network_image.dart';
import 'package:tiktok_tutorial/utils/web_image_policy.dart';
import 'package:tiktok_tutorial/views/widgets/video_player_iten.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;

  const StoryViewerScreen({
    Key? key,
    required this.stories,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentIndex = 0;
  bool _isPaused = false;

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
    _startProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _nextStory();
    }
  }

  void _startProgress() {
    // Video stories should stay longer than images by default.
    final current = widget.stories[_currentIndex];
    final isVideo = (current['video_url']?.toString() ?? '').trim().isNotEmpty;
    _progressController.duration = Duration(seconds: isVideo ? 10 : 5);
    _progressController.reset();
    _progressController.forward();
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startProgress();
    } else {
      Get.back();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startProgress();
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
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    setState(() {
      _isPaused = false;
    });
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
              physics: const BouncingScrollPhysics(),
              itemCount: widget.stories.length,
              onPageChanged: (i) {
                setState(() {
                  _currentIndex = i;
                });
                _startProgress();
              },
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
                              ? networkImageProviderOrNull(widget.stories[_currentIndex]['author_avatar'])
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
    final imageUrl = story['image_url'];
    final videoUrl = story['video_url'];

    return Container(
      color: Colors.black,
      child: Center(
        child: imageUrl != null
            ? AppNetworkImage(
                url: imageUrl?.toString(),
                fit: BoxFit.contain,
                placeholder: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text(
                      'image_load_failed'.tr,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            : (videoUrl != null && videoUrl.toString().trim().isNotEmpty)
                ? VideoPlayerItem(videoUrl: videoUrl.toString())
                : Column(
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

  Widget _buildProductLink(Map<String, dynamic> story) {
    return GestureDetector(
      onTap: () {
        // Navigate to product detail
        Get.snackbar(
          'product'.tr,
          'go_to_product'.trParams({'id': story['product_id']?.toString() ?? ''}),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.white,
          colorText: Colors.black,
        );
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
              child: const Icon(Icons.shopping_bag, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'view_product'.tr,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'tap_to_open'.tr,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
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
    if (dateString == null) return 'recently'.tr;
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'just_now'.tr;
      } else if (difference.inMinutes < 60) {
        return 'minutes_ago'.trParams({'n': difference.inMinutes.toString()});
      } else if (difference.inHours < 24) {
        return 'hours_ago'.trParams({'n': difference.inHours.toString()});
      } else {
        return 'days_ago'.trParams({'n': difference.inDays.toString()});
      }
    } catch (e) {
      return 'recently'.tr;
    }
  }
}
