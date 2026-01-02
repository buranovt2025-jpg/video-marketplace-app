import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;

  AuthProvider() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    try {
      _token = await _storage.read(key: 'auth_token');
      final userData = await _storage.read(key: 'user_data');
      
      if (_token != null && userData != null) {
        await fetchProfile();
      }
    } catch (e) {
      debugPrint('Error loading stored auth: $e');
    }
  }

  Future<bool> register({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    String? email,
    UserRole role = UserRole.buyer,
    required bool acceptedTerms,
    required bool acceptedPrivacy,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/register', {
        'phone': phone,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role.name,
        'acceptedTerms': acceptedTerms,
        'acceptedPrivacy': acceptedPrivacy,
      });

      _isLoading = false;
      notifyListeners();

      return response['success'] == true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/verify-otp', {
        'phone': phone,
        'code': code,
      });

      if (response['success'] == true && response['data'] != null) {
        _token = response['data']['token'] as String;
        _user = User.fromJson(response['data']['user'] as Map<String, dynamic>);

        await _storage.write(key: 'auth_token', value: _token);
        _apiService.setToken(_token!);

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

  Future<bool> resendOtp(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/resend-otp', {
        'phone': phone,
      });

      _isLoading = false;
      notifyListeners();

      return response['success'] == true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/login', {
        'phone': phone,
        'password': password,
      });

      if (response['success'] == true && response['data'] != null) {
        _token = response['data']['token'] as String;
        _user = User.fromJson(response['data']['user'] as Map<String, dynamic>);

        await _storage.write(key: 'auth_token', value: _token);
        _apiService.setToken(_token!);

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

  Future<void> fetchProfile() async {
    if (_token == null) return;

    try {
      _apiService.setToken(_token!);
      final response = await _apiService.get('/auth/profile');

      if (response['success'] == true && response['data'] != null) {
        _user = User.fromJson(response['data'] as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? avatar,
    Language? language,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/auth/profile', {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (email != null) 'email': email,
        if (avatar != null) 'avatar': avatar,
        if (language != null) 'language': language.name,
      });

      if (response['success'] == true && response['data'] != null) {
        _user = User.fromJson(response['data'] as Map<String, dynamic>);
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

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put('/auth/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      _isLoading = false;
      notifyListeners();

      return response['success'] == true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    _error = null;

    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_data');
    _apiService.clearToken();

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
