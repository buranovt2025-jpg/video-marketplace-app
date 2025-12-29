import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gogomarket/constants.dart';
import 'package:gogomarket/controllers/marketplace_controller.dart';
import 'package:gogomarket/services/location_service.dart';

class NearbySellersScreen extends StatefulWidget {
  const NearbySellersScreen({Key? key}) : super(key: key);

  @override
  State<NearbySellersScreen> createState() => _NearbySellersScreenState();
}

class _NearbySellersScreenState extends State<NearbySellersScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  final LocationService _locationService = Get.find<LocationService>();
  
  Position? _currentPosition;
  bool _isLoading = true;
  String? _error;
  double _maxDistance = 10.0; // km
  
  List<Map<String, dynamic>> _nearbySellers = [];

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        _loadNearbySellers();
      } else {
        setState(() {
          _error = 'location_error'.tr;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _loadNearbySellers() {
    if (_currentPosition == null) return;

    // Get all products and extract unique sellers with their locations
    final products = _controller.products;
    final Map<String, Map<String, dynamic>> sellersMap = {};

    for (final product in products) {
      final sellerId = product['seller_id'];
      if (sellerId != null && !sellersMap.containsKey(sellerId)) {
        // Simulate seller location (in real app, this would come from API)
        // For demo, we'll use random offsets from current position
        final sellerLat = _currentPosition!.latitude + (sellerId.hashCode % 100) * 0.001;
        final sellerLng = _currentPosition!.longitude + (sellerId.hashCode % 50) * 0.001;
        
        final distance = _locationService.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          sellerLat,
          sellerLng,
        );

        sellersMap[sellerId] = {
          'id': sellerId,
          'name': product['seller_name'] ?? 'Продавец',
          'latitude': sellerLat,
          'longitude': sellerLng,
          'distance': distance,
          'products_count': products.where((p) => p['seller_id'] == sellerId).length,
          'rating': 4.5 + (sellerId.hashCode % 5) * 0.1,
          'is_verified': sellerId.hashCode % 3 == 0,
        };
      }
    }

    // Filter by max distance and sort by distance
    _nearbySellers = sellersMap.values
        .where((s) => s['distance'] <= _maxDistance)
        .toList()
      ..sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    setState(() {
      _isLoading = false;
    });
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
          'nearby_sellers'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Distance filter
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.location_on, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Радиус: ${_maxDistance.toInt()} км',
                  style: const TextStyle(color: Colors.white),
                ),
                Expanded(
                  child: Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: primaryColor,
                    inactiveColor: Colors.grey[700],
                    onChanged: (value) {
                      setState(() {
                        _maxDistance = value;
                      });
                      _loadNearbySellers();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text(
              'Поиск продавцов рядом...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadLocation,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_nearbySellers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Нет продавцов в радиусе ${_maxDistance.toInt()} км',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте увеличить радиус поиска',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _nearbySellers.length,
      itemBuilder: (context, index) {
        final seller = _nearbySellers[index];
        return _buildSellerCard(seller);
      },
    );
  }

  Widget _buildSellerCard(Map<String, dynamic> seller) {
    final distance = seller['distance'] as double;
    final isVerified = seller['is_verified'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[800],
              child: Icon(Icons.store, color: Colors.grey[600], size: 28),
            ),
            if (isVerified)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                seller['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isVerified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'verified_seller'.tr,
                  style: const TextStyle(color: Colors.blue, fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: primaryColor),
                const SizedBox(width: 4),
                Text(
                  _formatDistance(distance),
                  style: TextStyle(color: primaryColor),
                ),
                const SizedBox(width: 16),
                Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${seller['rating']?.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.amber),
                ),
                const SizedBox(width: 16),
                Icon(Icons.inventory_2, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${seller['products_count']} товаров',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.navigation, color: primaryColor),
          onPressed: () => _locationService.openLocationInMaps(
            lat: seller['latitude'],
            lng: seller['longitude'],
            label: seller['name'],
          ),
        ),
        onTap: () {
          // Navigate to seller's products
          Get.snackbar(
            seller['name'],
            'Показать товары продавца',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      ),
    );
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).toInt()} м';
    }
    return '${distance.toStringAsFixed(1)} км';
  }
}
