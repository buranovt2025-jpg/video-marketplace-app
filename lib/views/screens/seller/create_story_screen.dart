import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/utils/formatters.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({Key? key}) : super(key: key);

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  
  String? _selectedProductId;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _controller.fetchMyProducts();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _createStory() async {
    final hasImage = _imageUrlController.text.isNotEmpty;
    final hasVideo = _videoUrlController.text.isNotEmpty;
    
    if (!hasImage && !hasVideo) {
      Get.snackbar(
        'Ошибка',
        'Добавьте фото или видео',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final story = await _controller.createStory(
      imageUrl: hasImage ? _imageUrlController.text.trim() : null,
      videoUrl: hasVideo ? _videoUrlController.text.trim() : null,
      caption: _captionController.text.isNotEmpty 
          ? _captionController.text.trim() 
          : null,
      productId: _selectedProductId,
    );

    if (story != null) {
      Get.back();
      Get.snackbar(
        'Успешно',
        'История опубликована',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Ошибка',
        _controller.error.value.isNotEmpty 
            ? _controller.error.value 
            : 'Не удалось создать историю',
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
          'Новая история',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Obx(() => TextButton(
            onPressed: _controller.isLoading.value ? null : _createStory,
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
            // Type selector
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isVideo = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isVideo ? buttonColor!.withOpacity(0.2) : Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !_isVideo ? buttonColor! : Colors.grey[800]!,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo,
                            color: !_isVideo ? buttonColor : Colors.grey[500],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Фото',
                            style: TextStyle(
                              color: !_isVideo ? Colors.white : Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isVideo = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isVideo ? buttonColor!.withOpacity(0.2) : Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isVideo ? buttonColor! : Colors.grey[800]!,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam,
                            color: _isVideo ? buttonColor : Colors.grey[500],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Видео',
                            style: TextStyle(
                              color: _isVideo ? Colors.white : Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Media preview area
            GestureDetector(
              onTap: () {
                // TODO: Implement media picker
              },
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isVideo ? Icons.video_call : Icons.add_photo_alternate,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isVideo ? 'Добавить видео' : 'Добавить фото',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'История исчезнет через 24 часа',
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
            
            // URL field (temporary until file upload is implemented)
            if (_isVideo)
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
              )
            else
              TextField(
                controller: _imageUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'URL изображения *',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  hintText: 'https://example.com/image.jpg',
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
              maxLines: 2,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: 'Подпись',
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'Добавьте подпись...',
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
                          'У вас пока нет товаров.',
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
                                  '${product['name']} - ${formatMoney(product['price'])} сум',
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
            
            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.orange[300]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Истории видны 24 часа и отображаются в кружочках вверху ленты',
                      style: TextStyle(color: Colors.orange[300], fontSize: 13),
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
}
