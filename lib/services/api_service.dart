import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://app-owphiuvd.fly.dev';
  static String? _token;
  static const Duration _defaultTimeout = Duration(seconds: 30);
  
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
    final response = await http
        .post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['access_token']);
      return data;
    } else {
      throw ApiException(response.statusCode, jsonDecode(response.body)['detail'] ?? 'Login failed');
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
    final response = await http
        .post(
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
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['access_token']);
      return data;
    } else {
      throw ApiException(response.statusCode, jsonDecode(response.body)['detail'] ?? 'Registration failed');
    }
  }
  
  static Future<Map<String, dynamic>> getMe() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: _headers,
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to get user');
    }
  }
  
  static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> updates) async {
    final response = await http
        .put(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: _headers,
      body: jsonEncode(updates),
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to update user');
    }
  }
  
  // Products endpoints
  static Future<List<dynamic>> getProducts({String? sellerId, String? category, String? search}) async {
    final queryParams = <String, String>{};
    if (sellerId != null) queryParams['seller_id'] = sellerId;
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;
    
    final uri = Uri.parse('$baseUrl/api/products').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await http.get(uri, headers: _headers).timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to get products');
    }
  }
  
  static Future<Map<String, dynamic>> getProduct(String productId) async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/api/products/$productId'),
      headers: _headers,
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
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
    final response = await http
        .post(
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
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to create product');
    }
  }
  
  static Future<Map<String, dynamic>> updateProduct(String productId, Map<String, dynamic> updates) async {
    final response = await http
        .put(
      Uri.parse('$baseUrl/api/products/$productId'),
      headers: _headers,
      body: jsonEncode(updates),
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to update product');
    }
  }
  
  static Future<void> deleteProduct(String productId) async {
    final response = await http
        .delete(
      Uri.parse('$baseUrl/api/products/$productId'),
      headers: _headers,
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to delete product');
    }
  }
  
  // Content endpoints (Reels & Stories)
  static Future<List<dynamic>> getReels({int page = 1, int perPage = 10}) async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/api/content/reels?page=$page&per_page=$perPage'),
      headers: _headers,
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to get reels');
    }
  }
  
  static Future<List<dynamic>> getStories() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/api/content/stories'),
      headers: _headers,
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
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
    final response = await http
        .post(
      Uri.parse('$baseUrl/api/content'),
      headers: _headers,
      body: jsonEncode({
        'content_type': contentType,
        'video_url': videoUrl,
        'image_url': imageUrl,
        'caption': caption,
        'product_id': productId,
      }),
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to create content');
    }
  }
  
  static Future<void> viewContent(String contentId) async {
    await http
        .post(
      Uri.parse('$baseUrl/api/content/$contentId/view'),
      headers: _headers,
    )
        .timeout(_defaultTimeout);
  }
  
  static Future<Map<String, dynamic>> likeContent(String contentId) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/api/content/$contentId/like'),
      headers: _headers,
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to like content');
    }
  }
  
  // Orders endpoints
  static Future<List<dynamic>> getOrders() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/api/orders'),
      headers: _headers,
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
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
    final response = await http
        .post(
      Uri.parse('$baseUrl/api/orders'),
      headers: _headers,
      body: jsonEncode({
        // Backend часто ожидает int. Если sellerId числовой — отправим int.
        'seller_id': int.tryParse(sellerId) ?? sellerId,
        'items': items,
        'delivery_address': deliveryAddress,
        'delivery_latitude': deliveryLatitude,
        'delivery_longitude': deliveryLongitude,
        'notes': notes,
      }),
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to create order');
    }
  }
  
  static Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    final response = await http
        .put(
      Uri.parse('$baseUrl/api/orders/$orderId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to update order status');
    }
  }
  
  // Chat endpoints
  static Future<List<dynamic>> getConversations() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/api/chat/conversations'),
      headers: _headers,
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to get conversations');
    }
  }
  
  static Future<List<dynamic>> getChatMessages(String userId) async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/api/chat/$userId'),
      headers: _headers,
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to get messages');
    }
  }
  
  static Future<Map<String, dynamic>> sendMessage(String receiverId, String content, {String? imageUrl}) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/api/chat'),
      headers: _headers,
      body: jsonEncode({
        'receiver_id': receiverId,
        'content': content,
        'image_url': imageUrl,
      }),
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to send message');
    }
  }
  
  static Future<int> getUnreadCount() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/api/chat/unread/count'),
      headers: _headers,
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['unread_count'];
    } else {
      throw ApiException(response.statusCode, 'Failed to get unread count');
    }
  }
  
  // Search & Explore
  static Future<Map<String, dynamic>> search(String query, {String? type}) async {
    final queryParams = {'q': query};
    if (type != null) queryParams['type'] = type;
    
    final uri = Uri.parse('$baseUrl/api/search').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers).timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to search');
    }
  }
  
  static Future<Map<String, dynamic>> getExplore({int page = 1, int perPage = 20}) async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/api/explore?page=$page&per_page=$perPage'),
      headers: _headers,
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to get explore');
    }
  }
  
  static Future<List<dynamic>> getSellers() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/api/sellers'),
      headers: _headers,
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to get sellers');
    }
  }
  
  // Admin endpoints
  static Future<List<dynamic>> getUsers() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/api/users'),
      headers: _headers,
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, 'Failed to get users');
    }
  }
  
  static Future<void> deleteContent(String contentId) async {
    final response = await http
        .delete(
      Uri.parse('$baseUrl/api/content/$contentId'),
      headers: _headers,
    )
        .timeout(_defaultTimeout);
    
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to delete content');
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
