import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/widgets/app_network_image.dart';
import 'package:tiktok_tutorial/views/screens/seller/create_reel_screen.dart';
import 'package:tiktok_tutorial/views/screens/seller/create_story_screen.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({Key? key}) : super(key: key);

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> with SingleTickerProviderStateMixin {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    await Future.wait([
      _controller.fetchReels(),
      _controller.fetchStories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          'content'.tr,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadContent,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: buttonColor,
          labelColor: buttonColor,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'reels'.tr),
            Tab(text: 'stories'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReelsTab(),
          _buildStoriesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOptions(),
        backgroundColor: buttonColor,
        icon: const Icon(Icons.add),
        label: Text('create'.tr),
      ),
    );
  }

  Widget _buildReelsTab() {
    return Obx(() {
      final reels = _controller.reels;
      
      if (reels.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[700]),
              const SizedBox(height: 16),
              Text(
                'reels_empty'.tr,
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'create_promotional_reel'.tr,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        );
      }
      
      return RefreshIndicator(
        onRefresh: _loadContent,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: reels.length,
          itemBuilder: (context, index) {
            final reel = reels[index];
            return _buildReelCard(reel);
          },
        ),
      );
    });
  }

  Widget _buildStoriesTab() {
    return Obx(() {
      final stories = _controller.stories;
      
      if (stories.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_stories_outlined, size: 64, color: Colors.grey[700]),
              const SizedBox(height: 16),
              Text(
                'stories_empty'.tr,
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'create_promotional_story'.tr,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        );
      }
      
      return RefreshIndicator(
        onRefresh: _loadContent,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.6,
          ),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            return _buildStoryCard(story);
          },
        ),
      );
    });
  }

  Widget _buildReelCard(Map<String, dynamic> reel) {
    return GestureDetector(
      onTap: () => _showReelDetails(reel),
      onLongPress: () => _showDeleteDialog(reel, 'reel'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (reel['thumbnail_url'] != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: AppNetworkImage(
                          url: reel['thumbnail_url']?.toString(),
                          fit: BoxFit.cover,
                          errorWidget: const Center(
                            child: Icon(Icons.video_library, color: Colors.grey, size: 40),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Icon(Icons.video_library, color: Colors.grey[600], size: 40),
                      ),
                    
                    // Play icon overlay
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                      ),
                    ),
                    
                    // Stats overlay
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Row(
                        children: [
                          Icon(Icons.favorite, color: primaryColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${reel['likes_count'] ?? 0}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reel['caption'] ?? 'no_description'.tr,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reel['author_name'] ?? 'author'.tr,
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    return GestureDetector(
      onTap: () => _showStoryDetails(story),
      onLongPress: () => _showDeleteDialog(story, 'story'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: story['is_active'] == true ? accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (story['media_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AppNetworkImage(
                  url: story['media_url']?.toString(),
                  fit: BoxFit.cover,
                  errorWidget: const Center(
                    child: Icon(Icons.image, color: Colors.grey, size: 32),
                  ),
                ),
              )
            else
              Center(
                child: Icon(Icons.image, color: Colors.grey[600], size: 32),
              ),
            
            // Author name at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
                child: Text(
                  story['author_name'] ?? 'author'.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'create_ad_content'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.video_call, color: primaryColor),
              ),
              title: Text('reel'.tr, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                'video_for_feed'.tr,
                style: TextStyle(color: Colors.grey[500]),
              ),
              onTap: () {
                Get.back();
                Get.to(() => const CreateReelScreen());
              },
            ),
            
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_photo_alternate, color: accentColor),
              ),
              title: Text('story'.tr, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                'photo_video_24h'.tr,
                style: TextStyle(color: Colors.grey[500]),
              ),
              onTap: () {
                Get.back();
                Get.to(() => const CreateStoryScreen());
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showReelDetails(Map<String, dynamic> reel) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              reel['caption'] ?? 'no_description'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildDetailRow('author'.tr, (reel['author_name'] ?? 'not_specified'.tr).toString()),
            _buildDetailRow('likes'.tr, '${reel['likes_count'] ?? 0}'),
            _buildDetailRow('comments'.tr, '${reel['comments_count'] ?? 0}'),
            _buildDetailRow('ID', reel['id']?.substring(0, 8) ?? ''),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.back();
                  _showDeleteDialog(reel, 'reel');
                },
                icon: const Icon(Icons.delete, color: primaryColor),
                label: Text('delete'.tr, style: const TextStyle(color: primaryColor)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showStoryDetails(Map<String, dynamic> story) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'story'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildDetailRow('author'.tr, (story['author_name'] ?? 'not_specified'.tr).toString()),
            _buildDetailRow('order_status'.tr, story['is_active'] == true ? 'active_feminine'.tr : 'expired_feminine'.tr),
            _buildDetailRow('ID', story['id']?.substring(0, 8) ?? ''),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.back();
                  _showDeleteDialog(story, 'story');
                },
                icon: const Icon(Icons.delete, color: primaryColor),
                label: Text('delete'.tr, style: const TextStyle(color: primaryColor)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> item, String type) {
    final typeLabel = type == 'reel' ? 'reel'.tr : 'story'.tr;
    
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'delete_content_question'.trParams({'type': typeLabel}),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'delete_irreversible'.tr,
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              // TODO: Implement delete API
              Get.snackbar(
                'deleted'.tr,
                'content_deleted'.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
              _loadContent();
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }
}
