import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/ui/app_ui.dart';

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
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedMedia;
  bool _isPickingMedia = false;
  
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
        title: Text('Новая история', style: AppUI.h2),
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
                      color: primaryColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          )),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppUI.pagePadding,
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
                        color: !_isVideo ? primaryColor.withOpacity(0.18) : surfaceColor,
                        borderRadius: BorderRadius.circular(AppUI.radiusM),
                        border: Border.all(
                          color: !_isVideo ? primaryColor.withOpacity(0.6) : Colors.white.withOpacity(0.10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo,
                            color: !_isVideo ? primaryColor : Colors.white.withOpacity(0.45),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Фото',
                            style: TextStyle(
                              color: !_isVideo ? Colors.white : Colors.white.withOpacity(0.55),
                              fontWeight: FontWeight.w700,
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
                        color: _isVideo ? primaryColor.withOpacity(0.18) : surfaceColor,
                        borderRadius: BorderRadius.circular(AppUI.radiusM),
                        border: Border.all(
                          color: _isVideo ? primaryColor.withOpacity(0.6) : Colors.white.withOpacity(0.10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam,
                            color: _isVideo ? primaryColor : Colors.white.withOpacity(0.45),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Видео',
                            style: TextStyle(
                              color: _isVideo ? Colors.white : Colors.white.withOpacity(0.55),
                              fontWeight: FontWeight.w700,
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
            InkWell(
              onTap: _showMediaSourceDialog,
              borderRadius: BorderRadius.circular(AppUI.radiusL),
              child: Container(
                height: 300,
                decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isVideo ? Icons.video_call : Icons.add_photo_alternate,
                      size: 64,
                      color: Colors.white.withOpacity(0.25),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedMedia != null ? 'Выбрано: ${_selectedMedia!.name}' : (_isVideo ? 'Добавить видео' : 'Добавить фото'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'История исчезнет через 24 часа',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                    if (_isPickingMedia) ...[
                      const SizedBox(height: 14),
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                      ),
                    ],
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
                  labelStyle: AppUI.muted,
                  hintText: 'https://example.com/video.mp4',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.link, color: Colors.white.withOpacity(0.55)),
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppUI.radiusM),
                    borderSide: BorderSide.none,
                  ),
                ),
              )
            else
              TextField(
                controller: _imageUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'URL изображения *',
                  labelStyle: AppUI.muted,
                  hintText: 'https://example.com/image.jpg',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.link, color: Colors.white.withOpacity(0.55)),
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppUI.radiusM),
                    borderSide: BorderSide.none,
                  ),
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
                labelStyle: AppUI.muted,
                hintText: 'Добавьте подпись...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                alignLabelWithHint: true,
                counterStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppUI.radiusM),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Link to product
            Text('Привязать к товару', style: AppUI.h2.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            
            Obx(() {
              final products = _controller.myProducts;
              
              if (products.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white.withOpacity(0.45)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'У вас пока нет товаров.',
                          style: AppUI.muted,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: AppUI.inputDecoration(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedProductId,
                    isExpanded: true,
                    dropdownColor: cardColor,
                    icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
                    hint: Text(
                      'Выберите товар (опционально)',
                      style: AppUI.muted,
                    ),
                    style: const TextStyle(color: Colors.white),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'Без товара',
                          style: AppUI.muted,
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
            
            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Истории видны 24 часа и отображаются в кружочках вверху ленты',
                      style: AppUI.muted,
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

  void _showMediaSourceDialog() {
    Get.bottomSheet(
      Container(
        padding: AppUI.pagePadding,
        decoration: const BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(_isVideo ? 'Видео для истории' : 'Фото для истории', style: AppUI.h2),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_isVideo ? Icons.video_library : Icons.photo_library, color: primaryColor),
              ),
              title: Text('Галерея', style: AppUI.body),
              subtitle: Text('Выбрать файл', style: AppUI.muted),
              onTap: () {
                Get.back();
                _pickMedia(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_isVideo ? Icons.videocam : Icons.camera_alt, color: primaryColor),
              ),
              title: Text('Камера', style: AppUI.body),
              subtitle: Text(_isVideo ? 'Снять видео' : 'Сделать фото', style: AppUI.muted),
              onTap: () {
                Get.back();
                _pickMedia(ImageSource.camera);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source) async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);
    try {
      final XFile? file = _isVideo
          ? await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 1))
          : await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (file != null) {
        String? imageDataUrl;
        if (!_isVideo) {
          final bytes = await file.readAsBytes();
          final mime = _inferImageMime(file.name);
          imageDataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
        }
        setState(() {
          _selectedMedia = file;
          if (_isVideo) {
            _videoUrlController.text = file.path;
            _imageUrlController.clear();
          } else {
            _imageUrlController.text = imageDataUrl ?? '';
            _videoUrlController.clear();
          }
        });
      }
    } catch (_) {
      Get.snackbar(
        'error'.tr,
        'Не удалось выбрать файл',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isPickingMedia = false);
    }
  }

  String _inferImageMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
