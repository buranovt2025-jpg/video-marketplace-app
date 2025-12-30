import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tiktok_tutorial/constants.dart';

class QRCodeScreen extends StatelessWidget {
  final String orderId;
  final String type; // 'pickup' or 'delivery'
  final String title;
  final String subtitle;

  const QRCodeScreen({
    super.key,
    required this.orderId,
    required this.type,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // Generate QR data with order info and type
    final qrData = 'ORDER:$orderId|TYPE:$type|TIME:${DateTime.now().millisecondsSinceEpoch}';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // QR Code container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: primaryColor,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Order ID
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${'order'.tr} #$orderId',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Subtitle/Instructions
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Type indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: type == 'pickup' 
                      ? Colors.blue.withValues(alpha: 0.2) 
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: type == 'pickup' ? Colors.blue : Colors.green,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type == 'pickup' ? Icons.inventory_2 : Icons.local_shipping,
                      color: type == 'pickup' ? Colors.blue : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type == 'pickup' ? 'pickup_qr'.tr : 'delivery_qr'.tr,
                      style: TextStyle(
                        color: type == 'pickup' ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'qr_scan_instruction'.tr,
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
