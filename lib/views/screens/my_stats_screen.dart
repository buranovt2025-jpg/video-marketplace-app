import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gogomarket/constants.dart';
import 'package:gogomarket/services/api_service.dart';
import 'package:gogomarket/controllers/marketplace_controller.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MyStatsScreen extends StatefulWidget {
  const MyStatsScreen({Key? key}) : super(key: key);

  @override
  State<MyStatsScreen> createState() => _MyStatsScreenState();
}

class _MyStatsScreenState extends State<MyStatsScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await ApiService.getMyStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _exportStats() async {
    setState(() => _isExporting = true);

    try {
      final csvContent = await ApiService.exportMyStats();
      
      final directory = await getTemporaryDirectory();
      final role = _stats?['role'] ?? 'user';
      final file = File('${directory.path}/${role}_report.csv');
      await file.writeAsString(csvContent);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'My Statistics Report',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0';
    final num = (value is int) ? value.toDouble() : (value as double);
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'My Statistics',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_stats != null)
            IconButton(
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download),
              onPressed: _isExporting ? null : _exportStats,
              tooltip: 'Export CSV',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load statistics',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadStats,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: _buildStatsContent(),
                  ),
                ),
    );
  }

  Widget _buildStatsContent() {
    if (_stats == null) return const SizedBox();

    final role = _stats!['role'] as String;

    switch (role) {
      case 'seller':
        return _buildSellerStats();
      case 'courier':
        return _buildCourierStats();
      case 'buyer':
        return _buildBuyerStats();
      default:
        return Center(
          child: Text(
            _stats!['message'] ?? 'No statistics available',
            style: const TextStyle(color: Colors.white),
          ),
        );
    }
  }

  Widget _buildSellerStats() {
    final orders = _stats!['orders'] as Map<String, dynamic>;
    final revenue = _stats!['revenue'] as Map<String, dynamic>;
    final rating = _stats!['rating'] as Map<String, dynamic>;
    final products = _stats!['products'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRoleHeader('Seller Dashboard', Icons.store, Colors.orange),
        const SizedBox(height: 24),

        // Revenue section
        _buildSectionTitle('Revenue'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Revenue',
                '${_formatPrice(revenue['total'])} sum',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Net Earnings',
                '${_formatPrice(revenue['net_earnings'])} sum',
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          'Commission: ${revenue['commission_rate']}% (${_formatPrice(revenue['commission_amount'])} sum)',
          Icons.percent,
          Colors.orange,
        ),
        const SizedBox(height: 24),

        // Orders section
        _buildSectionTitle('Orders'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMiniStat('Total', orders['total'], Colors.blue)),
            Expanded(child: _buildMiniStat('Completed', orders['completed'], Colors.green)),
            Expanded(child: _buildMiniStat('Pending', orders['pending'], Colors.orange)),
            Expanded(child: _buildMiniStat('Cancelled', orders['cancelled'], Colors.red)),
          ],
        ),
        const SizedBox(height: 24),

        // Products & Rating
        _buildSectionTitle('Products & Rating'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Products',
                products.toString(),
                Icons.inventory,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Rating',
                '${(rating['average'] as double).toStringAsFixed(1)} / 5',
                Icons.star,
                Colors.amber,
                subtitle: '${rating['total_reviews']} reviews',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCourierStats() {
    final deliveries = _stats!['deliveries'] as Map<String, dynamic>;
    final earnings = _stats!['earnings'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRoleHeader('Courier Dashboard', Icons.delivery_dining, Colors.green),
        const SizedBox(height: 24),

        // Earnings section
        _buildSectionTitle('Earnings'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Earnings',
                '${_formatPrice(earnings['total_earnings'])} sum',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Fee per Delivery',
                '${_formatPrice(earnings['fee_per_delivery'])} sum',
                Icons.local_shipping,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Deliveries section
        _buildSectionTitle('Deliveries'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMiniStat('Total', deliveries['total'], Colors.blue)),
            Expanded(child: _buildMiniStat('Completed', deliveries['completed'], Colors.green)),
            Expanded(child: _buildMiniStat('In Progress', deliveries['in_progress'], Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildBuyerStats() {
    final orders = _stats!['orders'] as Map<String, dynamic>;
    final spending = _stats!['spending'] as Map<String, dynamic>;
    final activity = _stats!['activity'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRoleHeader('Buyer Dashboard', Icons.shopping_bag, Colors.blue),
        const SizedBox(height: 24),

        // Spending section
        _buildSectionTitle('Spending'),
        const SizedBox(height: 12),
        _buildStatCard(
          'Total Spent',
          '${_formatPrice(spending['total_spent'])} sum',
          Icons.attach_money,
          Colors.green,
          fullWidth: true,
        ),
        const SizedBox(height: 24),

        // Orders section
        _buildSectionTitle('Orders'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMiniStat('Total', orders['total'], Colors.blue)),
            Expanded(child: _buildMiniStat('Completed', orders['completed'], Colors.green)),
            Expanded(child: _buildMiniStat('Pending', orders['pending'], Colors.orange)),
            Expanded(child: _buildMiniStat('Cancelled', orders['cancelled'], Colors.red)),
          ],
        ),
        const SizedBox(height: 24),

        // Activity section
        _buildSectionTitle('Activity'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Favorites',
                activity['favorites'].toString(),
                Icons.favorite,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Reviews',
                activity['reviews'].toString(),
                Icons.rate_review,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 48, color: Colors.white),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
