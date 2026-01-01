import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/services/api_service.dart';
import 'package:tiktok_tutorial/views/screens/admin/admin_home_screen.dart';
import 'package:tiktok_tutorial/views/screens/courier/courier_home_screen.dart';
import 'package:tiktok_tutorial/views/screens/marketplace_home_screen.dart';
import 'package:tiktok_tutorial/main.dart' show AppRouter;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const int _minSplashMs = int.fromEnvironment('SPLASH_MS', defaultValue: 900);

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Start animation on next microtask to avoid a “pop-in”.
    scheduleMicrotask(() {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Best-effort precache (helps on web).
    final brightness = MediaQuery.platformBrightnessOf(context);
    final asset = brightness == Brightness.light ? 'assets/images/logo_white.png' : 'assets/images/logo_dark.png';
    // ignore: discarded_futures
    precacheImage(AssetImage(asset), context);

    // Kick navigation only once (didChangeDependencies может вызываться несколько раз).
    // ignore: discarded_futures
    _startOnce();
  }

  bool _started = false;
  Future<void> _startOnce() async {
    if (_started) return;
    _started = true;
    await _goNext();
  }

  Future<void> _goNext() async {
    // Always show splash for at least a small amount of time.
    await Future<void>.delayed(Duration(milliseconds: _minSplashMs));

    // Guest flow (web/app): show marketplace without login.
    if (!ApiService.isLoggedIn) {
      Get.offAll(() => const MarketplaceHomeScreen(isGuestMode: true));
      return;
    }

    // Logged-in flow: wait a bit for profile to load.
    final controller = Get.find<MarketplaceController>();
    final deadline = DateTime.now().add(const Duration(seconds: 4));
    while (controller.currentUser.value == null && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    if (controller.currentUser.value == null) {
      // Fallback: existing router will show a safe loading screen + logout.
      Get.offAll(() => const AppRouter());
      return;
    }

    if (controller.isAdmin) {
      Get.offAll(() => const AdminHomeScreen());
      return;
    }
    if (controller.isCourier) {
      Get.offAll(() => const CourierHomeScreen());
      return;
    }
    Get.offAll(() => const MarketplaceHomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isLight = brightness == Brightness.light;

    final bg = isLight ? Colors.white : Colors.black;
    final asset = isLight ? 'assets/images/logo_white.png' : 'assets/images/logo_dark.png';

    // Scale logo on larger screens (web desktop).
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final logoSize = (shortest * 0.45).clamp(180.0, 360.0);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          opacity: _visible ? 1 : 0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            scale: _visible ? 1 : 0.96,
            child: Image.asset(
              asset,
              width: logoSize,
              height: logoSize,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

