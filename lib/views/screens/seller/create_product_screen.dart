import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gogomarket/constants.dart';
import 'package:gogomarket/controllers/marketplace_controller.dart';
import 'package:gogomarket/services/api_service.dart';

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
  List<String> _imageUrls = []; // Multiple image URLs
  File? _selectedImage; // Single selected image file
  bool _isPickingImage = false;
  
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
        setState(() {
          _selectedImage = File(image.path);
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

  void _showImageSourceDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
              title: const Text('Галерея', style: TextStyle(color: Colors.white)),
              subtitle: Text('Выбрать из галереи', style: TextStyle(color: Colors.grey[500])),
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
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: const Text('Камера', style: TextStyle(color: Colors.white)),
              subtitle: Text('Сделать фото', style: TextStyle(color: Colors.grey[500])),
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

    // Use selected image path or URL
    String? imageUrl = _imageUrlController.text.isNotEmpty 
        ? _imageUrlController.text.trim() 
        : null;
    
    // If local image selected, we'd upload it here (for now use placeholder)
    if (_selectedImage != null && imageUrl == null) {
      // In production, upload to server and get URL
      // For now, use a placeholder
      imageUrl = 'https://via.placeholder.com/400x400?text=${_nameController.text.trim()}';
    }

    final product = await _controller.createProduct(
      name: _nameController.text.trim(),
      price: price,
      description: _descriptionController.text.isNotEmpty 
          ? _descriptionController.text.trim() 
          : null,
      imageUrl: imageUrl,
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
        title: const Text(
          'Новый товар',
          style: TextStyle(color: Colors.white),
        ),
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
            // Image preview / upload area
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImage = null),
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
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              _imageUrlController.text,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                            ),
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
            
            // Name field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Название товара *',
                labelStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.inventory_2, color: Colors.grey[400]),
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
            
            // Price field
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Цена (сум) *',
                labelStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.attach_money, color: Colors.grey[400]),
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
            
            // Quantity field
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Количество в наличии *',
                labelStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.inventory, color: Colors.grey[400]),
                suffixText: 'шт.',
                suffixStyle: TextStyle(color: Colors.grey[500]),
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
            
            // Category dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: Colors.grey[900],
                  icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
                  style: const TextStyle(color: Colors.white),
                  items: [
                    ..._categories.map((category) {
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
                    }),
                    // Add "Request new category" option
                    DropdownMenuItem<String>(
                      value: '_request_new',
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline, color: buttonColor, size: 20),
                          const SizedBox(width: 12),
                          Text('Предложить новую категорию', style: TextStyle(color: buttonColor)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == '_request_new') {
                      _showRequestCategoryDialog();
                    } else {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    }
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
                labelStyle: TextStyle(color: Colors.grey[400]),
                alignLabelWithHint: true,
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
            
            const SizedBox(height: 32),
            
            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue[300]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Добавьте качественное фото и подробное описание для привлечения покупателей',
                      style: TextStyle(color: Colors.blue[300], fontSize: 13),
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
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(
          'Добавить фото',
          style: TextStyle(color: Colors.grey[500]),
        ),
      ],
    );
  }

  void _showRequestCategoryDialog() {
    final nameController = TextEditingController();
    final nameRuController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isSubmitting = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Предложить новую категорию',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ваша заявка будет рассмотрена администратором. После одобрения категория станет доступна для всех продавцов.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Название (латиницей)',
                      hintText: 'например: handmade',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: buttonColor!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameRuController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Название (на русском)',
                      hintText: 'например: Ручная работа',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: buttonColor!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Описание (необязательно)',
                      hintText: 'Какие товары будут в этой категории?',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: buttonColor!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Отмена', style: TextStyle(color: Colors.grey[400])),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (nameController.text.isEmpty || nameRuController.text.isEmpty) {
                          Get.snackbar(
                            'Ошибка',
                            'Заполните оба названия категории',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);

                        try {
                          await ApiService.requestCategory(
                            name: nameController.text.trim(),
                            nameRu: nameRuController.text.trim(),
                            description: descriptionController.text.trim().isNotEmpty
                                ? descriptionController.text.trim()
                                : null,
                          );

                          Get.back();
                          Get.snackbar(
                            'Заявка отправлена',
                            'Администратор рассмотрит вашу заявку на новую категорию',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          Get.snackbar(
                            'Ошибка',
                            e.toString().contains('already exists')
                                ? 'Такая категория уже существует'
                                : e.toString().contains('already pending')
                                    ? 'Заявка на эту категорию уже на рассмотрении'
                                    : 'Не удалось отправить заявку',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Отправить'),
              ),
            ],
          );
        },
      ),
    );
  }
}
