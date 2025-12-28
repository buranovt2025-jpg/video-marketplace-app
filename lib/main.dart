import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/services/api_service.dart';
import 'package:tiktok_tutorial/services/notification_service.dart';
import 'package:tiktok_tutorial/services/location_service.dart';
import 'package:tiktok_tutorial/views/screens/auth/marketplace_login_screen.dart';
import 'package:tiktok_tutorial/views/screens/marketplace_home_screen.dart';
import 'package:tiktok_tutorial/views/screens/courier/courier_home_screen.dart';
import 'package:tiktok_tutorial/views/screens/admin/admin_home_screen.dart';
import 'package:tiktok_tutorial/l10n/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API service and check for existing token
  await ApiService.init();
  
  // Initialize services
  await Get.putAsync(() => NotificationService().init());
  await Get.putAsync(() => LocationService().init());
  
  // Initialize controllers
  Get.put(MarketplaceController());
  Get.put(CartController());
  
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
    if (!ApiService.isLoggedIn) {
      return const MarketplaceLoginScreen();
    }
    
    final controller = Get.find<MarketplaceController>();
    
    return Obx(() {
      if (controller.currentUser.value == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      
      // Route based on user role
      if (controller.isAdmin) {
        return const AdminHomeScreen();
      }
      
      if (controller.isCourier) {
        return const CourierHomeScreen();
      }
      
      return const MarketplaceHomeScreen();
    });
  }
}
