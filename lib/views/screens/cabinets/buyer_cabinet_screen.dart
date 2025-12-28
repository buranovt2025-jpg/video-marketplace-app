import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/views/screens/buyer/order_tracking_screen.dart';

class BuyerCabinetScreen extends StatefulWidget {
  const BuyerCabinetScreen({Key? key}) : super(key: key);

  @override
  State<BuyerCabinetScreen> createState() => _BuyerCabinetScreenState();
}

class _BuyerCabinetScreenState extends State<BuyerCabinetScreen> with SingleTickerProviderStateMixin {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  late TabController _tabController;
  
  // Local state for addresses and favorites
  final RxList<Map<String, dynamic>> _addresses = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _favorites = <Map<String, dynamic>>[].obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _controller.fetchOrders();
    // Load saved addresses from user data
    final user = _controller.currentUser.value;
    if (user != null && user['addresses'] != null) {
      _addresses.value = List<Map<String, dynamic>>.from(user['addresses']);
    }
    // Initialize with default address if empty
    if (_addresses.isEmpty) {
      _addresses.add({
        'id': '1',
        'name': 'Дом',
        'address': user?['address'] ?? 'Не указан',
        'isDefault': true,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text('my_cabinet'.tr, style: const TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'orders'.tr),
            Tab(text: 'favorites'.tr),
            Tab(text: 'addresses'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab(),
          _buildFavoritesTab(),
          _buildAddressesTab(),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Obx(() {
      final orders = _controller.orders.where((o) {
        final buyerId = _controller.currentUser.value?['id'];
        return o['buyer_id'] == buyerId;
      }).toList();

      if (orders.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[700]),
              const SizedBox(height: 16),
              Text(
                'Нет заказов',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Ваши заказы появятся здесь',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _loadData,
        color: primaryColor,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        ),
      );
    });
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Ожидает подтверждения';
        statusIcon = Icons.pending;
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusText = 'Принят продавцом';
        statusIcon = Icons.check_circle;
        break;
      case 'ready':
        statusColor = Colors.purple;
        statusText = 'Готов к выдаче';
        statusIcon = Icons.inventory;
        break;
      case 'in_delivery':
        statusColor = primaryColor;
        statusText = 'В пути';
        statusIcon = Icons.local_shipping;
        break;
      case 'delivered':
        statusColor = Colors.green;
        statusText = 'Доставлен';
        statusIcon = Icons.done_all;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Отклонён';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
        statusIcon = Icons.help;
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Get.to(() => OrderTrackingScreen(order: order)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Заказ #${order['id']?.toString().substring(0, 8) ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[600]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(color: statusColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Сумма: ${order['total_amount']?.toStringAsFixed(0) ?? '0'} сум',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              
              // Problem button for non-delivered orders
              if (status != 'delivered' && status != 'rejected')
                OutlinedButton.icon(
                  onPressed: () => _reportProblem(order),
                  icon: const Icon(Icons.warning_amber, size: 18),
                  label: Text('problem_with_order'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportProblem(Map<String, dynamic> order) {
    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        title: Text('report_problem'.tr, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProblemOption('Заказ не приходит', Icons.schedule),
            _buildProblemOption('Неправильный товар', Icons.inventory_2),
            _buildProblemOption('Повреждённый товар', Icons.broken_image),
            _buildProblemOption('Другая проблема', Icons.help_outline),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemOption(String text, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Get.back();
        Get.snackbar(
          'Жалоба отправлена',
          'Администратор рассмотрит вашу жалобу',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return Obx(() {
      if (_favorites.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 64, color: Colors.grey[700]),
              const SizedBox(height: 16),
              Text(
                'Нет избранных товаров',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Нажмите на сердечко, чтобы\nдобавить товар в избранное',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final product = _favorites[index];
          return _buildFavoriteCard(product);
        },
      );
    });
  }

  Widget _buildFavoriteCard(Map<String, dynamic> product) {
    return Card(
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: product['image_url'] != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            product['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.inventory_2,
                              color: Colors.grey[600],
                              size: 48,
                            ),
                          ),
                        )
                      : Icon(Icons.inventory_2, color: Colors.grey[600], size: 48),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      _favorites.remove(product);
                      Get.snackbar(
                        'Удалено',
                        'Товар удалён из избранного',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite, color: Colors.red, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'Товар',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${product['price']?.toStringAsFixed(0) ?? '0'} сум',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesTab() {
    return Obx(() {
      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final address = _addresses[index];
                return _buildAddressCard(address, index);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addNewAddress,
                icon: const Icon(Icons.add),
                label: const Text('Добавить адрес'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAddressCard(Map<String, dynamic> address, int index) {
    final isDefault = address['isDefault'] == true;
    
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDefault ? primaryColor.withOpacity(0.2) : Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                address['name'] == 'Дом' ? Icons.home : 
                address['name'] == 'Работа' ? Icons.work : Icons.location_on,
                color: isDefault ? primaryColor : Colors.grey[500],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address['name'] ?? 'Адрес',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Основной',
                            style: TextStyle(color: primaryColor, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address['address'] ?? '',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              color: cardColor,
              onSelected: (value) {
                if (value == 'default') {
                  _setDefaultAddress(index);
                } else if (value == 'edit') {
                  _editAddress(index);
                } else if (value == 'delete') {
                  _deleteAddress(index);
                }
              },
              itemBuilder: (context) => [
                if (!isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Text('Сделать основным', style: TextStyle(color: Colors.white)),
                  ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Редактировать', style: TextStyle(color: Colors.white)),
                ),
                if (_addresses.length > 1)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Удалить', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setDefaultAddress(int index) {
    for (int i = 0; i < _addresses.length; i++) {
      _addresses[i]['isDefault'] = i == index;
    }
    _addresses.refresh();
    Get.snackbar('success'.tr, 'Адрес установлен как основной', snackPosition: SnackPosition.BOTTOM);
  }

  void _editAddress(int index) {
    final address = _addresses[index];
    final nameController = TextEditingController(text: address['name']);
    final addressController = TextEditingController(text: address['address']);

    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Редактировать адрес', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Название',
                labelStyle: TextStyle(color: Colors.grey[500]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Адрес',
                labelStyle: TextStyle(color: Colors.grey[500]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _addresses[index]['name'] = nameController.text;
              _addresses[index]['address'] = addressController.text;
              _addresses.refresh();
              Get.back();
              Get.snackbar('success'.tr, 'Адрес обновлён', snackPosition: SnackPosition.BOTTOM);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }

  void _deleteAddress(int index) {
    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Удалить адрес?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Вы уверены, что хотите удалить этот адрес?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _addresses.removeAt(index);
              Get.back();
              Get.snackbar('success'.tr, 'Адрес удалён', snackPosition: SnackPosition.BOTTOM);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  void _addNewAddress() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Новый адрес', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Название (Дом, Работа...)',
                labelStyle: TextStyle(color: Colors.grey[500]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Адрес',
                labelStyle: TextStyle(color: Colors.grey[500]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && addressController.text.isNotEmpty) {
                _addresses.add({
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': nameController.text,
                  'address': addressController.text,
                  'isDefault': false,
                });
                Get.back();
                Get.snackbar('success'.tr, 'Адрес добавлен', snackPosition: SnackPosition.BOTTOM);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}
