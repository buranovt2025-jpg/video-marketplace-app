import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/utils/share_utils.dart';

class CommentsComingSoonSheet extends StatelessWidget {
  final Map<String, dynamic>? reel;
  final Map<String, dynamic>? product;

  const CommentsComingSoonSheet({super.key, this.reel, this.product})
      : assert(reel != null || product != null, 'Provide reel or product');

  @override
  Widget build(BuildContext context) {
    final title = 'comments'.tr;
    final subtitle = 'comments_coming_soon'.tr;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (reel != null) {
                    await copyToClipboardWithToast(buildReelShareText(reel!));
                  } else if (product != null) {
                    await copyToClipboardWithToast(buildProductShareText(product!));
                  }
                },
                icon: const Icon(Icons.share),
                label: Text('share'.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: (buttonColor ?? primaryColor).withOpacity(0.6)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(backgroundColor: buttonColor ?? primaryColor),
                child: Text('cancel'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

