import 'package:get/get.dart';
import 'package:tiktok_tutorial/services/api_service.dart';

class MarketplaceController extends GetxController {
  static MarketplaceController get instance => Get.find();
  
  // User state
  final Rx<Map<String, dynamic>?> currentUser = Rx<Map<String, dynamic>?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  // Products state
  final RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> myProducts = <Map<String, dynamic>>[].obs;
  
  // Content state
  final RxList<Map<String, dynamic>> reels = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> stories = <Map<String, dynamic>>[].obs;
  
  // Orders state
  final RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;
  
  // Chat state
  final RxList<Map<String, dynamic>> conversations = <Map<String, dynamic>>[].obs;
  final RxInt unreadCount = 0.obs;
  
  // Getters
  String get userId => currentUser.value?['id'] ?? '';
  String get userRole => currentUser.value?['role'] ?? '';
  String get userName => currentUser.value?['name'] ?? '';
  String get userEmail => currentUser.value?['email'] ?? '';
  String get userAvatar => currentUser.value?['avatar_url'] ?? '';
  bool get isSeller => userRole == 'seller';
  bool get isBuyer => userRole == 'buyer';
  bool get isCourier => userRole == 'courier';
  bool get isAdmin => userRole == 'admin';
  bool get isLoggedIn => currentUser.value != null;
  
  @override
  void onInit() {
    super.onInit();
    _initializeApi();
  }
  
  Future<void> _initializeApi() async {
    await ApiService.init();
    if (ApiService.isLoggedIn) {
      await fetchCurrentUser();
    }
  }
  
  // Auth methods
  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await ApiService.login(email, password);
      currentUser.value = response['user'];
      
      await _loadInitialData();
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await ApiService.register(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      currentUser.value = response['user'];
      
      await _loadInitialData();
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> logout() async {
    await ApiService.clearToken();
    currentUser.value = null;
    products.clear();
    myProducts.clear();
    reels.clear();
    stories.clear();
    orders.clear();
    conversations.clear();
    unreadCount.value = 0;
  }
  
  Future<void> fetchCurrentUser() async {
    try {
      final user = await ApiService.getMe();
      currentUser.value = user;
    } catch (e) {
      await logout();
    }
  }
  
  Future<void> _loadInitialData() async {
    await Future.wait([
      fetchProducts(),
      fetchReels(),
      fetchStories(),
      if (isLoggedIn) fetchOrders(),
      if (isLoggedIn) fetchUnreadCount(),
    ]);
  }
  
  // Products methods
  Future<void> fetchProducts({String? sellerId, String? category, String? search}) async {
    try {
      final data = await ApiService.getProducts(
        sellerId: sellerId,
        category: category,
        search: search,
      );
      products.value = List<Map<String, dynamic>>.from(data);
      
      if (isSeller && sellerId == null) {
        myProducts.value = products.where((p) => p['seller_id'] == userId).toList();
      }
    } catch (e) {
      error.value = e.toString();
    }
  }
  
  Future<void> fetchMyProducts() async {
    if (!isSeller && !isAdmin) return;
    
    try {
      final data = await ApiService.getProducts(sellerId: userId);
      myProducts.value = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      error.value = e.toString();
    }
  }
  
  Future<Map<String, dynamic>?> createProduct({
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    String? category,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final product = await ApiService.createProduct(
        name: name,
        price: price,
        description: description,
        imageUrl: imageUrl,
        category: category,
      );
      
      myProducts.add(product);
      products.add(product);
      
      return product;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final updated = await ApiService.updateProduct(productId, updates);
      
      final index = myProducts.indexWhere((p) => p['id'] == productId);
      if (index != -1) myProducts[index] = updated;
      
      final prodIndex = products.indexWhere((p) => p['id'] == productId);
      if (prodIndex != -1) products[prodIndex] = updated;
      
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> deleteProduct(String productId) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await ApiService.deleteProduct(productId);
      
      myProducts.removeWhere((p) => p['id'] == productId);
      products.removeWhere((p) => p['id'] == productId);
      
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Content methods
  Future<void> fetchReels() async {
    try {
      final data = await ApiService.getReels();
      reels.value = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      error.value = e.toString();
    }
  }
  
  Future<void> fetchStories() async {
    try {
      final data = await ApiService.getStories();
      stories.value = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      error.value = e.toString();
    }
  }
  
  Future<Map<String, dynamic>?> createReel({
    required String videoUrl,
    String? caption,
    String? productId,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final content = await ApiService.createContent(
        contentType: 'reel',
        videoUrl: videoUrl,
        caption: caption,
        productId: productId,
      );
      
      reels.insert(0, content);
      return content;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<Map<String, dynamic>?> createStory({
    String? videoUrl,
    String? imageUrl,
    String? caption,
    String? productId,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final content = await ApiService.createContent(
        contentType: 'story',
        videoUrl: videoUrl,
        imageUrl: imageUrl,
        caption: caption,
        productId: productId,
      );
      
      stories.insert(0, content);
      return content;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> likeContent(String contentId) async {
    try {
      await ApiService.likeContent(contentId);
    } catch (e) {
      error.value = e.toString();
    }
  }
  
  // Orders methods
  Future<void> fetchOrders() async {
    try {
      final data = await ApiService.getOrders();
      orders.value = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      error.value = e.toString();
    }
  }
  
  Future<Map<String, dynamic>?> createOrder({
    required String sellerId,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
    String? notes,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final order = await ApiService.createOrder(
        sellerId: sellerId,
        items: items,
        deliveryAddress: deliveryAddress,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        notes: notes,
      );
      
      orders.insert(0, order);
      return order;
    } catch (e) {
      error.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final updated = await ApiService.updateOrderStatus(orderId, status);
      
      final index = orders.indexWhere((o) => o['id'] == orderId);
      if (index != -1) orders[index] = updated;
      
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Chat methods
  Future<void> fetchConversations() async {
    try {
      final data = await ApiService.getConversations();
      conversations.value = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      error.value = e.toString();
    }
  }
  
  Future<void> fetchUnreadCount() async {
    try {
      unreadCount.value = await ApiService.getUnreadCount();
    } catch (e) {
      // Ignore errors for unread count
    }
  }
  
  Future<List<Map<String, dynamic>>> getChatMessages(String userId) async {
    try {
      final data = await ApiService.getChatMessages(userId);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      error.value = e.toString();
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> sendMessage(String receiverId, String content) async {
    try {
      final message = await ApiService.sendMessage(receiverId, content);
      return message;
    } catch (e) {
      error.value = e.toString();
      return null;
    }
  }
}
