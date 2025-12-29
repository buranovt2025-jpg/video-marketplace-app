import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryMapScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const DeliveryMapScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> with TickerProviderStateMixin {
  // Delivery coordinates
  late double _deliveryLat;
  late double _deliveryLng;
  
  // Courier coordinates (simulated)
  double _courierLat = 0;
  double _courierLng = 0;
  
  // Animation
  Timer? _locationTimer;
  int _updateCount = 0;
  double _estimatedMinutes = 15;
  bool _isDelivered = false;
  
  // Route points for simulation
  final List<Map<String, double>> _routePoints = [];
  int _currentRouteIndex = 0;

  @override
  void initState() {
    super.initState();
    _deliveryLat = (widget.order['delivery_latitude'] as num?)?.toDouble() ?? 41.2995;
    _deliveryLng = (widget.order['delivery_longitude'] as num?)?.toDouble() ?? 69.2401;
    
    // Generate simulated route from seller to buyer
    _generateRoute();
    
    // Start location updates
    _startLocationUpdates();
  }

  void _generateRoute() {
    // Simulate courier starting from a point ~2km away
    final random = Random();
    final startLat = _deliveryLat + (random.nextDouble() - 0.5) * 0.02;
    final startLng = _deliveryLng + (random.nextDouble() - 0.5) * 0.02;
    
    _courierLat = startLat;
    _courierLng = startLng;
    
    // Generate intermediate points
    const steps = 20;
    for (int i = 0; i <= steps; i++) {
      final progress = i / steps;
      _routePoints.add({
        'lat': startLat + (_deliveryLat - startLat) * progress,
        'lng': startLng + (_deliveryLng - startLng) * progress,
      });
    }
  }

  void _startLocationUpdates() {
    // Update courier location every 3 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentRouteIndex < _routePoints.length - 1) {
        setState(() {
          _currentRouteIndex++;
          _courierLat = _routePoints[_currentRouteIndex]['lat']!;
          _courierLng = _routePoints[_currentRouteIndex]['lng']!;
          _updateCount++;
          
          // Calculate estimated time
          final remaining = _routePoints.length - _currentRouteIndex - 1;
          _estimatedMinutes = (remaining * 3 / 60 * 5).clamp(1, 60);
        });
      } else {
        setState(() {
          _isDelivered = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  double _calculateDistance() {
    // Haversine formula for distance calculation
    const R = 6371.0; // Earth's radius in km
    final dLat = _toRadians(_deliveryLat - _courierLat);
    final dLng = _toRadians(_deliveryLng - _courierLng);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(_courierLat)) * cos(_toRadians(_deliveryLat)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    final distance = _calculateDistance();
    final status = widget.order['status'] ?? 'in_transit';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text(
          'Отслеживание доставки',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            onPressed: _openInExternalMaps,
            tooltip: 'Открыть в навигаторе',
          ),
        ],
      ),
      body: Column(
        children: [
          // Map view (simulated with custom widget)
          Expanded(
            flex: 3,
            child: _buildMapView(),
          ),
          
          // Delivery info panel
          Expanded(
            flex: 2,
            child: _buildInfoPanel(distance, status),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Stack(
        children: [
          // Map background with grid
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              painter: _MapGridPainter(),
              child: Container(),
            ),
          ),
          
          // Route line
          CustomPaint(
            painter: _RoutePainter(
              routePoints: _routePoints,
              currentIndex: _currentRouteIndex,
              deliveryLat: _deliveryLat,
              deliveryLng: _deliveryLng,
            ),
            child: Container(),
          ),
          
          // Delivery destination marker
          Positioned(
            bottom: 80,
            right: 80,
            child: _buildMarker(
              icon: Icons.home,
              color: Colors.green,
              label: 'Доставка',
            ),
          ),
          
          // Courier marker (animated position)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            top: 60 + (_currentRouteIndex * 8).clamp(0, 200).toDouble(),
            left: 60 + (_currentRouteIndex * 10).clamp(0, 200).toDouble(),
            child: _buildMarker(
              icon: Icons.delivery_dining,
              color: primaryColor,
              label: 'Курьер',
              isAnimated: true,
            ),
          ),
          
          // Live indicator
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isDelivered ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: _isDelivered ? null : [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isDelivered ? 'Доставлено' : 'LIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Zoom controls
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                _buildZoomButton(Icons.add, () {}),
                const SizedBox(height: 8),
                _buildZoomButton(Icons.remove, () {}),
              ],
            ),
          ),
          
          // Open in maps button
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _openInExternalMaps,
              backgroundColor: primaryColor,
              child: const Icon(Icons.navigation, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarker({
    required IconData icon,
    required Color color,
    required String label,
    bool isAnimated = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: isAnimated ? 12 : 8,
                spreadRadius: isAnimated ? 4 : 2,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildInfoPanel(double distance, String status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Courier info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor.withOpacity(0.2),
                child: Icon(Icons.person, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order['courier_name'] ?? 'Курьер в пути',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '4.9',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.delivery_dining, color: Colors.grey[400], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_updateCount * 50 + 100}+ доставок',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Call courier button
              IconButton(
                onPressed: _callCourier,
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Delivery stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.timer,
                  value: _isDelivered ? 'Доставлено!' : '~${_estimatedMinutes.toInt()} мин',
                  label: 'Время',
                  color: _isDelivered ? Colors.green : primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.route,
                  value: '${(distance * 1000).toInt()} м',
                  label: 'Расстояние',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.speed,
                  value: _isDelivered ? '0' : '~25',
                  label: 'км/ч',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const Spacer(),
          
          // Delivery address
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Адрес доставки',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.order['delivery_address'] ?? 'Адрес не указан',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callCourier() async {
    final phone = widget.order['courier_phone'] ?? '+998901234568';
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось позвонить курьеру',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _openInExternalMaps() async {
    final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$_deliveryLat,$_deliveryLng&origin=$_courierLat,$_courierLng';
    final yandexMapsUrl = 'yandexmaps://maps.yandex.ru/?rtext=$_courierLat,$_courierLng~$_deliveryLat,$_deliveryLng&rtt=auto';
    
    try {
      if (await canLaunchUrl(Uri.parse(yandexMapsUrl))) {
        await launchUrl(Uri.parse(yandexMapsUrl));
      } else {
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось открыть навигатор',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

// Custom painter for map grid background
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 0.5;

    // Draw grid
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some "roads"
    final roadPaint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3), roadPaint);
    canvas.drawLine(Offset(size.width * 0.4, 0), Offset(size.width * 0.4, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), roadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for route line
class _RoutePainter extends CustomPainter {
  final List<Map<String, double>> routePoints;
  final int currentIndex;
  final double deliveryLat;
  final double deliveryLng;

  _RoutePainter({
    required this.routePoints,
    required this.currentIndex,
    required this.deliveryLat,
    required this.deliveryLng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (routePoints.isEmpty) return;

    // Draw completed route (green)
    final completedPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw remaining route (dashed blue)
    final remainingPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Simple visualization - draw from top-left to bottom-right
    final startX = 80.0;
    final startY = 80.0;
    final endX = size.width - 100;
    final endY = size.height - 100;

    final progress = currentIndex / (routePoints.length - 1);
    final currentX = startX + (endX - startX) * progress;
    final currentY = startY + (endY - startY) * progress;

    // Draw completed path
    canvas.drawLine(Offset(startX, startY), Offset(currentX, currentY), completedPaint);

    // Draw remaining path (dashed)
    _drawDashedLine(canvas, Offset(currentX, currentY), Offset(endX, endY), remainingPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 10.0;
    const dashSpace = 5.0;
    
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    
    for (int i = 0; i < dashCount; i++) {
      final startFraction = i * (dashWidth + dashSpace) / distance;
      final endFraction = (i * (dashWidth + dashSpace) + dashWidth) / distance;
      
      canvas.drawLine(
        Offset(start.dx + dx * startFraction, start.dy + dy * startFraction),
        Offset(start.dx + dx * endFraction, start.dy + dy * endFraction),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex;
  }
}
