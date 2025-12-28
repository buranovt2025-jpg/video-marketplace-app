import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';

class SellerAnalyticsScreen extends StatefulWidget {
  const SellerAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<SellerAnalyticsScreen> createState() => _SellerAnalyticsScreenState();
}

class _SellerAnalyticsScreenState extends State<SellerAnalyticsScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  
  String _selectedPeriod = 'week'; // week, month, year, all
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _controller.fetchOrders();
    await _controller.fetchProducts();
    setState(() => _isLoading = false);
  }

  // Get seller's orders
  List<Map<String, dynamic>> get _sellerOrders {
    final sellerId = _controller.userId;
    return _controller.orders.where((o) => o['seller_id'] == sellerId).toList();
  }

  // Get orders for selected period
  List<Map<String, dynamic>> get _periodOrders {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedPeriod) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'year':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        return _sellerOrders;
    }
    
    return _sellerOrders.where((o) {
      final createdAt = DateTime.tryParse(o['created_at'] ?? '');
      return createdAt != null && createdAt.isAfter(startDate);
    }).toList();
  }

  // Calculate total revenue
  double get _totalRevenue {
    return _periodOrders.fold(0.0, (sum, order) {
      final total = order['total'] ?? order['total_amount'] ?? 0;
      return sum + (total is num ? total.toDouble() : 0);
    });
  }

  // Calculate completed orders revenue
  double get _completedRevenue {
    return _periodOrders
        .where((o) => o['status'] == 'delivered' || o['status'] == 'completed')
        .fold(0.0, (sum, order) {
      final total = order['total'] ?? order['total_amount'] ?? 0;
      return sum + (total is num ? total.toDouble() : 0);
    });
  }

  // Get order counts by status
  Map<String, int> get _ordersByStatus {
    final counts = <String, int>{};
    for (final order in _periodOrders) {
      final status = order['status'] ?? 'unknown';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  // Get top products by sales
  List<Map<String, dynamic>> get _topProducts {
    final productSales = <String, Map<String, dynamic>>{};
    
    for (final order in _periodOrders) {
      final items = order['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final productId = item['product_id'] ?? '';
        final productName = item['product_name'] ?? 'Товар';
        final quantity = item['quantity'] ?? 1;
        final price = item['price'] ?? 0;
        
        if (productSales.containsKey(productId)) {
          productSales[productId]!['quantity'] += quantity;
          productSales[productId]!['revenue'] += quantity * price;
        } else {
          productSales[productId] = {
            'id': productId,
            'name': productName,
            'quantity': quantity,
            'revenue': quantity * price,
          };
        }
      }
    }
    
    final sorted = productSales.values.toList()
      ..sort((a, b) => (b['revenue'] as num).compareTo(a['revenue'] as num));
    
    return sorted.take(5).toList();
  }

  // Get daily sales for chart
  List<Map<String, dynamic>> get _dailySales {
    final now = DateTime.now();
    final days = _selectedPeriod == 'week' ? 7 : 
                 _selectedPeriod == 'month' ? 30 : 12;
    
    final salesByDay = <String, double>{};
    
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.day}/${date.month}';
      salesByDay[key] = 0;
    }
    
    for (final order in _periodOrders) {
      final createdAt = DateTime.tryParse(order['created_at'] ?? '');
      if (createdAt != null) {
        final key = '${createdAt.day}/${createdAt.month}';
        final total = order['total'] ?? order['total_amount'] ?? 0;
        salesByDay[key] = (salesByDay[key] ?? 0) + (total is num ? total.toDouble() : 0);
      }
    }
    
    return salesByDay.entries
        .map((e) => {'date': e.key, 'amount': e.value})
        .toList()
        .reversed
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'analytics'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selector
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),
                    
                    // Revenue cards
                    _buildRevenueCards(),
                    const SizedBox(height: 24),
                    
                    // Orders by status
                    _buildOrdersStats(),
                    const SizedBox(height: 24),
                    
                    // Sales chart
                    _buildSalesChart(),
                    const SizedBox(height: 24),
                    
                    // Top products
                    _buildTopProducts(),
                    const SizedBox(height: 24),
                    
                    // Views and engagement
                    _buildEngagementStats(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodChip('week', 'Неделя'),
          _buildPeriodChip('month', 'Месяц'),
          _buildPeriodChip('year', 'Год'),
          _buildPeriodChip('all', 'Всё время'),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Выручка',
            _formatPrice(_totalRevenue),
            Icons.attach_money,
            primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Получено',
            _formatPrice(_completedRevenue),
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersStats() {
    final statuses = _ordersByStatus;
    final total = _periodOrders.length;
    final completed = (statuses['delivered'] ?? 0) + (statuses['completed'] ?? 0);
    final pending = statuses['pending'] ?? 0;
    final cancelled = statuses['cancelled'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Заказы',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOrderStat('Всего', total.toString(), Colors.white),
              _buildOrderStat('Выполнено', completed.toString(), Colors.green),
              _buildOrderStat('В ожидании', pending.toString(), Colors.orange),
              _buildOrderStat('Отменено', cancelled.toString(), Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          // Conversion rate
          if (total > 0) ...[
            Text(
              'Конверсия: ${((completed / total) * 100).toStringAsFixed(1)}%',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completed / total,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSalesChart() {
    final sales = _dailySales;
    if (sales.isEmpty) return const SizedBox.shrink();
    
    final maxAmount = sales.fold<double>(0, (max, s) {
      final amount = s['amount'] as double;
      return amount > max ? amount : max;
    });
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Продажи по дням',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sales.take(7).map((s) {
                final amount = s['amount'] as double;
                final height = maxAmount > 0 ? (amount / maxAmount) * 120 : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (amount > 0)
                          Text(
                            _formatShortPrice(amount),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 8,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          height: height.clamp(4.0, 120.0),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s['date'] as String,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    final products = _topProducts;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Топ товары',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            Center(
              child: Text(
                'Нет данных о продажах',
                style: TextStyle(color: Colors.grey[500]),
              ),
            )
          else
            ...products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: index == 0 ? Colors.amber :
                               index == 1 ? Colors.grey[400] :
                               index == 2 ? Colors.brown : Colors.grey[700],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'],
                            style: const TextStyle(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${product['quantity']} шт.',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatPrice(product['revenue'].toDouble()),
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEngagementStats() {
    // Get seller's reels and stories
    final sellerId = _controller.userId;
    final reels = _controller.reels.where((r) => r['author_id'] == sellerId).toList();
    final totalViews = reels.fold<int>(0, (sum, r) => sum + ((r['views'] ?? 0) as int));
    final totalLikes = reels.fold<int>(0, (sum, r) => sum + ((r['likes'] ?? 0) as int));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Вовлечённость',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEngagementStat(Icons.play_circle, 'Просмотры', _formatNumber(totalViews)),
              _buildEngagementStat(Icons.favorite, 'Лайки', _formatNumber(totalLikes)),
              _buildEngagementStat(Icons.video_library, 'Рилсы', reels.length.toString()),
              _buildEngagementStat(Icons.inventory_2, 'Товары', _controller.myProducts.length.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M сум';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K сум';
    }
    return '${price.toStringAsFixed(0)} сум';
  }

  String _formatShortPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
