import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/utils/responsive_helper.dart';
import 'package:tiktok_tutorial/views/screens/auth/marketplace_register_screen.dart';
import 'package:tiktok_tutorial/views/screens/auth/forgot_password_screen.dart';
import 'package:tiktok_tutorial/views/screens/marketplace_home_screen.dart';
import 'package:tiktok_tutorial/views/screens/courier/courier_home_screen.dart';
import 'package:tiktok_tutorial/views/screens/admin/admin_home_screen.dart';

class MarketplaceLoginScreen extends StatefulWidget {
  const MarketplaceLoginScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceLoginScreen> createState() => _MarketplaceLoginScreenState();
}

class _MarketplaceLoginScreenState extends State<MarketplaceLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _continueAsGuest() {
    _controller.setGuestMode(true);
    Get.offAll(() => const MarketplaceHomeScreen());
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Get.snackbar(
        'Ошибка',
        'Заполните все поля',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final success = await _controller.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      // Route based on user role
      if (_controller.isAdmin) {
        Get.offAll(() => const AdminHomeScreen());
      } else if (_controller.isCourier) {
        Get.offAll(() => const CourierHomeScreen());
      } else {
        Get.offAll(() => const MarketplaceHomeScreen());
      }
    }else {
      Get.snackbar(
        'Ошибка',
        _controller.error.value.isNotEmpty 
            ? _controller.error.value 
            : 'Неверный email или пароль',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive max width for form content
    final maxFormWidth = ResponsiveHelper.responsiveValue(
      context,
      mobile: double.infinity,
      tablet: 450.0,
      desktop: 450.0,
    );
    
    final horizontalPadding = ResponsiveHelper.responsiveValue(
      context,
      mobile: 24.0,
      tablet: 48.0,
      desktop: 64.0,
    );
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxFormWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
              
                            // Logo
                            Image.asset(
                              'assets/images/logo_white.png',
                              height: 120,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.storefront,
                                size: 80,
                                color: buttonColor,
                              ),
                            ),
                            const SizedBox(height: 16),
              
                            // Title
                            const Text(
                              'GoGoMarket',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Оптовые рынки в твоём телефоне',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
              
              const SizedBox(height: 48),
              
              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.email, color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: buttonColor),
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
                  labelText: 'Пароль',
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
                    borderSide: BorderSide(color: buttonColor),
                  ),
                  filled: true,
                  fillColor: Colors.grey[900],
                ),
              ),
              
              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.to(() => const ForgotPasswordScreen()),
                  child: Text(
                    'forgot_password'.tr,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Login button
              Obx(() => ElevatedButton(
                onPressed: _controller.isLoading.value ? null : _login,
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
                        'Войти',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              )),
              
              const SizedBox(height: 24),
              
              // Demo accounts info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Демо-аккаунты:',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDemoAccount('Продавец', 'seller@demo.com'),
                    _buildDemoAccount('Покупатель', 'buyer@demo.com'),
                    _buildDemoAccount('Курьер', 'courier@demo.com'),
                    _buildDemoAccount('Админ', 'admin@demo.com'),
                    const SizedBox(height: 4),
                    Text(
                      'Пароль: demo123 (admin123 для админа)',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
                          // Guest mode button
                          OutlinedButton.icon(
                            onPressed: () => _continueAsGuest(),
                            icon: const Icon(Icons.visibility),
                            label: Text('continue_as_guest'.tr),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[400],
                              side: BorderSide(color: Colors.grey[700]!),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
              
                          const SizedBox(height: 16),
              
                          // Register link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Нет аккаунта? ',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              GestureDetector(
                                onTap: () => Get.to(() => const MarketplaceRegisterScreen()),
                                child: Text(
                                  'Зарегистрироваться',
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
        ),
      ),
    );
  }

  Widget _buildDemoAccount(String role, String email) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onTap: () {
          _emailController.text = email;
          _passwordController.text = email.contains('admin') ? 'admin123' : 'demo123';
        },
        child: Row(
          children: [
            Icon(Icons.person, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Text(
              '$role: ',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            Text(
              email,
              style: TextStyle(color: buttonColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
