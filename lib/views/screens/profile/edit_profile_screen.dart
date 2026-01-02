import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/services/api_service.dart';
import 'package:tiktok_tutorial/ui/app_ui.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  String? _avatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = _controller.currentUser.value;
    if (user != null) {
      _nameController.text = user['name'] ?? '';
      _phoneController.text = user['phone'] ?? '';
      _addressController.text = user['address'] ?? '';
      _avatarUrl = user['avatar_url'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: AppUI.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: Text('Камера', style: AppUI.body),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: Text('Галерея', style: AppUI.body),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                },
              ),
              if (_avatarUrl != null || _selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Удалить фото', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _avatarUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Ошибка',
        'Имя не может быть пустым',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // For now, we'll use a placeholder URL for avatar
      // In production, you would upload to DigitalOcean Spaces or similar
      String? avatarUrl = _avatarUrl;
      
      if (_selectedImage != null) {
        // Placeholder: In production, upload image to cloud storage
        // For MVP, we'll use a demo avatar URL
        avatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_nameController.text)}&background=random&size=256';
      }

      final updates = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        'address': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        'avatar_url': avatarUrl,
      };

      await ApiService.updateMe(updates);
      await _controller.fetchCurrentUser();

      Get.back();
      Get.snackbar(
        'Успешно',
        'Профиль обновлён',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось обновить профиль: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text('Редактировать профиль', style: AppUI.h2),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Сохранить', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppUI.pagePadding,
        child: Column(
          children: [
            // Avatar section
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null) as ImageProvider?,
                    child: (_selectedImage == null && _avatarUrl == null)
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: backgroundColor, width: 3),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Изменить фото',
              style: const TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            
            const SizedBox(height: 32),
            
            // Name field
            _buildTextField(
              controller: _nameController,
              label: 'Имя',
              icon: Icons.person,
              required: true,
            ),
            const SizedBox(height: 16),
            
            // Phone field
            _buildTextField(
              controller: _phoneController,
              label: 'Телефон',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            // Address field
            _buildTextField(
              controller: _addressController,
              label: 'Адрес',
              icon: Icons.location_on,
              maxLines: 2,
            ),
            
            const SizedBox(height: 32),
            
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white.withOpacity(0.45)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Email и роль нельзя изменить. Обратитесь в поддержку если нужна помощь.',
                      style: AppUI.muted,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current email (read-only)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: AppUI.muted.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _controller.userEmail,
                          style: AppUI.body,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.lock, color: Colors.white.withOpacity(0.25), size: 16),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Current role (read-only)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppUI.cardDecoration(radius: AppUI.radiusL),
              child: Row(
                children: [
                  Icon(Icons.badge, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Роль',
                          style: AppUI.muted.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRoleLabel(_controller.userRole),
                          style: AppUI.body,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.lock, color: Colors.white.withOpacity(0.25), size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: AppUI.muted,
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.55)),
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUI.radiusM),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'seller':
        return 'Продавец';
      case 'buyer':
        return 'Покупатель';
      case 'courier':
        return 'Курьер';
      case 'admin':
        return 'Администратор';
      default:
        return role;
    }
  }
}
