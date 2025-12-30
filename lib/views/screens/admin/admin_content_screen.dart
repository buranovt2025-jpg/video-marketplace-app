import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/screens/seller/create_reel_screen.dart';
import 'package:tiktok_tutorial/views/screens/seller/create_story_screen.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

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
        title: const Text(
          'Контент',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          tabs: const [
            Tab(text: 'Рилсы'),
            Tab(text: 'Истории'),
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
        label: const Text('Создать'),
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
                'Нет рилсов',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Создайте рекламный рилс для платформы',
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
                'Нет историй',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Создайте рекламную историю для платформы',
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
                        child: Image.network(
                          reel['thumbnail_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(Icons.video_library, color: Colors.grey[600], size: 40),
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
                        decoration: const BoxDecoration(
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
                          Icon(Icons.favorite, color: Colors.red[400], size: 14),
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
                    reel['caption'] ?? 'Без описания',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reel['author_name'] ?? 'Автор',
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
            color: story['is_active'] == true ? Colors.purple : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (story['media_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  story['media_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.image, color: Colors.grey[600], size: 32),
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
                child: Text(
                  story['author_name'] ?? 'Автор',
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
            
            const Text(
              'Создать рекламный контент',
              style: TextStyle(
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
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.video_call, color: Colors.purple),
              ),
              title: const Text('Рилс', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Видео для ленты',
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
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_photo_alternate, color: Colors.orange),
              ),
              title: const Text('История', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Фото/видео на 24 часа',
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
              reel['caption'] ?? 'Без описания',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildDetailRow('Автор', reel['author_name'] ?? 'Не указан'),
            _buildDetailRow('Лайки', '${reel['likes_count'] ?? 0}'),
            _buildDetailRow('Комментарии', '${reel['comments_count'] ?? 0}'),
            _buildDetailRow('ID', reel['id']?.substring(0, 8) ?? ''),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.back();
                  _showDeleteDialog(reel, 'reel');
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Удалить', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
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
            
            const Text(
              'История',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildDetailRow('Автор', story['author_name'] ?? 'Не указан'),
            _buildDetailRow('Статус', story['is_active'] == true ? 'Активна' : 'Истекла'),
            _buildDetailRow('ID', story['id']?.substring(0, 8) ?? ''),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Get.back();
                  _showDeleteDialog(story, 'story');
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Удалить', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
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
    final typeLabel = type == 'reel' ? 'рилс' : 'историю';
    
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Удалить $typeLabel?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Это действие нельзя отменить.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Отмена', style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              // TODO: Implement delete API
              Get.snackbar(
                'Удалено',
                'Контент удалён',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
              _loadContent();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
