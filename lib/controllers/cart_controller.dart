import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktok_tutorial/utils/formatters.dart';

class CartItem {
  final String productId;
  final String productName;
  final double price;
  final String? imageUrl;
  final String sellerId;
  final String sellerName;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toOrderItem() => {
    // Backend может ожидать int, но в UI ID часто хранится как String.
    // Отправляем int, если строка числовая, иначе отправляем как есть.
    'product_id': int.tryParse(productId) ?? productId,
    'quantity': quantity,
    'price': price,
  };

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'price': price,
        'image_url': imageUrl,
        'seller_id': sellerId,
        'seller_name': sellerName,
        'quantity': quantity,
      };

  static CartItem? fromJson(Map<String, dynamic> json) {
    try {
      final productId = (json['product_id'] ?? '').toString();
      final sellerId = (json['seller_id'] ?? '').toString();
      if (productId.trim().isEmpty || sellerId.trim().isEmpty) return null;

      return CartItem(
        productId: productId,
        productName: (json['product_name'] ?? '').toString(),
        price: asDouble(json['price']),
        imageUrl: json['image_url']?.toString(),
        sellerId: sellerId,
        sellerName: (json['seller_name'] ?? '').toString(),
        quantity: (json['quantity'] is int) ? json['quantity'] as int : int.tryParse((json['quantity'] ?? '1').toString()) ?? 1,
      );
    } catch (_) {
      return null;
    }
  }
}

class CartController extends GetxController {
  static CartController get instance => Get.find();

  final RxList<CartItem> items = <CartItem>[].obs;
  static const _prefsKey = 'cart_items_v1';
  Timer? _saveDebounce;
  
  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);
  
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  
  bool get isEmpty => items.isEmpty;

  @override
  void onInit() {
    super.onInit();
    // Best-effort restore (do not block app startup).
    // ignore: discarded_futures
    _restore();
    ever(items, (_) => _scheduleSave());
  }

  @override
  void onClose() {
    _saveDebounce?.cancel();
    super.onClose();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final restored = <CartItem>[];
      for (final e in decoded) {
        if (e is Map) {
          final item = CartItem.fromJson(Map<String, dynamic>.from(e));
          if (item != null) restored.add(item);
        }
      }
      if (restored.isNotEmpty) {
        items.assignAll(restored);
      }
    } catch (_) {
      // ignore
    }
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 250), () {
      // ignore: discarded_futures
      _save();
    });
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, raw);
    } catch (_) {
      // ignore
    }
  }
  
  // Get unique sellers in cart
  List<String> get sellerIds => items.map((e) => e.sellerId).toSet().toList();
  
  // Get items by seller
  List<CartItem> getItemsBySeller(String sellerId) {
    return items.where((item) => item.sellerId == sellerId).toList();
  }
  
  // Get total for a specific seller
  double getTotalBySeller(String sellerId) {
    return getItemsBySeller(sellerId).fold(0, (sum, item) => sum + item.total);
  }

  void addToCart(Map<String, dynamic> product, {int quantity = 1}) {
    final existingIndex = items.indexWhere((item) => item.productId == product['id'].toString());
    
    if (existingIndex != -1) {
      items[existingIndex].quantity += quantity;
      items.refresh();
    } else {
      items.add(CartItem(
        productId: product['id'].toString(),
        productName: product['name'],
        price: asDouble(product['price']),
        imageUrl: product['image_url'],
        sellerId: product['seller_id'].toString(),
        sellerName: (product['seller_name'] ?? '').toString().isNotEmpty ? product['seller_name'] : 'seller_fallback'.tr,
        quantity: quantity,
      ));
    }
  }

  void removeFromCart(String productId) {
    items.removeWhere((item) => item.productId == productId);
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    
    final index = items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      items[index].quantity = quantity;
      items.refresh();
    }
  }

  void incrementQuantity(String productId) {
    final index = items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      items[index].quantity++;
      items.refresh();
    }
  }

  void decrementQuantity(String productId) {
    final index = items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      if (items[index].quantity > 1) {
        items[index].quantity--;
        items.refresh();
      } else {
        removeFromCart(productId);
      }
    }
  }

  void clearCart() {
    items.clear();
  }

  void clearSellerItems(String sellerId) {
    items.removeWhere((item) => item.sellerId == sellerId);
  }

  bool isInCart(String productId) {
    return items.any((item) => item.productId == productId);
  }

  int getQuantity(String productId) {
    final item = items.firstWhereOrNull((item) => item.productId == productId);
    return item?.quantity ?? 0;
  }
}
