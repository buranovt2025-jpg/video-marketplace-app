import 'package:get/get.dart';

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
    'product_id': int.tryParse(productId) ?? 0,
    'quantity': quantity,
    'price': price,
  };
}

class CartController extends GetxController {
  static CartController get instance => Get.find();

  final RxList<CartItem> items = <CartItem>[].obs;
  
  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);
  
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  
  bool get isEmpty => items.isEmpty;
  
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
    final existingIndex = items.indexWhere((item) => item.productId == product['id']);
    
    if (existingIndex != -1) {
      items[existingIndex].quantity += quantity;
      items.refresh();
    } else {
      items.add(CartItem(
        productId: product['id'],
        productName: product['name'],
        price: (product['price'] as num).toDouble(),
        imageUrl: product['image_url'],
        sellerId: product['seller_id'],
        sellerName: product['seller_name'] ?? 'Продавец',
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
