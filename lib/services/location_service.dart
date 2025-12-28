import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService extends GetxService {
  static LocationService get to => Get.find<LocationService>();
  
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  Future<LocationService> init() async {
    await _checkPermissions();
    return this;
  }
  
  Future<bool> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      error.value = 'Службы геолокации отключены';
      return false;
    }
    
    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        error.value = 'Доступ к геолокации запрещён';
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      error.value = 'Доступ к геолокации запрещён навсегда. Включите в настройках.';
      return false;
    }
    
    return true;
  }
  
  // Get current location
  Future<Position?> getCurrentLocation() async {
    isLoading.value = true;
    error.value = '';
    
    try {
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        isLoading.value = false;
        return null;
      }
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      currentPosition.value = position;
      isLoading.value = false;
      return position;
    } catch (e) {
      error.value = 'Не удалось получить местоположение: $e';
      isLoading.value = false;
      return null;
    }
  }
  
  // Calculate distance between two points in meters
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
  
  // Format distance for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} м';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} км';
    }
  }
  
  // Open navigation to destination (Google Maps, Yandex Maps, etc.)
  Future<void> openNavigation({
    required double destinationLat,
    required double destinationLng,
    String? destinationName,
  }) async {
    // Try Google Maps first
    final googleMapsUrl = Uri.parse(
      'google.navigation:q=$destinationLat,$destinationLng&mode=d',
    );
    
    // Fallback to web Google Maps
    final webGoogleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng&travelmode=driving',
    );
    
    // Yandex Maps URL
    final yandexMapsUrl = Uri.parse(
      'yandexmaps://maps.yandex.ru/?rtext=~$destinationLat,$destinationLng&rtt=auto',
    );
    
    // Try to launch navigation apps in order of preference
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else if (await canLaunchUrl(yandexMapsUrl)) {
      await launchUrl(yandexMapsUrl);
    } else if (await canLaunchUrl(webGoogleMapsUrl)) {
      await launchUrl(webGoogleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      error.value = 'Не удалось открыть навигатор';
      Get.snackbar(
        'Ошибка',
        'Не удалось открыть навигатор',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  // Open location in maps (for viewing, not navigation)
  Future<void> openLocationInMaps({
    required double lat,
    required double lng,
    String? label,
  }) async {
    final encodedLabel = Uri.encodeComponent(label ?? 'Местоположение');
    
    // Google Maps URL
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    
    // Yandex Maps URL
    final yandexMapsUrl = Uri.parse(
      'yandexmaps://maps.yandex.ru/?pt=$lng,$lat&z=17&l=map',
    );
    
    if (await canLaunchUrl(yandexMapsUrl)) {
      await launchUrl(yandexMapsUrl);
    } else if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      error.value = 'Не удалось открыть карту';
    }
  }
  
  // Stream location updates (for real-time tracking)
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }
  
  // Check if location is within delivery radius
  bool isWithinDeliveryRadius({
    required double centerLat,
    required double centerLng,
    required double targetLat,
    required double targetLng,
    double radiusInKm = 20, // Default 20km radius
  }) {
    final distance = calculateDistance(centerLat, centerLng, targetLat, targetLng);
    return distance <= radiusInKm * 1000;
  }
  
  // Get estimated delivery time based on distance
  String getEstimatedDeliveryTime(double distanceInMeters) {
    // Assume average speed of 30 km/h in city
    final hours = distanceInMeters / 1000 / 30;
    final minutes = (hours * 60).round();
    
    if (minutes < 60) {
      return '$minutes мин';
    } else {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return '$h ч ${m > 0 ? '$m мин' : ''}';
    }
  }
}
