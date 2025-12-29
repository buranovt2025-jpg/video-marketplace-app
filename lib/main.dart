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
  
  // Initialize controllers (permanent: true to prevent disposal on navigation)
  Get.put(MarketplaceController(), permanent: true);
  Get.put(CartController(), permanent: true);
  Get.put(FavoritesController(), permanent: true);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoGoMarket',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        primaryColor: primaryColor,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: accentColor,
        ),
        // Smooth page transitions
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        // Card theme
        cardTheme: CardTheme(
          color: Colors.grey[900],
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        // Snackbar theme
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.grey[850],
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      // Default page transition
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
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
