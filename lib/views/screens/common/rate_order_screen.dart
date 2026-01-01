import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';

class RateOrderScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final String rateType; // 'seller' or 'courier'
  
  const RateOrderScreen({
    Key? key,
    required this.order,
    required this.rateType,
  }) : super(key: key);

  @override
  State<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends State<RateOrderScreen> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      Get.snackbar(
        'error'.tr,
        'select_rating'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isSubmitting = false);

    Get.back();
    Get.snackbar(
      'success'.tr,
      'thank_you_review'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetName = widget.rateType == 'seller'
        ? widget.order['seller_name'] ?? 'seller'.tr
        : widget.order['courier_name'] ?? 'courier'.tr;
    final orderIdStr = (widget.order['id'] ?? '').toString();
    final orderIdShort = orderIdStr.length > 8 ? orderIdStr.substring(0, 8) : orderIdStr;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.rateType == 'seller' ? 'rate_seller'.tr : 'rate_courier'.tr,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Target avatar and name
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[800],
              child: Icon(
                widget.rateType == 'seller' ? Icons.store : Icons.delivery_dining,
                size: 50,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              targetName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'order_number_short'.trParams({'id': orderIdShort}),
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),

            // Rating stars
            Text(
              'your_rating'.tr,
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 48,
                      color: index < _rating ? Colors.amber : Colors.grey[600],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _getRatingText(),
              style: TextStyle(
                color: _rating > 0 ? Colors.amber : Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            // Review text field
            TextField(
              controller: _reviewController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'write_review'.tr,
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'review_hint'.tr,
                hintStyle: TextStyle(color: Colors.grey[600]),
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'confirm'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'rating_very_bad'.tr;
      case 2:
        return 'rating_bad'.tr;
      case 3:
        return 'rating_ok'.tr;
      case 4:
        return 'rating_good'.tr;
      case 5:
        return 'rating_excellent'.tr;
      default:
        return '';
    }
  }
}
