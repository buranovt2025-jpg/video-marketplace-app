import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/services/api_service.dart';
import 'package:tiktok_tutorial/views/screens/chat/chat_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _filterRole = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await ApiService.getUsers();
      setState(() {
        _users = List<Map<String, dynamic>>.from(users);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Ошибка',
        'Не удалось загрузить пользователей',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var filtered = _users;
    
    if (_filterRole != 'all') {
      filtered = filtered.where((u) => u['role'] == _filterRole).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((u) {
        final name = (u['name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final phone = (u['phone'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query) || phone.contains(query);
      }).toList();
    }
    
    return filtered;
  }

  void _showUserDetails(Map<String, dynamic> user) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserDetailSheet(
        user: user,
        onRefresh: _loadUsers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text(
          'Пользователи',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Поиск по имени, email, телефону...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[500]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Все', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Продавцы', 'seller'),
                const SizedBox(width: 8),
                _buildFilterChip('Покупатели', 'buyer'),
                const SizedBox(width: 8),
                _buildFilterChip('Курьеры', 'courier'),
                const SizedBox(width: 8),
                _buildFilterChip('Админы', 'admin'),
              ],
            ),
          ),
          
          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Всего: ${_filteredUsers.length}',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const Spacer(),
                Text(
                  'Нажмите для деталей',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[700]),
                            const SizedBox(height: 16),
                            Text(
                              'Нет пользователей',
                              style: TextStyle(color: Colors.grey[500], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return _buildUserCard(user);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String role) {
    final isSelected = _filterRole == role;
    return GestureDetector(
      onTap: () => setState(() => _filterRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? buttonColor : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final roleColors = {
      'seller': Colors.green,
      'buyer': Colors.blue,
      'courier': Colors.orange,
      'admin': Colors.purple,
    };

    final roleLabels = {
      'seller': 'Продавец',
      'buyer': 'Покупатель',
      'courier': 'Курьер',
      'admin': 'Админ',
    };

    final role = user['role'] ?? 'buyer';
    final isBlocked = user['is_blocked'] == true;
    final isVerified = user['is_verified'] == true;

    return GestureDetector(
      onTap: () => _showUserDetails(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isBlocked ? Colors.red[900]?.withOpacity(0.3) : Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: isBlocked ? Border.all(color: Colors.red, width: 1) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: roleColors[role]?.withOpacity(0.2),
                      backgroundImage: user['avatar'] != null && user['avatar'].toString().isNotEmpty
                          ? NetworkImage(user['avatar'])
                          : null,
                      child: user['avatar'] == null || user['avatar'].toString().isEmpty
                          ? Icon(Icons.person, color: roleColors[role], size: 24)
                          : null,
                    ),
                    if (isVerified)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                
                // Name and email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user['name'] ?? 'Без имени',
                              style: TextStyle(
                                color: isBlocked ? Colors.red[300] : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isBlocked) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ЗАБЛОКИРОВАН',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        user['email'] ?? '',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColors[role]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roleLabels[role] ?? role,
                    style: TextStyle(
                      color: roleColors[role],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Arrow icon
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey[600]),
              ],
            ),
            
            // Address if available
            if (user['address'] != null && user['address'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      user['address'],
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            // Phone if available
            if (user['phone'] != null && user['phone'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    user['phone'],
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ],
            
            // User ID
            const SizedBox(height: 8),
            Text(
              'ID: ${user['id']?.toString().substring(0, 8) ?? ''}',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class UserDetailSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onRefresh;

  const UserDetailSheet({
    Key? key,
    required this.user,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<UserDetailSheet> {
  Map<String, dynamic>? _userDetails;
  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    try {
      final userId = widget.user['id'];
      if (userId != null) {
        final details = await ApiService.getUserDetails(int.parse(userId.toString()));
        setState(() {
          _userDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Ошибка',
        'Не удалось загрузить детали пользователя',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _blockUser() async {
    final user = _userDetails ?? widget.user;
    final isBlocked = user['is_blocked'] == true;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          isBlocked ? 'Разблокировать пользователя?' : 'Заблокировать пользователя?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isBlocked 
              ? 'Пользователь сможет снова использовать приложение'
              : 'Пользователь не сможет использовать приложение',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked ? Colors.green : Colors.red,
            ),
            child: Text(isBlocked ? 'Разблокировать' : 'Заблокировать'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isActionLoading = true);
      try {
        final userId = int.parse(user['id'].toString());
        await ApiService.blockUser(userId, isBlocked: !isBlocked);
        Get.snackbar(
          'Успешно',
          isBlocked ? 'Пользователь разблокирован' : 'Пользователь заблокирован',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        widget.onRefresh();
        Navigator.pop(context);
      } catch (e) {
        Get.snackbar(
          'Ошибка',
          'Не удалось выполнить действие',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _approveUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Одобрить пользователя?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Пользователь получит статус верифицированного',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Одобрить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isActionLoading = true);
      try {
        final user = _userDetails ?? widget.user;
        final userId = int.parse(user['id'].toString());
        await ApiService.approveUser(userId);
        Get.snackbar(
          'Успешно',
          'Пользователь одобрен',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        widget.onRefresh();
        Navigator.pop(context);
      } catch (e) {
        Get.snackbar(
          'Ошибка',
          'Не удалось одобрить пользователя',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        setState(() => _isActionLoading = false);
      }
    }
  }

  void _editUser() {
    final user = _userDetails ?? widget.user;
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(
        user: user,
        onSave: (updates) async {
          setState(() => _isActionLoading = true);
          try {
            final userId = int.parse(user['id'].toString());
            await ApiService.adminUpdateUser(userId, updates);
            Get.snackbar(
              'Успешно',
              'Данные пользователя обновлены',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            widget.onRefresh();
            Navigator.pop(context);
          } catch (e) {
            Get.snackbar(
              'Ошибка',
              'Не удалось обновить данные',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          } finally {
            setState(() => _isActionLoading = false);
          }
        },
      ),
    );
  }

  void _openChat() {
    final user = _userDetails ?? widget.user;
    Navigator.pop(context);
    Get.to(() => ChatScreen(
      userId: user['id'].toString(),
      userName: user['name'] ?? 'Пользователь',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = _userDetails ?? widget.user;
    final isBlocked = user['is_blocked'] == true;
    final isVerified = user['is_verified'] == true;

    final roleColors = {
      'seller': Colors.green,
      'buyer': Colors.blue,
      'courier': Colors.orange,
      'admin': Colors.purple,
    };

    final roleLabels = {
      'seller': 'Продавец',
      'buyer': 'Покупатель',
      'courier': 'Курьер',
      'admin': 'Админ',
    };

    final role = user['role'] ?? 'buyer';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: roleColors[role]?.withOpacity(0.2),
                            backgroundImage: user['avatar'] != null && user['avatar'].toString().isNotEmpty
                                ? NetworkImage(user['avatar'])
                                : null,
                            child: user['avatar'] == null || user['avatar'].toString().isEmpty
                                ? Icon(Icons.person, color: roleColors[role], size: 36)
                                : null,
                          ),
                          if (isVerified)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 16),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user['name'] ?? 'Без имени',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isBlocked) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ЗАБЛОКИРОВАН',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: roleColors[role]?.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                roleLabels[role] ?? role,
                                style: TextStyle(
                                  color: roleColors[role],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // User details
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSection('Контактная информация', [
                          _buildDetailRow(Icons.email, 'Email', user['email'] ?? 'Не указан'),
                          _buildDetailRow(Icons.phone, 'Телефон', user['phone'] ?? 'Не указан'),
                          _buildDetailRow(Icons.location_on, 'Адрес', user['address'] ?? 'Не указан'),
                        ]),
                        
                        const SizedBox(height: 16),
                        
                        _buildDetailSection('Статус аккаунта', [
                          _buildDetailRow(
                            Icons.verified_user,
                            'Верификация',
                            isVerified ? 'Верифицирован' : 'Не верифицирован',
                            valueColor: isVerified ? Colors.green : Colors.orange,
                          ),
                          _buildDetailRow(
                            Icons.block,
                            'Статус',
                            isBlocked ? 'Заблокирован' : 'Активен',
                            valueColor: isBlocked ? Colors.red : Colors.green,
                          ),
                          if (user['block_reason'] != null && user['block_reason'].toString().isNotEmpty)
                            _buildDetailRow(Icons.info, 'Причина блокировки', user['block_reason']),
                        ]),
                        
                        const SizedBox(height: 16),
                        
                        if (_userDetails != null) ...[
                          _buildDetailSection('Статистика', [
                            _buildDetailRow(Icons.shopping_bag, 'Заказов', '${_userDetails!['orders_count'] ?? 0}'),
                            _buildDetailRow(Icons.inventory, 'Товаров', '${_userDetails!['products_count'] ?? 0}'),
                          ]),
                          
                          const SizedBox(height: 16),
                        ],
                        
                        _buildDetailSection('Системная информация', [
                          _buildDetailRow(Icons.fingerprint, 'ID', user['id']?.toString() ?? ''),
                          _buildDetailRow(Icons.calendar_today, 'Дата регистрации', _formatDate(user['created_at'])),
                          if (user['roles'] != null)
                            _buildDetailRow(Icons.people, 'Роли', (user['roles'] as List?)?.join(', ') ?? ''),
                        ]),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                
                // Action buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: _isActionLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.chat,
                                    label: 'Чат',
                                    color: Colors.blue,
                                    onTap: _openChat,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.edit,
                                    label: 'Редактировать',
                                    color: Colors.orange,
                                    onTap: _editUser,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (!isVerified)
                                  Expanded(
                                    child: _buildActionButton(
                                      icon: Icons.check_circle,
                                      label: 'Одобрить',
                                      color: Colors.green,
                                      onTap: _approveUser,
                                    ),
                                  ),
                                if (!isVerified) const SizedBox(width: 12),
                                Expanded(
                                  child: _buildActionButton(
                                    icon: isBlocked ? Icons.lock_open : Icons.block,
                                    label: isBlocked ? 'Разблокировать' : 'Заблокировать',
                                    color: isBlocked ? Colors.green : Colors.red,
                                    onTap: _blockUser,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Не указана';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (e) {
      return date.toString();
    }
  }
}

class EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(Map<String, dynamic>) onSave;

  const EditUserDialog({
    Key? key,
    required this.user,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String _selectedRole = 'buyer';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name'] ?? '');
    _phoneController = TextEditingController(text: widget.user['phone'] ?? '');
    _addressController = TextEditingController(text: widget.user['address'] ?? '');
    _selectedRole = widget.user['role'] ?? 'buyer';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        'Редактировать пользователя',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Имя',
                labelStyle: TextStyle(color: Colors.grey[500]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: buttonColor),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Телефон',
                labelStyle: TextStyle(color: Colors.grey[500]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: buttonColor),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Адрес',
                labelStyle: TextStyle(color: Colors.grey[500]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: buttonColor),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Роль',
                labelStyle: TextStyle(color: Colors.grey[500]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: buttonColor),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'buyer', child: Text('Покупатель')),
                DropdownMenuItem(value: 'seller', child: Text('Продавец')),
                DropdownMenuItem(value: 'courier', child: Text('Курьер')),
                DropdownMenuItem(value: 'admin', child: Text('Админ')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            final updates = <String, dynamic>{};
            if (_nameController.text.isNotEmpty) {
              updates['name'] = _nameController.text;
            }
            if (_phoneController.text.isNotEmpty) {
              updates['phone'] = _phoneController.text;
            }
            if (_addressController.text.isNotEmpty) {
              updates['address'] = _addressController.text;
            }
            if (_selectedRole != widget.user['role']) {
              updates['role'] = _selectedRole;
            }
            
            Navigator.pop(context);
            widget.onSave(updates);
          },
          style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
