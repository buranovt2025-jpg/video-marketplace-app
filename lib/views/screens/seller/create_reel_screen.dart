import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/utils/formatters.dart';
import 'package:tiktok_tutorial/utils/media_url.dart';
import 'package:tiktok_tutorial/utils/money.dart';

class CreateReelScreen extends StatefulWidget {
  const CreateReelScreen({Key? key}) : super(key: key);

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  
  String? _selectedProductId;

  @override
  void initState() {
    super.initState();
    _controller.fetchMyProducts();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _createReel() async {
    if (_videoUrlController.text.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'video_url_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    final url = _videoUrlController.text.trim();
    if (!looksLikeVideoUrl(url)) {
      Get.snackbar(
        'error'.tr,
        'video_url_invalid'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    final reel = await _controller.createReel(
      videoUrl: url,
      caption: _captionController.text.isNotEmpty 
          ? _captionController.text.trim() 
          : null,
      productId: _selectedProductId,
    );

    if (reel != null) {
      Get.back();
      Get.snackbar(
        'success'.tr,
        'reel_published'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        _controller.error.value.isNotEmpty 
            ? _controller.error.value 
            : 'create_reel_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'new_reel'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          Obx(() => TextButton(
            onPressed: _controller.isLoading.value ? null : _createReel,
            child: _controller.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'publish'.tr,
                    style: TextStyle(
                      color: buttonColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video preview area
            GestureDetector(
              onTap: () {
                // TODO: Implement video picker
              },
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_call, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text(
                      'add_video'.tr,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'recommended_format_9_16'.tr,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Video URL field (temporary until file upload is implemented)
            TextField(
              controller: _videoUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'video_url_required'.tr,
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'video_url_hint_mp4'.tr,
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.link, color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: buttonColor!),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 24),
            
            // Caption field
            TextField(
              controller: _captionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'description'.tr,
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'tell_about_product_hint'.tr,
                hintStyle: TextStyle(color: Colors.grey[600]),
                alignLabelWithHint: true,
                counterStyle: TextStyle(color: Colors.grey[500]),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: buttonColor!),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 16),
            
            // Link to product
            Text(
              'link_to_product'.tr,
              style: TextStyle(
                color: Colors.grey[300],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Obx(() {
              final products = _controller.myProducts;
              
              if (products.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[500]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'no_products_link_reel'.tr,
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedProductId,
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
                    icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
                    hint: Text(
                      'choose_product_optional'.tr,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    style: const TextStyle(color: Colors.white),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'no_product'.tr,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                      ...products.map((product) {
                        return DropdownMenuItem<String?>(
                          value: product['id'],
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2, color: Colors.grey[400], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${product['name']} - ${formatMoneyWithCurrency(product['price'])}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedProductId = value;
                      });
                    },
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 32),
            
            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates, color: Colors.purple[300]),
                      const SizedBox(width: 8),
                      Text(
                        'reels_tips_title'.tr,
                        style: TextStyle(
                          color: Colors.purple[300],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'reels_tips_body'.tr,
                    style: TextStyle(color: Colors.purple[300], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
