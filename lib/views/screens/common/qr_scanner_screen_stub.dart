import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gogomarket/constants.dart';

// Stub implementation for web - QR scanning not supported
class QRScannerScreen extends StatelessWidget {
  final String expectedType;
  final String? expectedOrderId;
  final Function(String orderId, String type) onScanned;

  const QRScannerScreen({
    Key? key,
    required this.expectedType,
    this.expectedOrderId,
    required this.onScanned,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'scan_qr'.tr,
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
              Icon(
                Icons.qr_code_scanner,
                size: 100,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 24),
              Text(
                'QR сканер недоступен в веб-версии',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Используйте мобильное приложение для сканирования QR-кодов',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Назад'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
