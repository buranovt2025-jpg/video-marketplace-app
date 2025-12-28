import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';

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
        'Ошибка',
        'Добавьте ссылку на видео',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final reel = await _controller.createReel(
      videoUrl: _videoUrlController.text.trim(),
      caption: _captionController.text.isNotEmpty 
          ? _captionController.text.trim() 
          : null,
      productId: _selectedProductId,
    );

    if (reel != null) {
      Get.back();
      Get.snackbar(
        'Успешно',
        'Рилс опубликован',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Ошибка',
        _controller.error.value.isNotEmpty 
            ? _controller.error.value 
            : 'Не удалось создать рилс',
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
        title: const Text(
          'Новый рилс',
          style: TextStyle(color: Colors.white),
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
                    'Опубликовать',
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
                      'Добавить видео',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Рекомендуемый формат: 9:16',
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
                labelText: 'URL видео *',
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'https://example.com/video.mp4',
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
                labelText: 'Описание',
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'Расскажите о вашем товаре...',
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
              'Привязать к товару',
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
                          'У вас пока нет товаров. Создайте товар, чтобы привязать его к рилсу.',
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
                      'Выберите товар (опционально)',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    style: const TextStyle(color: Colors.white),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'Без товара',
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
                                  '${product['name']} - ${product['price']?.toStringAsFixed(0)} сум',
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
                        'Советы для рилсов',
                        style: TextStyle(
                          color: Colors.purple[300],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Снимайте вертикальное видео (9:16)\n'
                    '• Первые 3 секунды - самые важные\n'
                    '• Покажите товар в действии\n'
                    '• Добавьте цену в описание',
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
