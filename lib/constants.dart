import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/controllers/auth_controller.dart';
import 'package:tiktok_tutorial/demo_config.dart';
import 'package:tiktok_tutorial/views/screens/add_video_screen.dart';
import 'package:tiktok_tutorial/views/screens/profile_screen.dart';
import 'package:tiktok_tutorial/views/screens/search_screen.dart';
import 'package:tiktok_tutorial/views/screens/video_screen.dart';

// IMPORTANT:
// Avoid side effects at import-time (especially on Flutter Web).
// Keep Firebase/GetX objects lazy so marketplace web build can run
// even if Firebase is not configured.
List<Widget> getPages() => [
      VideoScreen(),
      SearchScreen(),
      const AddVideoScreen(),
      const Text('Messages Screen'),
      ProfileScreen(uid: DEMO_MODE ? DEMO_USER_ID : (authController.user?.uid ?? '')),
    ];

// COLORS - Orange/White/Black theme
const backgroundColor = Colors.black;
const primaryColor = Color(0xFFFF6B00); // Orange
const accentColor = Color(0xFFFF8C00); // Light orange
var buttonColor = Color(0xFFFF6B00); // Orange (was red)
const borderColor = Colors.grey;
const textPrimaryColor = Colors.white;
const textSecondaryColor = Color(0xFFB0B0B0);
const cardColor = Color(0xFF1A1A1A);
const surfaceColor = Color(0xFF121212);

// FIREBASE
FirebaseAuth get firebaseAuth => FirebaseAuth.instance;
FirebaseStorage get firebaseStorage => FirebaseStorage.instance;
FirebaseFirestore get firestore => FirebaseFirestore.instance;

// CONTROLLER
AuthController get authController {
  if (Get.isRegistered<AuthController>()) {
    return Get.find<AuthController>();
  }
  return Get.put(AuthController(), permanent: true);
}
