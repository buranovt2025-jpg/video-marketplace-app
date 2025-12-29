import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gogomarket/constants.dart';

class QRScannerScreen extends StatefulWidget {
  final String expectedType; // 'pickup' or 'delivery'
  final String? expectedOrderId;
  final Function(String orderId, String type) onScanned;

  const QRScannerScreen({
    Key? key,
    required this.expectedType,
    this.expectedOrderId,
    required this.onScanned,
  }) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  
  bool _isScanned = false;
  bool _isProcessing = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null) return;

    setState(() {
      _isProcessing = true;
    });

    // Parse QR data: ORDER:xxx|TYPE:xxx|TIME:xxx
    try {
      final parts = rawValue.split('|');
      String? orderId;
      String? type;

      for (final part in parts) {
        if (part.startsWith('ORDER:')) {
          orderId = part.substring(6);
        } else if (part.startsWith('TYPE:')) {
          type = part.substring(5);
        }
      }

      if (orderId == null || type == null) {
        setState(() {
          _error = 'invalid_qr'.tr;
          _isProcessing = false;
        });
        return;
      }

      // Validate type matches expected
      if (type != widget.expectedType) {
        setState(() {
          _error = 'wrong_qr_type'.tr;
          _isProcessing = false;
        });
        return;
      }

      // Validate order ID if expected
      if (widget.expectedOrderId != null && orderId != widget.expectedOrderId) {
        setState(() {
          _error = 'wrong_order_qr'.tr;
          _isProcessing = false;
        });
        return;
      }

      // Success!
      setState(() {
        _isScanned = true;
        _isProcessing = false;
      });

      // Show success animation briefly
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onScanned(orderId!, type!);
        Get.back(result: {'orderId': orderId, 'type': type});
      });

    } catch (e) {
      setState(() {
        _error = 'scan_error'.tr;
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'scan_qr'.tr,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: state == TorchState.on ? primaryColor : Colors.white,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Scan overlay
          _buildScanOverlay(),

          // Bottom info panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),

          // Success overlay
          if (_isScanned) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QRScannerOverlayShape(
          borderColor: _isScanned ? Colors.green : primaryColor,
          borderRadius: 16,
          borderLength: 40,
          borderWidth: 4,
          cutOutSize: 280,
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
            Colors.black,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error message
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _error = null),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Instructions
            Text(
              widget.expectedType == 'pickup' 
                  ? 'scan_pickup_instruction'.tr 
                  : 'scan_delivery_instruction'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Expected type indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.expectedType == 'pickup' 
                    ? Colors.blue.withOpacity(0.2) 
                    : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.expectedType == 'pickup' ? Colors.blue : Colors.green,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.expectedType == 'pickup' ? Icons.inventory_2 : Icons.local_shipping,
                    color: widget.expectedType == 'pickup' ? Colors.blue : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.expectedType == 'pickup' ? 'pickup_qr'.tr : 'delivery_qr'.tr,
                    style: TextStyle(
                      color: widget.expectedType == 'pickup' ? Colors.blue : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'qr_scanned_success'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom overlay shape for QR scanner
class QRScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QRScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.5),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final cutOutWidth = cutOutSize;
    final cutOutHeight = cutOutSize;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + (width - cutOutWidth) / 2 + borderOffset,
      rect.top + (height - cutOutHeight) / 2 + borderOffset,
      cutOutWidth - borderOffset * 2,
      cutOutHeight - borderOffset * 2,
    );

    canvas
      ..saveLayer(rect, backgroundPaint)
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        boxPaint,
      )
      ..restore();

    // Draw corner borders
    final left = cutOutRect.left;
    final top = cutOutRect.top;
    final right = cutOutRect.right;
    final bottom = cutOutRect.bottom;

    // Top left corner
    canvas
      ..drawLine(Offset(left, top + borderLength), Offset(left, top + borderRadius), borderPaint)
      ..drawArc(
        Rect.fromLTWH(left, top, borderRadius * 2, borderRadius * 2),
        3.14159,
        3.14159 / 2,
        false,
        borderPaint,
      )
      ..drawLine(Offset(left + borderRadius, top), Offset(left + borderLength, top), borderPaint);

    // Top right corner
    canvas
      ..drawLine(Offset(right - borderLength, top), Offset(right - borderRadius, top), borderPaint)
      ..drawArc(
        Rect.fromLTWH(right - borderRadius * 2, top, borderRadius * 2, borderRadius * 2),
        -3.14159 / 2,
        3.14159 / 2,
        false,
        borderPaint,
      )
      ..drawLine(Offset(right, top + borderRadius), Offset(right, top + borderLength), borderPaint);

    // Bottom right corner
    canvas
      ..drawLine(Offset(right, bottom - borderLength), Offset(right, bottom - borderRadius), borderPaint)
      ..drawArc(
        Rect.fromLTWH(right - borderRadius * 2, bottom - borderRadius * 2, borderRadius * 2, borderRadius * 2),
        0,
        3.14159 / 2,
        false,
        borderPaint,
      )
      ..drawLine(Offset(right - borderRadius, bottom), Offset(right - borderLength, bottom), borderPaint);

    // Bottom left corner
    canvas
      ..drawLine(Offset(left + borderLength, bottom), Offset(left + borderRadius, bottom), borderPaint)
      ..drawArc(
        Rect.fromLTWH(left, bottom - borderRadius * 2, borderRadius * 2, borderRadius * 2),
        3.14159 / 2,
        3.14159 / 2,
        false,
        borderPaint,
      )
      ..drawLine(Offset(left, bottom - borderRadius), Offset(left, bottom - borderLength), borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QRScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
    );
  }
}
