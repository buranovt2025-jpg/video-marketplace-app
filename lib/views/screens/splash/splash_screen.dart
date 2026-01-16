import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/services/api_service.dart';
import 'package:tiktok_tutorial/views/screens/admin/admin_home_screen.dart';
import 'package:tiktok_tutorial/views/screens/courier/courier_home_screen.dart';
import 'package:tiktok_tutorial/views/screens/marketplace_home_screen.dart';
import 'package:tiktok_tutorial/app_router.dart';

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
    // ignore: discarded_futures
    precacheImage(const AssetImage('assets/images/splash_logo.png'), context);

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
    return Scaffold(
      backgroundColor: const Color(0xFFFF6A00),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fullscreen branded loading background.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            opacity: _visible ? 1 : 0,
            child: Image.asset(
              'assets/images/splash_logo.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),

          // Optional small loading indicator (subtle).
          Positioned(
            left: 0,
            right: 0,
            bottom: 56,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: _visible ? 0.9 : 0,
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

