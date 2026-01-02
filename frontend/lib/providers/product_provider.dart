import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _sellerProducts = [];
  List<String> _categories = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  final ApiService _apiService = ApiService();

  List<Product> get products => _products;
  List<Product> get sellerProducts => _sellerProducts;
  List<String> get categories => _categories;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchProducts({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? search,
    String? sellerId,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _products = [];
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        'page': _currentPage.toString(),
        'limit': '20',
        if (category != null) 'category': category,
        if (minPrice != null) 'minPrice': minPrice.toString(),
        if (maxPrice != null) 'maxPrice': maxPrice.toString(),
        if (search != null) 'search': search,
        if (sellerId != null) 'sellerId': sellerId,
      };

      final response = await _apiService.get('/products', queryParams: queryParams);

      if (response['success'] == true && response['data'] != null) {
        final newProducts = (response['data'] as List)
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();

        _products.addAll(newProducts);

        final pagination = response['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          _totalPages = pagination['totalPages'] as int? ?? 1;
          _hasMore = _currentPage < _totalPages;
          _currentPage++;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProductById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/products/$id');

      if (response['success'] == true && response['data'] != null) {
        _selectedProduct = Product.fromJson(response['data'] as Map<String, dynamic>);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await _apiService.get('/products/categories');

      if (response['success'] == true && response['data'] != null) {
        _categories = (response['data'] as List).cast<String>();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> fetchSellerProducts({bool refresh = false}) async {
    if (refresh) {
      _sellerProducts = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/products/seller');

      if (response['success'] == true && response['data'] != null) {
        _sellerProducts = (response['data'] as List)
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProduct(Map<String, dynamic> productData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/products', productData);

      if (response['success'] == true && response['data'] != null) {
        final newProduct = Product.fromJson(response['data'] as Map<String, dynamic>);
        _sellerProducts.insert(0, newProduct);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response['error'] as String?;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> productData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/products/$id', productData);

      if (response['success'] == true && response['data'] != null) {
        final updatedProduct = Product.fromJson(response['data'] as Map<String, dynamic>);
        
        final index = _sellerProducts.indexWhere((p) => p.id == id);
        if (index != -1) {
          _sellerProducts[index] = updatedProduct;
        }

        if (_selectedProduct?.id == id) {
          _selectedProduct = updatedProduct;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response['error'] as String?;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.delete('/products/$id');

      if (response['success'] == true) {
        _sellerProducts.removeWhere((p) => p.id == id);
        _products.removeWhere((p) => p.id == id);
        
        if (_selectedProduct?.id == id) {
          _selectedProduct = null;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response['error'] as String?;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
