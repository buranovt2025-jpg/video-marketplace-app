import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Minimal share helper without extra dependencies.
///
/// For now we implement "copy to clipboard" as a universal baseline:
/// - Works on web
/// - Works on mobile
///
/// Later we can replace/extend this with a native share sheet (share_plus).
Future<void> copyToClipboardWithToast(String text) async {
  final t = text.trim();
  if (t.isEmpty) return;
  await Clipboard.setData(ClipboardData(text: t));
  Get.snackbar(
    'success'.tr,
    'link_copied'.tr,
    snackPosition: SnackPosition.BOTTOM,
  );
}

String buildProductShareText(Map<String, dynamic> product) {
  final name = (product['name'] ?? '').toString().trim();
  final id = (product['id'] ?? '').toString().trim();
  final base = Uri.base.toString();
  final title = name.isNotEmpty ? name : 'product'.tr;
  final suffix = id.isNotEmpty ? ' (id: $id)' : '';
  // No deep links yet: share the site + product identifier.
  return '$title$suffix\n$base';
}

String buildReelShareText(Map<String, dynamic> reel) {
  final id = (reel['id'] ?? '').toString().trim();
  final author = (reel['author_name'] ?? '').toString().trim();
  final caption = (reel['caption'] ?? '').toString().trim();
  final base = Uri.base.toString();
  final who = author.isNotEmpty ? '@$author' : 'reel'.tr;
  final head = id.isNotEmpty ? '$who (id: $id)' : who;
  if (caption.isNotEmpty) {
    return '$head\n$caption\n$base';
  }
  return '$head\n$base';
}

