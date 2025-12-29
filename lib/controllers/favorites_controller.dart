import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tiktok_tutorial/services/api_service.dart';

class FavoritesController extends GetxController {
  static FavoritesController get to => Get.find<FavoritesController>();
  
  final RxList<Map<String, dynamic>> _favorites = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> get favorites => _favorites;
  
  final RxSet<int> _favoriteIds = <int>{}.obs;
  
  final RxBool isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
  }
  
  Future<void> _loadFavorites() async {
    // Try to load from backend if logged in
    if (ApiService.isLoggedIn) {
      await _loadFromBackend();
    } else {
      await _loadFromLocal();
    }
  }
  
  Future<void> _loadFromBackend() async {
    try {
      isLoading.value = true;
      final data = await ApiService.getFavorites();
      _favorites.value = List<Map<String, dynamic>>.from(data);
      _favoriteIds.value = _favorites.map((f) => f['id'] as int).toSet();
    } catch (e) {
      print('Error loading favorites from backend: $e');
      // Fallback to local storage
      await _loadFromLocal();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString('favorites');
      if (favoritesJson != null) {
        final List<dynamic> decoded = json.decode(favoritesJson);
        _favorites.value = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        _favoriteIds.value = _favorites.map((f) {
          final id = f['id'];
          return id is int ? id : int.tryParse(id.toString()) ?? 0;
        }).toSet();
      }
    } catch (e) {
      print('Error loading favorites from local: $e');
    }
  }
  
  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('favorites', json.encode(_favorites));
    } catch (e) {
      print('Error saving favorites to local: $e');
    }
  }
  
  bool isFavorite(dynamic productId) {
    if (productId == null) return false;
    final id = productId is int ? productId : int.tryParse(productId.toString()) ?? 0;
    return _favoriteIds.contains(id);
  }
  
  Future<void> toggleFavorite(Map<String, dynamic> product) async {
    final productId = product['id'];
    if (productId == null) return;
    
    final id = productId is int ? productId : int.tryParse(productId.toString()) ?? 0;
    final wasFavorite = isFavorite(id);
    
    // Try backend first if logged in
    if (ApiService.isLoggedIn) {
      try {
        final result = await ApiService.toggleFavorite(id);
        final isFav = result['is_favorite'] ?? false;
        
        if (isFav) {
          _favoriteIds.add(id);
          Get.snackbar(
            'add_to_favorites'.tr,
            product['name'] ?? 'Product',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 1),
          );
        } else {
          _favoriteIds.remove(id);
          Get.snackbar(
            'remove_from_favorites'.tr,
            product['name'] ?? 'Product',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 1),
          );
        }
        
        // Refresh full list from backend
        await _loadFromBackend();
        return;
      } catch (e) {
        print('Error toggling favorite on backend: $e');
        // Fall through to local storage
      }
    }
    
    // Local storage fallback
    if (wasFavorite) {
      _favorites.removeWhere((item) => item['id'] == productId || item['id'] == id);
      _favoriteIds.remove(id);
      Get.snackbar(
        'remove_from_favorites'.tr,
        product['name'] ?? 'Product',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    } else {
      _favorites.add({
        'id': id,
        'name': product['name'],
        'price': product['price'],
        'image_url': product['image_url'],
        'seller_id': product['seller_id'],
        'seller_name': product['seller_name'],
        'added_at': DateTime.now().toIso8601String(),
      });
      _favoriteIds.add(id);
      Get.snackbar(
        'add_to_favorites'.tr,
        product['name'] ?? 'Product',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    }
    
    await _saveToLocal();
  }
  
  Future<void> addToFavorites(Map<String, dynamic> product) async {
    if (!isFavorite(product['id'])) {
      await toggleFavorite(product);
    }
  }
  
  Future<void> removeFromFavorites(dynamic productId) async {
    if (productId == null) return;
    final id = productId is int ? productId : int.tryParse(productId.toString()) ?? 0;
    
    if (ApiService.isLoggedIn) {
      try {
        await ApiService.toggleFavorite(id);
        await _loadFromBackend();
        return;
      } catch (e) {
        print('Error removing favorite from backend: $e');
      }
    }
    
    _favorites.removeWhere((item) {
      final itemId = item['id'];
      return itemId == productId || itemId == id;
    });
    _favoriteIds.remove(id);
    await _saveToLocal();
  }
  
  void clearFavorites() {
    _favorites.clear();
    _favoriteIds.clear();
    _saveToLocal();
  }
  
  // Refresh favorites (call after login)
  Future<void> refresh() async {
    await _loadFavorites();
  }
  
  int get count => _favorites.length;
}
