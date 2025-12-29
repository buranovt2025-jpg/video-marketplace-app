import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gogomarket/services/http_client_factory.dart';

// Helper function to decode response body as UTF-8
dynamic _decodeResponse(http.Response response) {
  return jsonDecode(utf8.decode(response.bodyBytes));
}

class ApiService {
  static const String baseUrl = 'https://165.232.81.31';
  static String? _token;
  static http.Client? _client;
  
  // Create HTTP client (uses IOClient with self-signed cert support on mobile, regular Client on web)
  static http.Client get client {
    _client ??= createHttpClient();
    return _client!;
  }
  
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }
  
  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  static String? get token => _token;
  static bool get isLoggedIn => _token != null;
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
  
  // Auth endpoints
  static Future<Map<String, dynamic>> login(String email, String password) async {
        final response = await client.post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        );
    
    if (response.statusCode == 200) {
      final data = _decodeResponse(response);
      await setToken(data['access_token']);
      return data;
    } else {
      throw ApiException(response.statusCode, _decodeResponse(response)['detail'] ?? 'Login failed');
    }
  }
  
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'role': role,
        'phone': phone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = _decodeResponse(response);
      await setToken(data['access_token']);
      return data;
    } else {
      throw ApiException(response.statusCode, _decodeResponse(response)['detail'] ?? 'Registration failed');
    }
  }
  
  static Future<Map<String, dynamic>> getMe() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get user');
    }
  }
  
  static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> updates) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: _headers,
      body: jsonEncode(updates),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to update user');
    }
  }
  
  // Multi-role management endpoints
  static Future<Map<String, dynamic>> switchRole(String role) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/auth/switch-role'),
      headers: _headers,
      body: jsonEncode({'role': role}),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, _decodeResponse(response)['detail'] ?? 'Failed to switch role');
    }
  }
  
  static Future<Map<String, dynamic>> addRole(String role) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/auth/add-role'),
      headers: _headers,
      body: jsonEncode({'role': role}),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, _decodeResponse(response)['detail'] ?? 'Failed to add role');
    }
  }
  
  static Future<Map<String, dynamic>> getMyRoles() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/auth/roles'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get roles');
    }
  }
  
  // Products endpoints
  static Future<List<dynamic>> getProducts({String? sellerId, String? category, String? search}) async {
    final queryParams = <String, String>{};
    if (sellerId != null) queryParams['seller_id'] = sellerId;
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;
    
    final uri = Uri.parse('$baseUrl/api/products').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await client.get(uri, headers: _headers);
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get products');
    }
  }
  
  static Future<Map<String, dynamic>> getProduct(String productId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/products/$productId'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get product');
    }
  }
  
  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    String? category,
    int? quantity,
    bool inStock = true,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/products'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'price': price,
        'description': description,
        'image_url': imageUrl,
        'category': category,
        'quantity': quantity ?? 1,
        'in_stock': inStock,
      }),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to create product');
    }
  }
  
  static Future<Map<String, dynamic>> updateProduct(String productId, Map<String, dynamic> updates) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/products/$productId'),
      headers: _headers,
      body: jsonEncode(updates),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to update product');
    }
  }
  
  static Future<void> deleteProduct(String productId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/products/$productId'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to delete product');
    }
  }
  
  // Content endpoints (Reels & Stories)
  static Future<List<dynamic>> getReels({int page = 1, int perPage = 10}) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/content/reels?page=$page&per_page=$perPage'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get reels');
    }
  }
  
  static Future<List<dynamic>> getStories() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/content/stories'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get stories');
    }
  }
  
  static Future<Map<String, dynamic>> createContent({
    required String contentType, // 'reel' or 'story'
    String? videoUrl,
    String? imageUrl,
    String? caption,
    String? productId,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/content'),
      headers: _headers,
      body: jsonEncode({
        'content_type': contentType,
        'video_url': videoUrl,
        'image_url': imageUrl,
        'caption': caption,
        'product_id': productId,
      }),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to create content');
    }
  }
  
  static Future<void> viewContent(String contentId) async {
    await client.post(
      Uri.parse('$baseUrl/api/content/$contentId/view'),
      headers: _headers,
    );
  }
  
  static Future<Map<String, dynamic>> likeContent(String contentId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/content/$contentId/like'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to like content');
    }
  }
  
  // Orders endpoints
  static Future<List<dynamic>> getOrders() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/orders'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get orders');
    }
  }
  
  static Future<Map<String, dynamic>> createOrder({
    required String sellerId,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
    String? notes,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: _headers,
      body: jsonEncode({
        'seller_id': sellerId,
        'items': items,
        'delivery_address': deliveryAddress,
        'delivery_latitude': deliveryLatitude,
        'delivery_longitude': deliveryLongitude,
        'notes': notes,
      }),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to create order');
    }
  }
  
  static Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/orders/$orderId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to update order status');
    }
  }
  
  // Chat endpoints
  static Future<List<dynamic>> getConversations() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/chat/conversations'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get conversations');
    }
  }
  
  static Future<List<dynamic>> getChatMessages(String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/chat/$userId'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get messages');
    }
  }
  
  static Future<Map<String, dynamic>> sendMessage(String receiverId, String content, {String? imageUrl}) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/chat'),
      headers: _headers,
      body: jsonEncode({
        'receiver_id': receiverId,
        'content': content,
        'image_url': imageUrl,
      }),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to send message');
    }
  }
  
  static Future<int> getUnreadCount() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/chat/unread/count'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response)['unread_count'];
    } else {
      throw ApiException(response.statusCode, 'Failed to get unread count');
    }
  }
  
  // Search & Explore
  static Future<Map<String, dynamic>> search(String query, {String? type}) async {
    final queryParams = {'q': query};
    if (type != null) queryParams['type'] = type;
    
    final uri = Uri.parse('$baseUrl/api/search').replace(queryParameters: queryParams);
    final response = await client.get(uri, headers: _headers);
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to search');
    }
  }
  
  static Future<Map<String, dynamic>> getExplore({int page = 1, int perPage = 20}) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/explore?page=$page&per_page=$perPage'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get explore');
    }
  }
  
  static Future<List<dynamic>> getSellers() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/sellers'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get sellers');
    }
  }
  
  // Admin endpoints
  static Future<List<dynamic>> getUsers() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/users'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get users');
    }
  }
  
  // Admin user management endpoints
  static Future<Map<String, dynamic>> getUserDetails(int userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/admin/users/$userId'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get user details');
    }
  }
  
  static Future<Map<String, dynamic>> adminUpdateUser(int userId, Map<String, dynamic> updates) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/admin/users/$userId'),
      headers: _headers,
      body: jsonEncode(updates),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to update user');
    }
  }
  
  static Future<Map<String, dynamic>> blockUser(int userId, {bool isBlocked = true, String reason = ''}) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/admin/users/$userId/block'),
      headers: _headers,
      body: jsonEncode({'is_blocked': isBlocked, 'reason': reason}),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to block user');
    }
  }
  
  static Future<Map<String, dynamic>> approveUser(int userId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/admin/users/$userId/approve'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to approve user');
    }
  }
  
  static Future<void> deleteContent(String contentId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/content/$contentId'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to delete content');
    }
  }
  
  // Reviews endpoints
  static Future<Map<String, dynamic>> getProductReviews(int productId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/reviews/$productId'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get reviews');
    }
  }
  
  static Future<Map<String, dynamic>> createReview({
    required int productId,
    required int rating,
    String? comment,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/reviews'),
      headers: _headers,
      body: jsonEncode({
        'product_id': productId,
        'rating': rating,
        'comment': comment,
      }),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to create review');
    }
  }
  
  static Future<void> deleteReview(int reviewId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/reviews/$reviewId'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to delete review');
    }
  }
  
  // Product Likes endpoints
  static Future<Map<String, dynamic>> likeProduct(int productId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/products/$productId/like'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to like product');
    }
  }
  
  static Future<Map<String, dynamic>> getProductLikes(int productId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/products/$productId/likes'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get product likes');
    }
  }
  
  // Product Comments endpoints
  static Future<List<dynamic>> getProductComments(int productId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/products/$productId/comments'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get comments');
    }
  }
  
  static Future<Map<String, dynamic>> createProductComment({
    required int productId,
    required String content,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/products/$productId/comments'),
      headers: _headers,
      body: jsonEncode({
        'product_id': productId,
        'content': content,
      }),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to create comment');
    }
  }
  
  static Future<void> deleteProductComment(int commentId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/products/comments/$commentId'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to delete comment');
    }
  }
  
  // Favorites endpoints
  static Future<List<dynamic>> getFavorites() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/favorites'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get favorites');
    }
  }
  
  static Future<Map<String, dynamic>> toggleFavorite(int productId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/favorites/$productId'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to toggle favorite');
    }
  }
  
  static Future<bool> checkFavorite(int productId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/favorites/check/$productId'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final data = _decodeResponse(response);
      return data['is_favorite'] ?? false;
    } else {
      throw ApiException(response.statusCode, 'Failed to check favorite');
    }
  }

  // Platform Settings endpoints (admin only)
  static Future<List<dynamic>> getSettings() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/settings'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get settings');
    }
  }

  static Future<Map<String, dynamic>> getSetting(String key) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/settings/$key'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get setting');
    }
  }

  static Future<Map<String, dynamic>> updateSetting(String key, String value) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/settings/$key'),
      headers: _headers,
      body: jsonEncode({'value': value}),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to update setting');
    }
  }

  // Admin statistics endpoint
  static Future<Map<String, dynamic>> getAdminStats() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/admin/stats'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get admin stats');
    }
  }

  // User-specific statistics (personal reports)
  static Future<Map<String, dynamic>> getMyStats() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/my/stats'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get my stats');
    }
  }

  // Export user statistics as CSV
  static Future<String> exportMyStats() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/my/stats/export'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw ApiException(response.statusCode, 'Failed to export stats');
    }
  }

  // Admin export all transactions as CSV
  static Future<String> exportAdminStats() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/admin/export'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw ApiException(response.statusCode, 'Failed to export admin stats');
    }
  }

  // ==================== FCM PUSH NOTIFICATIONS ====================
  
  // Register FCM token for push notifications
  static Future<void> registerFcmToken(String token, {String deviceType = 'android'}) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/fcm/register'),
      headers: _headers,
      body: jsonEncode({'token': token, 'device_type': deviceType}),
    );
    
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to register FCM token');
    }
  }

  // Unregister FCM token on logout
  static Future<void> unregisterFcmToken(String token) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/fcm/unregister?token=$token'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to unregister FCM token');
    }
  }

  // ==================== COURIER LOCATION TRACKING ====================
  
  // Update courier's current location
  static Future<void> updateCourierLocation(double latitude, double longitude) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/courier/location'),
      headers: _headers,
      body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
    );
    
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to update location');
    }
  }

  // Set courier online/offline status
  static Future<void> setCourierOnline(bool isOnline) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/courier/online?is_online=$isOnline'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to update status');
    }
  }

  // Get courier's current location (for tracking)
  static Future<Map<String, dynamic>> getCourierLocation(int courierId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/courier/$courierId/location'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to get courier location');
    }
  }

  // Get all online couriers (for admin/seller)
  static Future<List<dynamic>> getOnlineCouriers() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/couriers/online'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw ApiException(response.statusCode, 'Failed to get online couriers');
    }
  }

  // ==================== USER VERIFICATION ====================
  
  // Submit verification document
  static Future<Map<String, dynamic>> submitVerification(String documentType, String documentUrl) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/verification/submit'),
      headers: _headers,
      body: jsonEncode({'document_type': documentType, 'document_url': documentUrl}),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to submit verification');
    }
  }

  // Get user's verification status
  static Future<List<dynamic>> getVerificationStatus() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/verification/status'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw ApiException(response.statusCode, 'Failed to get verification status');
    }
  }

  // Get pending verifications (admin only)
  static Future<List<dynamic>> getPendingVerifications() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/admin/verifications'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw ApiException(response.statusCode, 'Failed to get pending verifications');
    }
  }

  // Review verification (admin only)
  static Future<void> reviewVerification(int verificationId, String status, {String? notes}) async {
    String url = '$baseUrl/api/admin/verifications/$verificationId?status=$status';
    if (notes != null) url += '&notes=${Uri.encodeComponent(notes)}';
    
    final response = await client.put(
      Uri.parse(url),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to review verification');
    }
  }

  // ==================== DELIVERY FEE CALCULATION ====================
  
  // Calculate delivery fee based on distance
  static Future<Map<String, dynamic>> calculateDeliveryFee({
    required double sellerLat,
    required double sellerLon,
    required double buyerLat,
    required double buyerLon,
  }) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/delivery/calculate?seller_lat=$sellerLat&seller_lon=$sellerLon&buyer_lat=$buyerLat&buyer_lon=$buyerLon'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to calculate delivery fee');
    }
  }

  // ==================== AUTO-ASSIGNMENT OF COURIERS ====================
  
  // Auto-assign nearest courier to order
  static Future<Map<String, dynamic>> autoAssignCourier(int orderId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/orders/$orderId/auto-assign'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to auto-assign courier');
    }
  }

  // ==================== ENHANCED ORDER STATUS ====================
  
  // Update order status with push notifications
  static Future<void> updateOrderStatusWithNotification(int orderId, String status) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/orders/$orderId/status?status=$status'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to update order status');
    }
  }

  // Get online chat users
  static Future<List<int>> getOnlineChatUsers() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/chat/online'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final data = _decodeResponse(response);
      return List<int>.from(data['online_users'] ?? []);
    } else {
      throw ApiException(response.statusCode, 'Failed to get online users');
    }
  }
  
  // Upload video file and return server URL
  static Future<String> uploadVideo(String filePath) async {
    final uri = Uri.parse('$baseUrl/api/upload/video');
    final request = http.MultipartRequest('POST', uri);
    
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = _decodeResponse(response);
      return data['url'] as String;
    } else {
      throw ApiException(response.statusCode, 'Failed to upload video');
    }
  }
  
  // Upload image file and return server URL
  static Future<String> uploadImage(String filePath) async {
    final uri = Uri.parse('$baseUrl/api/upload/image');
    final request = http.MultipartRequest('POST', uri);
    
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = _decodeResponse(response);
      return data['url'] as String;
    } else {
      throw ApiException(response.statusCode, 'Failed to upload image');
    }
  }
  
  // ==================== CATEGORY MODERATION ====================
  
  // Get all approved categories
  static Future<List<dynamic>> getCategories() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/categories'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw ApiException(response.statusCode, 'Failed to get categories');
    }
  }

  // Request a new category (seller only)
  static Future<Map<String, dynamic>> requestCategory({
    required String name,
    required String nameRu,
    String? description,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/categories/request'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'name_ru': nameRu,
        'description': description,
      }),
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response);
    } else {
      throw ApiException(response.statusCode, 'Failed to request category');
    }
  }

  // Get category requests (admin sees all, seller sees own)
  static Future<List<dynamic>> getCategoryRequests({String? status}) async {
    String url = '$baseUrl/api/categories/requests';
    if (status != null) url += '?status=$status';
    
    final response = await client.get(
      Uri.parse(url),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw ApiException(response.statusCode, 'Failed to get category requests');
    }
  }

  // Review category request (admin only)
  static Future<void> reviewCategoryRequest(int requestId, String status, {String? notes}) async {
    String url = '$baseUrl/api/admin/categories/$requestId?status=$status';
    if (notes != null) url += '&notes=${Uri.encodeComponent(notes)}';
    
    final response = await client.put(
      Uri.parse(url),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to review category request');
    }
  }

  // Comments endpoints
  static Future<List<dynamic>> getComments(String contentId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/comments/$contentId'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return _decodeResponse(response) as List<dynamic>;
    } else if (response.statusCode == 404) {
      // No comments yet
      return [];
    } else {
      throw ApiException(response.statusCode, 'Failed to load comments');
    }
  }
  
  static Future<Map<String, dynamic>> postComment(String contentId, String text) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/comments'),
      headers: _headers,
      body: jsonEncode({
        'content_id': contentId,
        'text': text,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _decodeResponse(response) as Map<String, dynamic>;
    } else {
      throw ApiException(response.statusCode, 'Failed to post comment');
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  
  ApiException(this.statusCode, this.message);
  
  @override
  String toString() => 'ApiException: $statusCode - $message';
}
