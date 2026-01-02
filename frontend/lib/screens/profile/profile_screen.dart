import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(context, user),
                const SizedBox(height: 24),
                _buildMenuSection(context, user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.grey200,
              backgroundImage: user?.avatar != null
                  ? NetworkImage(user!.avatar!)
                  : null,
              child: user?.avatar == null
                  ? const Icon(Icons.person, size: 40, color: AppColors.grey500)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? 'Guest',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phone ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user?.role.name.toUpperCase() ?? 'BUYER',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/profile/edit');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, User? user) {
    return Column(
      children: [
        _buildMenuItem(
          context,
          icon: Icons.person_outline,
          title: 'Edit Profile',
          onTap: () => Navigator.pushNamed(context, '/profile/edit'),
        ),
        _buildMenuItem(
          context,
          icon: Icons.location_on_outlined,
          title: 'My Addresses',
          onTap: () => Navigator.pushNamed(context, '/profile/addresses'),
        ),
        _buildMenuItem(
          context,
          icon: Icons.receipt_long_outlined,
          title: 'Order History',
          onTap: () => Navigator.pushNamed(context, '/orders'),
        ),
        if (user?.role == UserRole.seller) ...[
          _buildMenuItem(
            context,
            icon: Icons.store_outlined,
            title: 'Seller Dashboard',
            onTap: () => Navigator.pushNamed(context, '/seller/dashboard'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.video_library_outlined,
            title: 'My Videos',
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.inventory_2_outlined,
            title: 'My Products',
            onTap: () {},
          ),
        ],
        if (user?.role == UserRole.courier) ...[
          _buildMenuItem(
            context,
            icon: Icons.local_shipping_outlined,
            title: 'Courier Dashboard',
            onTap: () => Navigator.pushNamed(context, '/courier/dashboard'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.qr_code_scanner,
            title: 'Scan QR Code',
            onTap: () => Navigator.pushNamed(context, '/qr-scanner'),
          ),
        ],
        _buildMenuItem(
          context,
          icon: Icons.favorite_outline,
          title: 'Wishlist',
          onTap: () {},
        ),
        _buildMenuItem(
          context,
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {},
        ),
        _buildMenuItem(
          context,
          icon: Icons.info_outline,
          title: 'About',
          onTap: () {},
        ),
        const SizedBox(height: 16),
        _buildMenuItem(
          context,
          icon: Icons.logout,
          title: 'Logout',
          isDestructive: true,
          onTap: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppColors.error : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? AppColors.error : null,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
