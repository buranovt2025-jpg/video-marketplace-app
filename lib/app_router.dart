import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/services/api_service.dart';
import 'package:tiktok_tutorial/views/screens/admin/admin_home_screen.dart';
import 'package:tiktok_tutorial/views/screens/auth/marketplace_login_screen.dart';
import 'package:tiktok_tutorial/views/screens/courier/courier_home_screen.dart';
import 'package:tiktok_tutorial/views/screens/marketplace_home_screen.dart';

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
      // IMPORTANT:
      // ApiService.isLoggedIn is not reactive, but `currentUser` is.
      // When token becomes invalid and we call logout() (clears token + sets currentUser=null),
      // this Obx rebuilds. At that moment we must *not* stay on the infinite spinner.
      if (!ApiService.isLoggedIn) {
        return const MarketplaceLoginScreen();
      }

      if (controller.currentUser.value == null) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Загружаем профиль…',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Если загрузка не заканчивается — выйдите и войдите снова.',
                    style: TextStyle(color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () async {
                      await controller.logout();
                      Get.offAll(() => const MarketplaceLoginScreen());
                    },
                    child: const Text('Выйти'),
                  ),
                ],
              ),
            ),
          ),
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

