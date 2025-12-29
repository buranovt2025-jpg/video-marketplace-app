import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/services/api_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _settings = [];
  Map<String, dynamic>? _stats;

  final _settingLabels = {
    'platform_commission': 'Комиссия платформы (%)',
    'courier_fee': 'Тариф курьера (сум)',
    'min_order_amount': 'Мин. сумма заказа (сум)',
  };

  final _settingIcons = {
    'platform_commission': Icons.percent,
    'courier_fee': Icons.delivery_dining,
    'min_order_amount': Icons.shopping_cart,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final settings = await ApiService.getSettings();
      final stats = await ApiService.getAdminStats();
      setState(() {
        _settings = List<Map<String, dynamic>>.from(settings);
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Ошибка',
        'Не удалось загрузить настройки',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _updateSetting(String key, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    
    final result = await Get.dialog<String>(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          _settingLabels[key] ?? key,
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Введите значение',
            hintStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[700]!),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: primaryColor),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Отмена', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentValue) {
      try {
        await ApiService.updateSetting(key, result);
        await _loadData();
        Get.snackbar(
          'Успешно',
          'Настройка обновлена',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'Ошибка',
          'Не удалось обновить настройку',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text(
          'Настройки платформы',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats section
                    if (_stats != null) ...[
                      _buildStatsSection(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Settings section
                    const Text(
                      'Настройки комиссий',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._settings.map((setting) => _buildSettingCard(setting)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsSection() {
    final revenue = _stats!['revenue'] as Map<String, dynamic>?;
    final orders = _stats!['orders'] as Map<String, dynamic>?;
    final users = _stats!['users'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Статистика платформы',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Revenue stats
        Row(
          children: [
            Expanded(child: _buildStatCard(
              'Общая выручка',
              '${_formatPrice(revenue?['total'] ?? 0)} сум',
              Icons.account_balance_wallet,
              Colors.green,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              'Доход платформы',
              '${_formatPrice(revenue?['platform_earnings'] ?? 0)} сум',
              Icons.trending_up,
              Colors.blue,
            )),
          ],
        ),
        const SizedBox(height: 12),
        
        // Order stats
        Row(
          children: [
            Expanded(child: _buildStatCard(
              'Всего заказов',
              '${orders?['total'] ?? 0}',
              Icons.receipt_long,
              Colors.purple,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              'Выполнено',
              '${orders?['completed'] ?? 0}',
              Icons.check_circle,
              Colors.green,
            )),
          ],
        ),
        const SizedBox(height: 12),
        
        // User stats
        Row(
          children: [
            Expanded(child: _buildStatCard(
              'Покупатели',
              '${users?['buyers'] ?? 0}',
              Icons.person,
              Colors.blue,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              'Продавцы',
              '${users?['sellers'] ?? 0}',
              Icons.store,
              Colors.orange,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(
              'Курьеры',
              '${users?['couriers'] ?? 0}',
              Icons.delivery_dining,
              Colors.cyan,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              'Товары',
              '${_stats!['products'] ?? 0}',
              Icons.inventory,
              Colors.amber,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(Map<String, dynamic> setting) {
    final key = setting['setting_key'] as String;
    final value = setting['setting_value'] as String;
    final description = setting['description'] as String?;

    return GestureDetector(
      onTap: () => _updateSetting(key, value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _settingIcons[key] ?? Icons.settings,
                color: primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _settingLabels[key] ?? key,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (description != null)
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                key == 'platform_commission' ? '$value%' : _formatPrice(double.tryParse(value) ?? 0),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit, color: Colors.grey[500], size: 20),
          ],
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    final numPrice = price is int ? price.toDouble() : (price as double?) ?? 0.0;
    if (numPrice >= 1000000) {
      return '${(numPrice / 1000000).toStringAsFixed(1)}M';
    } else if (numPrice >= 1000) {
      return '${(numPrice / 1000).toStringAsFixed(0)}K';
    }
    return numPrice.toStringAsFixed(0);
  }
}
