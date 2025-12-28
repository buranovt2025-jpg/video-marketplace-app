import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_tutorial/controllers/auth_controller.dart';
import 'package:tiktok_tutorial/demo_config.dart';
import 'package:tiktok_tutorial/views/screens/add_video_screen.dart';
import 'package:tiktok_tutorial/views/screens/profile_screen.dart';
import 'package:tiktok_tutorial/views/screens/search_screen.dart';
import 'package:tiktok_tutorial/views/screens/video_screen.dart';

// ВАЖНО: pages создается динамически после инициализации authController
List get pages => [
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
var firebaseAuth = FirebaseAuth.instance;
var firebaseStorage = FirebaseStorage.instance;
var firestore = FirebaseFirestore.instance;

// CONTROLLER
var authController = AuthController.instance;
