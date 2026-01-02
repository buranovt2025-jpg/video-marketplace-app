import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/order_provider.dart';
import '../../services/qr_service.dart';
import '../../services/offline_service.dart';

class QrScannerScreen extends StatefulWidget {
  final String orderId;
  final String scanType;

  const QrScannerScreen({
    super.key,
    required this.orderId,
    required this.scanType,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _codeController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _processQrCode(String qrData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final isOnline = await OfflineService().isOnline();

    if (!isOnline) {
      await OfflineService().saveQrScanOffline(
        orderId: widget.orderId,
        qrData: qrData,
        scanType: widget.scanType,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved offline. Will sync when online.'),
          backgroundColor: AppColors.warning,
        ),
      );

      Navigator.pop(context);
      return;
    }

    final orderProvider = context.read<OrderProvider>();
    bool success;

    if (widget.scanType == 'pickup') {
      success = await orderProvider.scanPickupQr(widget.orderId, qrData);
    } else {
      success = await orderProvider.confirmDelivery(widget.orderId, qrData: qrData);
    }

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.scanType == 'pickup'
                ? 'Order picked up successfully!'
                : 'Delivery confirmed!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Invalid QR code'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _processDeliveryCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.confirmDelivery(
      widget.orderId,
      deliveryCode: code,
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery confirmed!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Invalid code'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.scanType == 'pickup' ? 'Scan Pickup QR' : 'Confirm Delivery',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: AppColors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 100,
                      color: AppColors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Camera preview will appear here',
                      style: TextStyle(color: AppColors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'QR Scanner requires camera permission',
                      style: TextStyle(color: AppColors.grey400),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Initialize QR scanner
                        // For demo, simulate a scan
                        _processQrCode('{"orderId":"${widget.orderId}","type":"${widget.scanType == 'pickup' ? 'seller_pickup' : 'courier_delivery'}","code":"TEST123","timestamp":${DateTime.now().millisecondsSinceEpoch}}');
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Start Scanning'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.scanType == 'delivery')
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Or enter delivery code',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Enter 6-digit code',
                              prefixIcon: Icon(Icons.pin),
                            ),
                            maxLength: 6,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isProcessing ? null : _processDeliveryCode,
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Text('Verify'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
