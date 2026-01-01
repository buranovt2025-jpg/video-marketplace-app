import 'package:get/get.dart';
import 'package:tiktok_tutorial/services/api_service.dart';

class MarketplaceController extends GetxController {
  static MarketplaceController get instance => Get.find();
  
    // User state
    final Rx<Map<String, dynamic>?> currentUser = Rx<Map<String, dynamic>?>(null);
    final RxBool isLoading = false.obs;
    final RxString error = ''.obs;
    final RxBool isGuestMode = false.obs;
  
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
  bool get isGuest => isGuestMode.value;
  
  Future<void> _handleApiError(Object e, {String? fallbackMessage, bool ignore = false}) async {
    if (e is ApiException) {
      // If token became invalid anywhere, treat it as logged out.
      if (e.statusCode == 401) {
        await logout();
        if (!ignore) {
          error.value = 'Сессия истекла. Войдите снова.';
        }
        return;
      }
      if (!ignore) {
        error.value = e.message.isNotEmpty ? e.message : (fallbackMessage ?? e.toString());
      }
      return;
    }
    if (!ignore) {
      error.value = fallbackMessage ?? e.toString();
    }
  }
  
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
      await _handleApiError(e, fallbackMessage: 'Не удалось войти');
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
      await _handleApiError(e, fallbackMessage: 'Не удалось зарегистрироваться');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
    Future<void> logout() async {
      await ApiService.clearToken();
      currentUser.value = null;
      isGuestMode.value = false;
      products.clear();
      myProducts.clear();
      reels.clear();
      stories.clear();
      orders.clear();
      conversations.clear();
      unreadCount.value = 0;
    }
  
    void setGuestMode(bool value) {
      isGuestMode.value = value;
      if (value) {
        // Set a guest user for browsing
        currentUser.value = null;
        _loadInitialData();
      }
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
      await _handleApiError(e, fallbackMessage: 'Не удалось загрузить товары');
    }
  }
  
  Future<void> fetchMyProducts() async {
    if (!isSeller && !isAdmin) return;
    
    try {
      final data = await ApiService.getProducts(sellerId: userId);
      myProducts.value = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      await _handleApiError(e, fallbackMessage: 'Не удалось загрузить мои товары');
    }
  }
  
  Future<Map<String, dynamic>?> createProduct({
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    String? category,
    int? quantity,
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
        quantity: quantity,
      );
      
      myProducts.add(product);
      products.add(product);
      
      return product;
    } catch (e) {
      await _handleApiError(e, fallbackMessage: 'Не удалось создать товар');
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
      await _handleApiError(e, fallbackMessage: 'Не удалось обновить товар');
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
      await _handleApiError(e, fallbackMessage: 'Не удалось удалить товар');
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
      await _handleApiError(e, fallbackMessage: 'Не удалось загрузить рилсы', ignore: true);
    }
  }
  
  Future<void> fetchStories() async {
    try {
      final data = await ApiService.getStories();
      stories.value = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      await _handleApiError(e, fallbackMessage: 'Не удалось загрузить истории', ignore: true);
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
      await _handleApiError(e, fallbackMessage: 'Не удалось создать рилс');
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
      await _handleApiError(e, fallbackMessage: 'Не удалось создать историю');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> likeContent(String contentId) async {
    // Keep backward compatibility for existing call sites.
    await toggleLikeOnReel(contentId);
  }

  Future<void> toggleLikeOnReel(String contentId) async {
    final id = contentId.trim();
    if (id.isEmpty) return;

    final idx = reels.indexWhere((r) => (r['id']?.toString() ?? '') == id);
    Map<String, dynamic>? before;
    if (idx != -1) {
      before = Map<String, dynamic>.from(reels[idx]);
      final liked = (before['liked_by_me'] == true) || (before['liked'] == true);
      final likes0 = (before['likes_count'] ?? before['likes'] ?? 0);
      final likes = likes0 is num ? likes0.toInt() : int.tryParse(likes0.toString()) ?? 0;
      final nextLikes = (liked ? (likes - 1) : (likes + 1)).clamp(0, 1 << 30);

      final updated = Map<String, dynamic>.from(before);
      updated['liked_by_me'] = !liked;
      updated['liked'] = !liked;
      updated['likes_count'] = nextLikes;
      updated['likes'] = nextLikes;
      reels[idx] = updated;
    }

    try {
      final updated = await ApiService.likeContent(id);
      if (idx != -1) {
        // Merge server response over local optimistic state.
        final merged = <String, dynamic>{
          ...reels[idx],
          ...updated,
        };
        reels[idx] = merged;
      }
    } catch (e) {
      // Revert optimistic update.
      if (idx != -1 && before != null) {
        reels[idx] = before;
      }
      await _handleApiError(e, fallbackMessage: 'Не удалось поставить лайк', ignore: true);
    }
  }
  
  // Orders methods
  Future<void> fetchOrders() async {
    try {
      final data = await ApiService.getOrders();
      orders.value = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      await _handleApiError(e, fallbackMessage: 'Не удалось загрузить заказы');
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
      await _handleApiError(e, fallbackMessage: 'Не удалось создать заказ');
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
      await _handleApiError(e, fallbackMessage: 'Не удалось обновить статус заказа');
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
      await _handleApiError(e, fallbackMessage: 'Не удалось загрузить чаты');
    }
  }
  
  Future<void> fetchUnreadCount() async {
    try {
      unreadCount.value = await ApiService.getUnreadCount();
    } catch (e) {
      await _handleApiError(e, fallbackMessage: 'Не удалось получить непрочитанные', ignore: true);
    }
  }
  
  Future<List<Map<String, dynamic>>> getChatMessages(String userId, {bool throwOnError = false}) async {
    try {
      final data = await ApiService.getChatMessages(userId);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      await _handleApiError(e, fallbackMessage: 'Не удалось загрузить сообщения', ignore: throwOnError);
      if (throwOnError) rethrow;
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> sendMessage(String receiverId, String content) async {
    try {
      final message = await ApiService.sendMessage(receiverId, content);
      return message;
    } catch (e) {
      await _handleApiError(e, fallbackMessage: 'Не удалось отправить сообщение');
      return null;
    }
  }
}
