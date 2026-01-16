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
      // ignore
    }
  }
  
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('favorites', json.encode(_favorites));
    } catch (e) {
      // ignore
    }
  }
  
  String _normalizeId(dynamic v) => (v ?? '').toString();

  bool isFavorite(String productId) {
    final id = _normalizeId(productId);
    if (id.trim().isEmpty) return false;
    return _favorites.any((item) => _normalizeId(item['id']) == id);
  }
  
  Future<void> toggleFavorite(Map<String, dynamic> product) async {
    final productId = _normalizeId(product['id']);
    if (productId.trim().isEmpty) return;
    
    if (isFavorite(productId)) {
      _favorites.removeWhere((item) => _normalizeId(item['id']) == productId);
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
        'category': product['category'],
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
    if (!isFavorite(_normalizeId(product['id']))) {
      await toggleFavorite(product);
    }
  }
  
  Future<void> removeFromFavorites(String productId) async {
    final id = _normalizeId(productId);
    _favorites.removeWhere((item) => _normalizeId(item['id']) == id);
    await _saveFavorites();
  }
  
  void clearFavorites() {
    _favorites.clear();
    _saveFavorites();
  }
  
  int get count => _favorites.length;
}
