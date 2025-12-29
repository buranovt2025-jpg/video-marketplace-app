import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gogomarket/constants.dart';
import 'package:gogomarket/controllers/marketplace_controller.dart';
import 'package:gogomarket/views/screens/marketplace_home_screen.dart';
import 'package:gogomarket/views/screens/legal/legal_page.dart';

class MarketplaceRegisterScreen extends StatefulWidget {
  const MarketplaceRegisterScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceRegisterScreen> createState() => _MarketplaceRegisterScreenState();
}

class _MarketplaceRegisterScreenState extends State<MarketplaceRegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  
    String _selectedRole = 'buyer';
    bool _obscurePassword = true;
    bool _agreedToTerms = false;

  final List<Map<String, dynamic>> _roles = [
    {
      'value': 'seller',
      'label': 'Продавец',
      'icon': Icons.storefront,
      'description': 'Продавайте товары на платформе',
    },
    {
      'value': 'buyer',
      'label': 'Покупатель',
      'icon': Icons.shopping_bag,
      'description': 'Покупайте товары с доставкой',
    },
    {
      'value': 'courier',
      'label': 'Курьер',
      'icon': Icons.delivery_dining,
      'description': 'Доставляйте заказы и зарабатывайте',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      Get.snackbar(
        'Ошибка',
        'Заполните обязательные поля',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

        if (_passwordController.text.length < 6) {
          Get.snackbar(
            'Ошибка',
            'Пароль должен быть не менее 6 символов',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        if (!_agreedToTerms) {
          Get.snackbar(
            'Ошибка',
            'Необходимо принять условия использования',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        final success = await _controller.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      role: _selectedRole,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text.trim() : null,
      address: _addressController.text.isNotEmpty ? _addressController.text.trim() : null,
    );

    if (success) {
      Get.offAll(() => const MarketplaceHomeScreen());
    } else {
      Get.snackbar(
        'Ошибка',
        _controller.error.value.isNotEmpty 
            ? _controller.error.value 
            : 'Не удалось зарегистрироваться',
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Регистрация',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Role selection
              Text(
                'Выберите роль',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 12),
              
              ...List.generate(_roles.length, (index) {
                final role = _roles[index];
                final isSelected = _selectedRole == role['value'];
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRole = role['value'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? buttonColor!.withOpacity(0.2) : Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? buttonColor! : Colors.grey[800]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          role['icon'],
                          color: isSelected ? buttonColor : Colors.grey[400],
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role['label'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[300],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                role['description'],
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: buttonColor),
                      ],
                    ),
                  ),
                );
              }),
              
              const SizedBox(height: 24),
              
              // Name field
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Имя *',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.person, color: Colors.grey[400]),
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
              
              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email *',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.email, color: Colors.grey[400]),
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
              
              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Пароль *',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.lock, color: Colors.grey[400]),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[400],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
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
              
              // Phone field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Телефон',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.phone, color: Colors.grey[400]),
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
              
              // Address field (important for sellers and buyers)
              TextField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: _selectedRole == 'seller' 
                      ? 'Адрес точки продаж' 
                      : 'Адрес доставки',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.location_on, color: Colors.grey[400]),
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
              
                            // Terms agreement checkbox
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _agreedToTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreedToTerms = value ?? false;
                                      });
                                    },
                                    activeColor: buttonColor,
                                    checkColor: Colors.white,
                                    side: BorderSide(color: Colors.grey[600]!),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Wrap(
                                    children: [
                                      Text(
                                        'Я принимаю условия ',
                                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                      ),
                                      GestureDetector(
                                        onTap: () => Get.to(() => const OfferPage()),
                                        child: Text(
                                          'публичной оферты',
                                          style: TextStyle(
                                            color: buttonColor,
                                            fontSize: 13,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        ', ',
                                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                      ),
                                      GestureDetector(
                                        onTap: () => Get.to(() => const PrivacyPolicyPage()),
                                        child: Text(
                                          'политику конфиденциальности',
                                          style: TextStyle(
                                            color: buttonColor,
                                            fontSize: 13,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        ' и ',
                                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                      ),
                                      GestureDetector(
                                        onTap: () => Get.to(() => const UserAgreementPage()),
                                        child: Text(
                                          'пользовательское соглашение',
                                          style: TextStyle(
                                            color: buttonColor,
                                            fontSize: 13,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
              
                            const SizedBox(height: 24),
              
                            // Register button
                            Obx(() => ElevatedButton(
                onPressed: _controller.isLoading.value ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Зарегистрироваться',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              )),
              
              const SizedBox(height: 16),
              
              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Уже есть аккаунт? ',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Text(
                      'Войти',
                      style: TextStyle(
                        color: buttonColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
