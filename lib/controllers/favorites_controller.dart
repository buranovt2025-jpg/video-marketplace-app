import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesController extends GetxController {
  static FavoritesController get to => Get.find<FavoritesController>();
  
  final RxList<Map<String, dynamic>> _favorites = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> get favorites => _favorites;
  
  final RxBool isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
  }
  
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString('favorites');
      if (favoritesJson != null) {
        final List<dynamic> decoded = json.decode(favoritesJson);
        _favorites.value = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }
  
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('favorites', json.encode(_favorites));
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }
  
  bool isFavorite(String productId) {
    return _favorites.any((item) => item['id'] == productId);
  }
  
  Future<void> toggleFavorite(Map<String, dynamic> product) async {
    final productId = product['id'];
    if (productId == null) return;
    
    if (isFavorite(productId)) {
      _favorites.removeWhere((item) => item['id'] == productId);
      Get.snackbar(
        'remove_from_favorites'.tr,
        product['name'] ?? 'Product',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    } else {
      _favorites.add({
        'id': productId,
        'name': product['name'],
        'price': product['price'],
        'image_url': product['image_url'],
        'seller_id': product['seller_id'],
        'seller_name': product['seller_name'],
        'added_at': DateTime.now().toIso8601String(),
      });
      Get.snackbar(
        'add_to_favorites'.tr,
        product['name'] ?? 'Product',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    }
    
    await _saveFavorites();
  }
  
  Future<void> addToFavorites(Map<String, dynamic> product) async {
    if (!isFavorite(product['id'])) {
      await toggleFavorite(product);
    }
  }
  
  Future<void> removeFromFavorites(String productId) async {
    _favorites.removeWhere((item) => item['id'] == productId);
    await _saveFavorites();
  }
  
  void clearFavorites() {
    _favorites.clear();
    _saveFavorites();
  }
  
  int get count => _favorites.length;
}
