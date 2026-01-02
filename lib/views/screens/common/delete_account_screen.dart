import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/services/api_service.dart';
import 'package:tiktok_tutorial/ui/app_ui.dart';
import 'package:tiktok_tutorial/views/screens/auth/marketplace_login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({Key? key}) : super(key: key);

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  
  bool _isLoading = false;
  bool _confirmChecked = false;
  String? _selectedReason;
  
  final List<String> _reasons = [
    'Больше не пользуюсь',
    'Нашёл другую платформу',
    'Проблемы с приложением',
    'Конфиденциальность',
    'Другое',
  ];

  @override
  void dispose() {
    _passwordController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_confirmChecked) {
      Get.snackbar(
        'error'.tr,
        'Подтвердите удаление аккаунта',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'Введите пароль для подтверждения',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: cardColor,
        title: Text('Удалить аккаунт?', style: AppUI.h2),
        content: Text(
          'Это действие нельзя отменить. Все ваши данные будут удалены навсегда.',
          style: AppUI.muted,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr, style: AppUI.muted),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUI.radiusM)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // In real app, this would call API to delete account
      // For demo, we'll simulate the deletion
      await Future.delayed(const Duration(seconds: 2));
      
      // Log out and clear data
      await ApiService.clearToken();
      
      Get.snackbar(
        'success'.tr,
        'Аккаунт успешно удалён',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      // Navigate to login screen
      Get.offAll(() => const MarketplaceLoginScreen());
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'Ошибка при удалении аккаунта',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'delete_account'.tr,
          style: AppUI.h2,
        ),
      ),
      body: SingleChildScrollView(
        padding: AppUI.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 60,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Warning text
            Center(child: Text('Удаление аккаунта', style: AppUI.h1)),
            const SizedBox(height: 12),
            Text(
              'После удаления аккаунта вы потеряете:',
              style: AppUI.muted.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // What will be deleted
            _buildDeleteItem('Все ваши заказы и историю'),
            _buildDeleteItem('Избранные товары'),
            _buildDeleteItem('Сохранённые адреса'),
            _buildDeleteItem('Отзывы и рейтинги'),
            if (_controller.currentUser.value?['role'] == 'seller') ...[
              _buildDeleteItem('Все ваши товары'),
              _buildDeleteItem('Рилсы и истории'),
              _buildDeleteItem('Статистику продаж'),
            ],
            
            const SizedBox(height: 32),
            
            // Reason selection
            Text(
              'Причина удаления',
              style: AppUI.muted,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: AppUI.inputDecoration(),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  hint: Text('Выберите причину', style: AppUI.muted),
                  dropdownColor: cardColor,
                  isExpanded: true,
                  items: _reasons.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason, style: AppUI.body),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedReason = value);
                  },
                ),
              ),
            ),
            
            if (_selectedReason == 'Другое') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Опишите причину...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppUI.radiusM),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Password confirmation
            Text(
              'Подтвердите паролем',
              style: AppUI.muted,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Введите пароль',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: surfaceColor,
                prefixIcon: Icon(Icons.lock, color: Colors.white.withOpacity(0.55)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppUI.radiusM),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Confirmation checkbox
            Row(
              children: [
                Checkbox(
                  value: _confirmChecked,
                  onChanged: (value) {
                    setState(() => _confirmChecked = value ?? false);
                  },
                  activeColor: Colors.red,
                ),
                Expanded(
                  child: Text(
                    'Я понимаю, что это действие необратимо',
                    style: AppUI.muted,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Delete button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppUI.radiusM),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'delete_account'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cancel button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: AppUI.outlineButton(),
                child: Text(
                  'cancel'.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.remove_circle, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Text(text, style: AppUI.muted),
        ],
      ),
    );
  }
}
