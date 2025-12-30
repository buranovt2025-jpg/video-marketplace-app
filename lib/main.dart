import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';
import 'package:tiktok_tutorial/controllers/favorites_controller.dart';
import 'package:tiktok_tutorial/services/api_service.dart';
import 'package:tiktok_tutorial/services/insecure_http_overrides_stub.dart'
    if (dart.library.io) 'package:tiktok_tutorial/services/insecure_http_overrides_io.dart';
import 'package:tiktok_tutorial/services/notification_service.dart';
import 'package:tiktok_tutorial/services/location_service.dart';
import 'package:tiktok_tutorial/views/screens/auth/marketplace_login_screen.dart';
import 'package:tiktok_tutorial/views/screens/marketplace_home_screen.dart';
import 'package:tiktok_tutorial/views/screens/courier/courier_home_screen.dart';
import 'package:tiktok_tutorial/views/screens/admin/admin_home_screen.dart';
import 'package:tiktok_tutorial/l10n/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TEMP (hotfix): accept self-signed certificates (e.g. https://165.232.81.31)
  // for all HTTP(S) requests on mobile/desktop. This is unsafe for production.
  installInsecureHttpOverrides();
  
  // Initialize API service and check for existing token
  await ApiService.init();
  
  // Initialize services
  await Get.putAsync(() => NotificationService().init());
  await Get.putAsync(() => LocationService().init());
  
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
    // Guest mode: allow browsing without login
    // Users will be prompted to login when trying to buy, add to favorites, etc.
    if (!ApiService.isLoggedIn) {
      // Show marketplace in guest mode (buyer view without login)
      return const MarketplaceHomeScreen(isGuestMode: true);
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
