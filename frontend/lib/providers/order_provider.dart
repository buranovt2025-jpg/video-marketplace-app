import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  List<Order> _availableOrders = [];
  Order? _selectedOrder;
  bool _isLoading = false;
  String? _error;

  final ApiService _apiService = ApiService();

  List<Order> get orders => _orders;
  List<Order> get availableOrders => _availableOrders;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrders({OrderStatus? status, bool refresh = false}) async {
    if (refresh) {
      _orders = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        if (status != null) 'status': status.name,
      };

      final response = await _apiService.get('/orders', queryParams: queryParams);

      if (response['success'] == true && response['data'] != null) {
        _orders = (response['data'] as List)
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
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

  Future<void> fetchOrderById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/orders/$id');

      if (response['success'] == true && response['data'] != null) {
        _selectedOrder = Order.fromJson(response['data'] as Map<String, dynamic>);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAvailableOrders({String? city}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        if (city != null) 'city': city,
      };

      final response = await _apiService.get('/orders/available', queryParams: queryParams);

      if (response['success'] == true && response['data'] != null) {
        _availableOrders = (response['data'] as List)
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
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

  Future<Order?> createOrder(Map<String, dynamic> orderData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/orders', orderData);

      if (response['success'] == true && response['data'] != null) {
        final newOrder = Order.fromJson(response['data'] as Map<String, dynamic>);
        _orders.insert(0, newOrder);
        _isLoading = false;
        notifyListeners();
        return newOrder;
      }

      _error = response['error'] as String?;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> confirmOrder(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/orders/$id/confirm', {});

      if (response['success'] == true) {
        await _updateOrderInList(id);
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

  Future<bool> acceptOrder(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/orders/$id/accept', {});

      if (response['success'] == true) {
        _availableOrders.removeWhere((o) => o.id == id);
        await fetchOrders(refresh: true);
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

  Future<bool> scanPickupQr(String orderId, String qrData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/orders/$orderId/pickup', {
        'qrData': qrData,
      });

      if (response['success'] == true) {
        await _updateOrderInList(orderId);
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

  Future<bool> confirmDelivery(String orderId, {String? qrData, String? deliveryCode}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/orders/$orderId/deliver', {
        if (qrData != null) 'qrData': qrData,
        if (deliveryCode != null) 'deliveryCode': deliveryCode,
      });

      if (response['success'] == true) {
        await _updateOrderInList(orderId);
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

  Future<bool> cancelOrder(String id, String reason) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/orders/$id/cancel', {
        'reason': reason,
      });

      if (response['success'] == true) {
        await _updateOrderInList(id);
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

  Future<void> _updateOrderInList(String id) async {
    try {
      final response = await _apiService.get('/orders/$id');

      if (response['success'] == true && response['data'] != null) {
        final updatedOrder = Order.fromJson(response['data'] as Map<String, dynamic>);
        
        final index = _orders.indexWhere((o) => o.id == id);
        if (index != -1) {
          _orders[index] = updatedOrder;
        }

        if (_selectedOrder?.id == id) {
          _selectedOrder = updatedOrder;
        }
      }
    } catch (e) {
      debugPrint('Error updating order in list: $e');
    }
  }

  void setSelectedOrder(Order order) {
    _selectedOrder = order;
    notifyListeners();
  }

  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
