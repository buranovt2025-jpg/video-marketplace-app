import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/screens/admin/admin_users_screen.dart';
import 'package:tiktok_tutorial/views/screens/admin/admin_orders_screen.dart';
import 'package:tiktok_tutorial/views/screens/admin/admin_content_screen.dart';
import 'package:tiktok_tutorial/views/screens/auth/marketplace_login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

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
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'dashboard'.tr,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'users'.tr,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'orders'.tr,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'content'.tr,
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
          title: Text(
            'admin_panel'.tr,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                      colors: [buttonColor!, buttonColor!.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'welcome_admin'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => Text(
                        _controller.userName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      )),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Stats grid
                Text(
                  'stats'.tr,
                  style: const TextStyle(
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
                      'orders'.tr,
                      _controller.orders.length.toString(),
                      Icons.shopping_bag,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'products'.tr,
                      _controller.products.length.toString(),
                      Icons.inventory_2,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'reels'.tr,
                      _controller.reels.length.toString(),
                      Icons.video_library,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      'stories'.tr,
                      _controller.stories.length.toString(),
                      Icons.auto_stories,
                      Colors.orange,
                    ),
                  ],
                )),
                
                const SizedBox(height: 24),
                
                // Orders by status
                Text(
                  'orders_by_status'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Obx(() => _buildOrdersStatusList()),
                
                const SizedBox(height: 24),
                
                // Quick actions
                Text(
                  'quick_actions'.tr,
                  style: const TextStyle(
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
      'created': 'status_created'.tr,
      'accepted': 'status_accepted'.tr,
      'ready': 'status_ready'.tr,
      'picked_up': 'status_picked_up'.tr,
      'in_transit': 'status_in_transit'.tr,
      'delivered': 'status_delivered'.tr,
      'completed': 'status_completed'.tr,
      'cancelled': 'status_cancelled'.tr,
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
                    color: statusColors[entry.key]?.withOpacity(0.2),
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
            'create_reel'.tr,
            Icons.video_call,
            Colors.purple,
            () => setState(() => _currentIndex = 3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'create_story'.tr,
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
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
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
