import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/ui/app_ui.dart';

class CreateReelScreen extends StatefulWidget {
  const CreateReelScreen({Key? key}) : super(key: key);

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedVideo;
  bool _isPickingVideo = false;
  
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
    final url = _videoUrlController.text.trim();
    final effectiveVideoUrl = url.isNotEmpty ? url : _selectedVideo?.path;
    if (effectiveVideoUrl == null || effectiveVideoUrl.isEmpty) {
      Get.snackbar(
        'Ошибка',
        'Добавьте видео или ссылку на видео',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final reel = await _controller.createReel(
      videoUrl: effectiveVideoUrl,
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
        title: Text('Новый рилс', style: AppUI.h2),
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
            // Video preview area
            InkWell(
              onTap: _showVideoSourceDialog,
              borderRadius: BorderRadius.circular(AppUI.radiusL),
              child: Container(
                height: 400,
                decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_call, size: 64, color: Colors.white.withOpacity(0.25)),
                    const SizedBox(height: 16),
                    Text(
                      _selectedVideo != null ? 'Выбрано: ${_selectedVideo!.name}' : 'Добавить видео',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Рекомендуемый формат: 9:16',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                    if (_isPickingVideo) ...[
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
            
            // Video URL field (temporary until file upload is implemented)
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
                labelStyle: AppUI.muted,
                hintText: 'Расскажите о вашем товаре...',
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
                          'У вас пока нет товаров. Создайте товар, чтобы привязать его к рилсу.',
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
            
            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tips_and_updates, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Советы для рилсов',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w700,
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
                    style: AppUI.muted,
                  ),
                ],
              ),
            ),
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
            Text('Видео для рилса', style: AppUI.h2),
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

  Future<void> _pickVideo(ImageSource source) async {
    if (_isPickingVideo) return;
    setState(() => _isPickingVideo = true);
    try {
      final XFile? video = await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 2));
      if (video != null) {
        setState(() {
          _selectedVideo = video;
          _videoUrlController.text = video.path;
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
}
