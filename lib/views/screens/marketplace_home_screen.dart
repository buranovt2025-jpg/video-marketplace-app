import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
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

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  int _currentIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Obx(() {
        if (!_controller.isLoggedIn) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        return IndexedStack(
          index: _currentIndex,
          children: [
            _buildFeedTab(),
            _buildExploreTab(),
            _buildCreateTab(),
            _buildOrdersTab(),
            _buildProfileTab(),
          ],
        );
      }),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: buttonColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Лента',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Поиск',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Создать',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Заказы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
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
    return Padding(
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
                    ? NetworkImage(story['image_url'])
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
          return _buildReelCard(reel);
        },
      );
    });
  }

  Widget _buildReelCard(Map<String, dynamic> reel) {
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
          
          // Video placeholder
          Container(
            height: 400,
            width: double.infinity,
            color: Colors.grey[800],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    'Видео',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () => _controller.likeContent(reel['id']),
                ),
                Text(
                  '${reel['likes'] ?? 0}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  onPressed: () {},
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border, color: Colors.white),
                  onPressed: () {},
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
            
            return SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
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
                ],
              ),
            ),
          ),
        ],
      );
    });
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
