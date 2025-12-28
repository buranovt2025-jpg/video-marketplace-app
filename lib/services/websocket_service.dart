import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket service for real-time chat functionality
class WebSocketService extends GetxService {
  static WebSocketService get to => Get.find();
  
  WebSocketChannel? _channel;
  final RxBool isConnected = false.obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxMap<String, bool> onlineUsers = <String, bool>{}.obs;
  
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  
  String? _currentUserId;
  String? _currentConversationId;
  
  // Callbacks
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(String visitorId, bool isOnline)? onUserStatusChanged;
  
  /// Initialize WebSocket service
  Future<WebSocketService> init() async {
    return this;
  }
  
  /// Connect to WebSocket server
  Future<void> connect({
    required String userId,
    String? conversationId,
  }) async {
    _currentUserId = userId;
    _currentConversationId = conversationId;
    
    // For demo mode, simulate connection
    if (kDebugMode || true) {
      // Demo mode - simulate WebSocket connection
      await Future.delayed(const Duration(milliseconds: 500));
      isConnected.value = true;
      _startPingTimer();
      _loadDemoMessages();
      return;
    }
    
    // Real WebSocket connection (when backend supports it)
    // try {
    //   final wsUrl = 'wss://your-backend.com/ws/chat/$conversationId?user_id=$userId';
    //   _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    //   
    //   _subscription = _channel!.stream.listen(
    //     _onMessage,
    //     onError: _onError,
    //     onDone: _onDone,
    //   );
    //   
    //   isConnected.value = true;
    //   _startPingTimer();
    // } catch (e) {
    //   print('WebSocket connection error: $e');
    //   _scheduleReconnect();
    // }
  }
  
  /// Load demo messages for testing
  void _loadDemoMessages() {
    messages.clear();
    messages.addAll([
      {
        'id': '1',
        'sender_id': 'seller_1',
        'sender_name': 'Продавец',
        'content': 'Здравствуйте! Чем могу помочь?',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        'is_read': true,
      },
      {
        'id': '2',
        'sender_id': _currentUserId ?? 'user',
        'sender_name': 'Вы',
        'content': 'Добрый день! Есть ли этот товар в наличии?',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 4)).toIso8601String(),
        'is_read': true,
      },
      {
        'id': '3',
        'sender_id': 'seller_1',
        'sender_name': 'Продавец',
        'content': 'Да, есть! Сколько штук вам нужно?',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 3)).toIso8601String(),
        'is_read': true,
      },
    ]);
    
    // Simulate online users
    onlineUsers['seller_1'] = true;
    onlineUsers['buyer_1'] = true;
  }
  
  /// Handle incoming WebSocket message
  void _onMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      
      switch (message['type']) {
        case 'chat_message':
          _handleChatMessage(message['data']);
          break;
        case 'user_status':
          _handleUserStatus(message['data']);
          break;
        case 'typing':
          _handleTyping(message['data']);
          break;
        case 'pong':
          // Ping response received
          break;
      }
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }
  
  /// Handle chat message
  void _handleChatMessage(Map<String, dynamic> data) {
    messages.add(data);
    onMessageReceived?.call(data);
  }
  
  /// Handle user status change
  void _handleUserStatus(Map<String, dynamic> data) {
    final visitorId = data['user_id'] as String;
    final isOnline = data['is_online'] as bool;
    onlineUsers[visitorId] = isOnline;
    onUserStatusChanged?.call(visitorId, isOnline);
  }
  
  /// Handle typing indicator
  void _handleTyping(Map<String, dynamic> data) {
    // Handle typing indicator
  }
  
  /// Handle WebSocket error
  void _onError(dynamic error) {
    debugPrint('WebSocket error: $error');
    isConnected.value = false;
    _scheduleReconnect();
  }
  
  /// Handle WebSocket connection closed
  void _onDone() {
    debugPrint('WebSocket connection closed');
    isConnected.value = false;
    _scheduleReconnect();
  }
  
  /// Schedule reconnection
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_currentUserId != null) {
        connect(
          userId: _currentUserId!,
          conversationId: _currentConversationId,
        );
      }
    });
  }
  
  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendPing();
    });
  }
  
  /// Send ping to server
  void _sendPing() {
    if (isConnected.value && _channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'ping'}));
    }
  }
  
  /// Send chat message
  void sendMessage({
    required String content,
    String? receiverId,
  }) {
    final message = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'sender_id': _currentUserId ?? 'user',
      'sender_name': 'Вы',
      'receiver_id': receiverId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
      'is_read': false,
    };
    
    // Add to local messages immediately
    messages.add(message);
    
    // Send via WebSocket if connected
    if (_channel != null && isConnected.value) {
      _channel!.sink.add(jsonEncode({
        'type': 'chat_message',
        'data': message,
      }));
    }
    
    // Simulate response in demo mode
    _simulateResponse(content);
  }
  
  /// Simulate response for demo mode
  void _simulateResponse(String userMessage) {
    Future.delayed(const Duration(seconds: 2), () {
      final responses = [
        'Хорошо, понял вас!',
        'Отлично, сейчас проверю.',
        'Да, конечно!',
        'Минутку, уточню информацию.',
        'Спасибо за обращение!',
      ];
      
      final response = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'sender_id': 'seller_1',
        'sender_name': 'Продавец',
        'content': responses[DateTime.now().second % responses.length],
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
      };
      
      messages.add(response);
      onMessageReceived?.call(response);
    });
  }
  
  /// Send typing indicator
  void sendTyping({required String receiverId}) {
    if (_channel != null && isConnected.value) {
      _channel!.sink.add(jsonEncode({
        'type': 'typing',
        'data': {
          'sender_id': _currentUserId,
          'receiver_id': receiverId,
        },
      }));
    }
  }
  
  /// Check if user is online
  bool isUserOnline(String visitorId) {
    return onlineUsers[visitorId] ?? false;
  }
  
  /// Disconnect from WebSocket
  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    isConnected.value = false;
    _currentUserId = null;
    _currentConversationId = null;
  }
  
  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
