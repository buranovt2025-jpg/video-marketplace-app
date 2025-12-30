import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/screens/admin/admin_users_screen.dart';
import 'package:tiktok_tutorial/views/screens/admin/admin_orders_screen.dart';
import 'package:tiktok_tutorial/views/screens/admin/admin_content_screen.dart';
import 'package:tiktok_tutorial/views/screens/auth/marketplace_login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _controller.fetchOrders(),
      _controller.fetchProducts(),
      _controller.fetchReels(),
      _controller.fetchStories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          const AdminUsersScreen(),
          const AdminOrdersScreen(),
          const AdminContentScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey[900],
        selectedItemColor: buttonColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Дашборд',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Пользователи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Заказы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Контент',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: backgroundColor,
          title: const Text(
            'Админ-панель',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [buttonColor, buttonColor.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Добро пожаловать!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => Text(
                        _controller.userName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                        ),
                      )),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Stats grid
                const Text(
                  'Статистика',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Obx(() => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      'Заказы',
                      _controller.orders.length.toString(),
                      Icons.shopping_bag,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Товары',
                      _controller.products.length.toString(),
                      Icons.inventory_2,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Рилсы',
                      _controller.reels.length.toString(),
                      Icons.video_library,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      'Истории',
                      _controller.stories.length.toString(),
                      Icons.auto_stories,
                      Colors.orange,
                    ),
                  ],
                )),
                
                const SizedBox(height: 24),
                
                // Orders by status
                const Text(
                  'Заказы по статусам',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Obx(() => _buildOrdersStatusList()),
                
                const SizedBox(height: 24),
                
                // Quick actions
                const Text(
                  'Быстрые действия',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersStatusList() {
    final orders = _controller.orders;
    
    final statusCounts = <String, int>{
      'created': 0,
      'accepted': 0,
      'ready': 0,
      'picked_up': 0,
      'in_transit': 0,
      'delivered': 0,
      'completed': 0,
      'cancelled': 0,
    };
    
    for (final order in orders) {
      final status = order['status'] ?? 'created';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    
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
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: statusCounts.entries.where((e) => e.value > 0).map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColors[entry.key],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusLabels[entry.key] ?? entry.key,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColors[entry.key]?.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.value.toString(),
                    style: TextStyle(
                      color: statusColors[entry.key],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Создать рилс',
            Icons.video_call,
            Colors.purple,
            () => setState(() => _currentIndex = 3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Создать историю',
            Icons.add_photo_alternate,
            Colors.orange,
            () => setState(() => _currentIndex = 3),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
