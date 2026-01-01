import 'dart:async';

import 'package:flutter/foundation.dart';
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
import 'package:tiktok_tutorial/app_router.dart';
import 'package:tiktok_tutorial/views/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Make sure errors are visible in browser console.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught async error: $error');
    debugPrint('$stack');
    return true;
  };

  // Show a visible error screen instead of silent white page on web release.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return _BootErrorScreen(
      title: 'App startup error',
      message: details.exceptionAsString(),
    );
  };

  runZonedGuarded(() async {
    // Optional: accept self-signed certificates on IO platforms.
    //
    // WARNING: This disables TLS certificate validation globally.
    // Keep it OFF for production builds and enable only for local/staging:
    //   --dart-define=ALLOW_INSECURE_TLS=true
    const allowInsecureTls = bool.fromEnvironment('ALLOW_INSECURE_TLS', defaultValue: false);
    if (allowInsecureTls) {
      installInsecureHttpOverrides();
    }

    debugPrint('=== GoGoMarket starting ===');

    // Initialize API service and check for existing token
    try {
      await ApiService.init();
      debugPrint('ApiService.init OK (isLoggedIn=${ApiService.isLoggedIn})');
    } catch (e, st) {
      debugPrint('ApiService.init FAILED: $e');
      debugPrint('$st');
      // Don't block startup; app can still render guest mode.
    }

    // Initialize services (non-blocking on web; plugins may be unavailable)
    final notificationService = Get.put(NotificationService(), permanent: true);
    final locationService = Get.put(LocationService(), permanent: true);

    if (!kIsWeb) {
      try {
        await notificationService.init();
        debugPrint('NotificationService.init OK');
      } catch (e, st) {
        debugPrint('NotificationService.init FAILED: $e');
        debugPrint('$st');
      }

      try {
        await locationService.init();
        debugPrint('LocationService.init OK');
      } catch (e, st) {
        debugPrint('LocationService.init FAILED: $e');
        debugPrint('$st');
      }
    } else {
      debugPrint('Web: skipping NotificationService/LocationService init');
    }

    // Initialize controllers
    Get.put(MarketplaceController());
    Get.put(CartController());
    Get.put(FavoritesController());

    runApp(const MyApp());
  }, (error, stack) {
    debugPrint('Zoned startup error: $error');
    debugPrint('$stack');
    // Fallback: show a readable error message in UI.
    runApp(_BootErrorApp(error: error, stack: stack));
  });
}

class _BootErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace? stack;
  const _BootErrorApp({required this.error, this.stack});

  @override
  Widget build(BuildContext context) {
    final msg = [
      error.toString(),
      if (stack != null) '',
      if (stack != null) stack.toString(),
    ].join('\n');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _BootErrorScreen(
        title: 'App failed to start',
        message: msg.isEmpty ? 'Check browser console / logs.' : msg,
      ),
    );
  }
}

class _BootErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  const _BootErrorScreen({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 72),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
      ),
      // Localization
      translations: AppTranslations(),
      locale: const Locale('ru', 'RU'), // Default Russian
      fallbackLocale: const Locale('en', 'US'),
      home: const SplashScreen(),
    );
  }
}
