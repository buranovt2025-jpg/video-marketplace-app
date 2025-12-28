import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/controllers/favorites_controller.dart';
import 'package:tiktok_tutorial/services/api_service.dart';
import 'package:tiktok_tutorial/services/notification_service.dart';
import 'package:tiktok_tutorial/services/location_service.dart';
import 'package:tiktok_tutorial/views/screens/marketplace_home_screen.dart';
import 'package:tiktok_tutorial/views/screens/courier/courier_home_screen.dart';
import 'package:tiktok_tutorial/views/screens/admin/admin_home_screen.dart';
import 'package:tiktok_tutorial/l10n/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (with error handling)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue without Firebase - push notifications won't work
  }
  
  // Initialize API service and check for existing token
  await ApiService.init();
  
  // Initialize services (with error handling)
  try {
    await Get.putAsync(() => NotificationService().init());
  } catch (e) {
    print('NotificationService initialization failed: $e');
  }
  
  try {
    await Get.putAsync(() => LocationService().init());
  } catch (e) {
    print('LocationService initialization failed: $e');
  }
  
  // Initialize controllers
  Get.put(MarketplaceController());
  Get.put(CartController());
  Get.put(FavoritesController());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Video Marketplace',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        primaryColor: primaryColor,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: accentColor,
        ),
      ),
      // Localization
      translations: AppTranslations(),
      locale: const Locale('ru', 'RU'), // Default Russian
      fallbackLocale: const Locale('en', 'US'),
      home: const AppRouter(),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceController>();
    
    // If not logged in, automatically set guest mode
    if (!ApiService.isLoggedIn) {
      // Set guest mode which creates a guest user with role='guest'
      controller.setGuestMode(true);
    }
    
    return Obx(() {
      final user = controller.currentUser.value;
      
      // Show loading only if we're waiting for a real user (not guest)
      if (user == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      
      // Route based on user role (including guest)
      final role = user['role'] ?? '';
      
      if (role == 'admin') {
        return const AdminHomeScreen();
      }
      
      if (role == 'courier') {
        return const CourierHomeScreen();
      }
      
      // Guest, buyer, seller all go to MarketplaceHomeScreen
      return const MarketplaceHomeScreen();
    });
  }
}
