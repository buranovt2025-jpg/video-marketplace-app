class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';
  
  // Product endpoints
  static const String products = '/products';
  static const String categories = '/products/categories';
  static const String sellerProducts = '/products/seller';
  
  // Video endpoints
  static const String videos = '/videos';
  static const String videoFeed = '/videos/feed';
  static const String liveVideos = '/videos/live';
  static const String sellerVideos = '/videos/seller';
  
  // Order endpoints
  static const String orders = '/orders';
  static const String availableOrders = '/orders/available';
  
  // Health check
  static const String health = '/health';
}
