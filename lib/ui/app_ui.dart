import 'package:flutter/material.dart';
import 'package:tiktok_tutorial/constants.dart';

/// Lightweight design system helpers (colors are in `constants.dart`).
class AppUI {
  static const double radiusS = 10;
  static const double radiusM = 14;
  static const double radiusL = 18;

  static const EdgeInsets pagePadding = EdgeInsets.all(16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  static const TextStyle h1 = TextStyle(
    color: textPrimaryColor,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    color: textPrimaryColor,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle body = TextStyle(
    color: textPrimaryColor,
    fontSize: 14,
    height: 1.4,
  );

  static const TextStyle muted = TextStyle(
    color: textSecondaryColor,
    fontSize: 13,
    height: 1.35,
  );

  static BoxDecoration cardDecoration({double radius = radiusM}) {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration inputDecoration() {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(radiusM),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    );
  }

  static ButtonStyle primaryButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
    );
  }

  static ButtonStyle outlineButton() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withOpacity(0.16)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
    );
  }
}

