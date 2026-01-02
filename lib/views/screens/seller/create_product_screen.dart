import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/ui/app_ui.dart';
import 'package:tiktok_tutorial/ui/app_media.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({Key? key}) : super(key: key);

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  final ImagePicker _imagePicker = ImagePicker();
  
  String _selectedCategory = 'other';
  Uint8List? _selectedImageBytes;
  String? _selectedImageMime;
  XFile? _selectedVideo;
  bool _isPickingImage = false;
  bool _isPickingVideo = false;
  
  final List<Map<String, String>> _categories = [
    {'value': 'fruits', 'label': 'Фрукты'},
    {'value': 'vegetables', 'label': 'Овощи'},
    {'value': 'meat', 'label': 'Мясо'},
    {'value': 'dairy', 'label': 'Молочные продукты'},
    {'value': 'bakery', 'label': 'Выпечка'},
    {'value': 'drinks', 'label': 'Напитки'},
    {'value': 'spices', 'label': 'Специи'},
    {'value': 'clothes', 'label': 'Одежда'},
    {'value': 'electronics', 'label': 'Электроника'},
    {'value': 'household', 'label': 'Товары для дома'},
    {'value': 'other', 'label': 'Другое'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;
    
    setState(() => _isPickingImage = true);
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageMime = _inferImageMime(image.name);
          _imageUrlController.clear();
        });
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'Не удалось выбрать изображение',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (_isPickingVideo) return;

    setState(() => _isPickingVideo = true);

    try {
      final XFile? video = await _imagePicker.pickVideo(source: source, maxDuration: const Duration(minutes: 2));
      if (video != null) {
        setState(() {
          _selectedVideo = video;
          _videoUrlController.clear();
        });
      }
    } catch (_) {
      Get.snackbar(
        'error'.tr,
        'Не удалось выбрать видео',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isPickingVideo = false);
    }
  }

  void _showImageSourceDialog() {
    Get.bottomSheet(
      Container(
        padding: AppUI.pagePadding,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            const SizedBox(height: 24),
            Text(
              'Выберите источник',
              style: AppUI.h2,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.photo_library, color: primaryColor),
              ),
              title: Text('Галерея', style: AppUI.body),
              subtitle: Text('Выбрать из галереи', style: AppUI.muted),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
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
                child: const Icon(Icons.camera_alt, color: primaryColor),
              ),
              title: Text('Камера', style: AppUI.body),
              subtitle: Text('Сделать фото', style: AppUI.muted),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showVideoSourceDialog() {
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
            Text('Видео товара', style: AppUI.h2),
            const SizedBox(height: 10),
            Text('Можно прикрепить видео или вставить ссылку ниже', style: AppUI.muted, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.video_library, color: primaryColor),
              ),
              title: Text('Галерея', style: AppUI.body),
              subtitle: Text('Выбрать видео', style: AppUI.muted),
              onTap: () {
                Get.back();
                _pickVideo(ImageSource.gallery);
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
                child: const Icon(Icons.videocam, color: primaryColor),
              ),
              title: Text('Камера', style: AppUI.body),
              subtitle: Text('Снять видео', style: AppUI.muted),
              onTap: () {
                Get.back();
                _pickVideo(ImageSource.camera);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _createProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      Get.snackbar(
        'Ошибка',
        'Заполните название и цену',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      Get.snackbar(
        'Ошибка',
        'Введите корректную цену',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity <= 0) {
      Get.snackbar(
        'Ошибка',
        'Количество должно быть больше 0',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Use selected image data-url or URL
    String? imageUrl = _imageUrlController.text.isNotEmpty 
        ? _imageUrlController.text.trim() 
        : null;
    
    if (_selectedImageBytes != null && imageUrl == null) {
      final mime = _selectedImageMime ?? 'image/jpeg';
      imageUrl = 'data:$mime;base64,${base64Encode(_selectedImageBytes!)}';
    }

    // Product video URL (optional)
    String? videoUrl = _videoUrlController.text.isNotEmpty ? _videoUrlController.text.trim() : null;
    if (_selectedVideo != null && videoUrl == null) {
      // NOTE: without server-side upload, we can only store the local path.
      // This is enough for “preview/how it looks” in the UI, but may not be playable elsewhere.
      videoUrl = _selectedVideo!.path;
    }

    final product = await _controller.createProduct(
      name: _nameController.text.trim(),
      price: price,
      description: _descriptionController.text.isNotEmpty 
          ? _descriptionController.text.trim() 
          : null,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      category: _selectedCategory,
      quantity: quantity,
    );

    if (product != null) {
      Get.back();
      Get.snackbar(
        'Успешно',
        'Товар "${product['name']}" создан',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Ошибка',
        _controller.error.value.isNotEmpty 
            ? _controller.error.value 
            : 'Не удалось создать товар',
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
        title: Text('Новый товар', style: AppUI.h2),
        actions: [
          Obx(() => TextButton(
            onPressed: _controller.isLoading.value ? null : _createProduct,
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
                    'Создать',
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
            // Image preview / upload area
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 200,
                decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
                child: _selectedImageBytes != null
                    ? Stack(
                        children: [
                          AppMedia.image(
                            'data:${_selectedImageMime ?? 'image/jpeg'};base64,${base64Encode(_selectedImageBytes!)}',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(AppUI.radiusL),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedImageBytes = null;
                                _selectedImageMime = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _imageUrlController.text.isNotEmpty
                        ? AppMedia.image(
                            _imageUrlController.text,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(AppUI.radiusL),
                          )
                        : _buildImagePlaceholder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Image URL field (temporary until file upload is implemented)
            TextField(
              controller: _imageUrlController,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'URL изображения (опционально)',
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
            const SizedBox(height: 16),

            // Product video (optional)
            InkWell(
              onTap: _showVideoSourceDialog,
              borderRadius: BorderRadius.circular(AppUI.radiusL),
              child: Container(
                padding: AppUI.cardPadding,
                decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(AppUI.radiusM),
                      ),
                      child: Icon(
                        _selectedVideo != null || _videoUrlController.text.isNotEmpty ? Icons.play_circle : Icons.video_call,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Видео товара (опционально)', style: AppUI.h2.copyWith(fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            _selectedVideo != null
                                ? 'Выбрано: ${_selectedVideo!.name}'
                                : (_videoUrlController.text.isNotEmpty ? 'Ссылка добавлена' : 'Нажмите, чтобы выбрать видео'),
                            style: AppUI.muted.copyWith(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (_selectedVideo != null || _videoUrlController.text.isNotEmpty)
                      IconButton(
                        onPressed: () => setState(() {
                          _selectedVideo = null;
                          _videoUrlController.clear();
                        }),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _videoUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'URL видео (опционально)',
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
            ),
            const SizedBox(height: 24),
            
            // Name field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Название товара *',
                labelStyle: AppUI.muted,
                prefixIcon: Icon(Icons.inventory_2, color: Colors.white.withOpacity(0.55)),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppUI.radiusM),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Price field
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Цена (сум) *',
                labelStyle: AppUI.muted,
                prefixIcon: Icon(Icons.attach_money, color: Colors.white.withOpacity(0.55)),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppUI.radiusM),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Quantity field
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Количество в наличии *',
                labelStyle: AppUI.muted,
                prefixIcon: Icon(Icons.inventory, color: Colors.white.withOpacity(0.55)),
                suffixText: 'шт.',
                suffixStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppUI.radiusM),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Category dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: AppUI.inputDecoration(),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: cardColor,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
                  style: const TextStyle(color: Colors.white),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['value'],
                      child: Row(
                        children: [
                          Icon(Icons.category, color: Colors.grey[400], size: 20),
                          const SizedBox(width: 12),
                          Text(category['label']!),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Description field
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Описание',
                labelStyle: AppUI.muted,
                alignLabelWithHint: true,
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppUI.radiusM),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Добавьте качественное фото и подробное описание для привлечения покупателей',
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

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.white.withOpacity(0.3)),
        const SizedBox(height: 8),
        Text(
          'Добавить фото',
          style: AppUI.muted,
        ),
      ],
    );
  }

  String _inferImageMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
