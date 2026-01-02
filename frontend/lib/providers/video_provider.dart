import 'package:flutter/foundation.dart';

import '../models/video.dart';
import '../services/api_service.dart';

class VideoProvider with ChangeNotifier {
  List<Video> _videos = [];
  List<Video> _liveVideos = [];
  List<Video> _sellerVideos = [];
  Video? _selectedVideo;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  final ApiService _apiService = ApiService();

  List<Video> get videos => _videos;
  List<Video> get liveVideos => _liveVideos;
  List<Video> get sellerVideos => _sellerVideos;
  Video? get selectedVideo => _selectedVideo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchVideoFeed({String? category, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _videos = [];
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        'page': _currentPage.toString(),
        'limit': '10',
        if (category != null) 'category': category,
      };

      final response = await _apiService.get('/videos/feed', queryParams: queryParams);

      if (response['success'] == true && response['data'] != null) {
        final newVideos = (response['data'] as List)
            .map((json) => Video.fromJson(json as Map<String, dynamic>))
            .toList();

        _videos.addAll(newVideos);

        final pagination = response['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          final totalPages = pagination['totalPages'] as int? ?? 1;
          _hasMore = _currentPage < totalPages;
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

  Future<void> fetchLiveVideos() async {
    try {
      final response = await _apiService.get('/videos/live');

      if (response['success'] == true && response['data'] != null) {
        _liveVideos = (response['data'] as List)
            .map((json) => Video.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching live videos: $e');
    }
  }

  Future<void> fetchVideoById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/videos/$id');

      if (response['success'] == true && response['data'] != null) {
        _selectedVideo = Video.fromJson(response['data'] as Map<String, dynamic>);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSellerVideos({bool refresh = false}) async {
    if (refresh) {
      _sellerVideos = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/videos/seller');

      if (response['success'] == true && response['data'] != null) {
        _sellerVideos = (response['data'] as List)
            .map((json) => Video.fromJson(json as Map<String, dynamic>))
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

  Future<bool> createVideo(Map<String, dynamic> videoData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/videos', videoData);

      if (response['success'] == true && response['data'] != null) {
        final newVideo = Video.fromJson(response['data'] as Map<String, dynamic>);
        _sellerVideos.insert(0, newVideo);
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

  Future<bool> likeVideo(String id) async {
    try {
      final response = await _apiService.post('/videos/$id/like', {});

      if (response['success'] == true) {
        final index = _videos.indexWhere((v) => v.id == id);
        if (index != -1) {
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error liking video: $e');
      return false;
    }
  }

  Future<bool> deleteVideo(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.delete('/videos/$id');

      if (response['success'] == true) {
        _sellerVideos.removeWhere((v) => v.id == id);
        _videos.removeWhere((v) => v.id == id);
        
        if (_selectedVideo?.id == id) {
          _selectedVideo = null;
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

  void setSelectedVideo(Video video) {
    _selectedVideo = video;
    notifyListeners();
  }

  void clearSelectedVideo() {
    _selectedVideo = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
