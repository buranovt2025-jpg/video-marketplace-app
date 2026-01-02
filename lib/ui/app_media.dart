import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tiktok_tutorial/constants.dart';

class AppMedia {
  static bool _isDataImage(String url) => url.startsWith('data:image/');

  static Uint8List? _decodeDataUrl(String url) {
    final comma = url.indexOf(',');
    if (comma == -1) return null;
    final payload = url.substring(comma + 1);
    try {
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  static Widget image(
    String? url, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    final placeholder = Container(
      width: width,
      height: height,
      color: surfaceColor,
      alignment: Alignment.center,
      child: Icon(Icons.image, color: Colors.white.withOpacity(0.35)),
    );

    if (url == null || url.isEmpty) return placeholder;

    Widget child;
    if (_isDataImage(url)) {
      final bytes = _decodeDataUrl(url);
      child = bytes == null
          ? placeholder
          : Image.memory(bytes, fit: fit, width: width, height: height);
    } else {
      child = Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: child);
    }
    return child;
  }
}

