import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/services/api_service.dart';
import 'package:tiktok_tutorial/utils/formatters.dart';
import 'package:tiktok_tutorial/views/screens/buyer/product_detail_screen.dart';
import 'package:tiktok_tutorial/views/widgets/app_network_image.dart';

class SmartSearchScreen extends StatefulWidget {
  const SmartSearchScreen({Key? key}) : super(key: key);

  @override
  State<SmartSearchScreen> createState() => _SmartSearchScreenState();
}

class _SmartSearchScreenState extends State<SmartSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  final FocusNode _focusNode = FocusNode();
  
  String _selectedCategory = 'all';
  String? _selectedSellerId;
  String? _selectedSellerName;
  List<Map<String, dynamic>> _sellers = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'all_categories', 'icon': 'apps'},
    {'value': 'fruits', 'label': 'fruits', 'icon': 'apple'},
    {'value': 'vegetables', 'label': 'vegetables', 'icon': 'eco'},
    {'value': 'meat', 'label': 'meat', 'icon': 'restaurant'},
    {'value': 'dairy', 'label': 'dairy', 'icon': 'egg'},
    {'value': 'bakery', 'label': 'bakery', 'icon': 'bakery_dining'},
    {'value': 'drinks', 'label': 'drinks', 'icon': 'local_drink'},
    {'value': 'spices', 'label': 'spices', 'icon': 'spa'},
    {'value': 'clothes', 'label': 'clothes', 'icon': 'checkroom'},
    {'value': 'electronics', 'label': 'electronics', 'icon': 'devices'},
    {'value': 'household', 'label': 'household', 'icon': 'home'},
    {'value': 'other', 'label': 'other', 'icon': 'more_horiz'},
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    // Generate suggestions from products
    final products = _controller.products;
    final Set<String> suggestionSet = {};
    
    for (var product in products) {
      final name = product['name']?.toString().toLowerCase() ?? '';
      final description = product['description']?.toString().toLowerCase() ?? '';
      final category = product['category']?.toString().toLowerCase() ?? '';
      final sellerName = product['seller_name']?.toString().toLowerCase() ?? '';
      final queryLower = query.toLowerCase();
      
      if (name.contains(queryLower)) {
        suggestionSet.add(product['name']);
      }
      if (category.contains(queryLower)) {
        suggestionSet.add(_getCategoryLabel(product['category']));
      }
      if (sellerName.contains(queryLower)) {
        suggestionSet.add(product['seller_name']);
      }
    }

    setState(() {
      _suggestions = suggestionSet.take(5).toList();
      _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
    });
  }

  String _getCategoryLabel(String? category) {
    if (category == null) return 'other'.tr;
    final cat = _categories.firstWhere(
      (c) => c['value'] == category,
      orElse: () => {'label': 'other'},
    );
    return cat['label']!.tr;
  }

  Future<void> _performSearch() async {
    final rawQuery = _searchController.text.trim();
    final query = rawQuery.toLowerCase();

    setState(() {
      _isSearching = true;
      _showSuggestions = false;
    });

    final category = _selectedCategory == 'all' ? null : _selectedCategory;
    final search = query.isEmpty ? null : query;
    final sellerId = _selectedSellerId;

    try {
      // Prefer server-side search so results don't depend on initial feed size.
      final data = await ApiService.getProducts(
        sellerId: sellerId,
        category: category,
        search: search,
      );
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(data);
      });
    } catch (_) {
      // Fallback to local filter if API search fails (offline/self-signed/etc).
      final products = _controller.products;
      final results = products.where((product) {
        if (category != null && product['category'] != category) return false;
        if (sellerId != null && sellerId.isNotEmpty) {
          if (product['seller_id']?.toString() != sellerId) return false;
        }
        if (query.isEmpty) return true;

        final name = product['name']?.toString().toLowerCase() ?? '';
        final description = product['description']?.toString().toLowerCase() ?? '';
        final cat = product['category']?.toString().toLowerCase() ?? '';
        final sellerName = product['seller_name']?.toString().toLowerCase() ?? '';
        return name.contains(query) ||
            description.contains(query) ||
            cat.contains(query) ||
            sellerName.contains(query);
      }).toList();

      setState(() {
        _searchResults = results;
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _ensureSellersLoaded() async {
    if (_sellers.isNotEmpty) return;
    try {
      final data = await ApiService.getSellers();
      setState(() {
        _sellers = List<Map<String, dynamic>>.from(data);
      });
    } catch (_) {
      // Ignore; we will show an error when trying to open picker.
    }
  }

  Future<void> _pickSeller() async {
    await _ensureSellersLoaded();

    if (_sellers.isEmpty) {
      Get.snackbar(
        'Ошибка',
        'Не удалось загрузить продавцов',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) {
        final q = TextEditingController();
        List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>.from(_sellers);

        void applyFilter(String text) {
          final s = text.trim().toLowerCase();
          filtered = _sellers.where((e) {
            final name = e['name']?.toString().toLowerCase() ?? '';
            final email = e['email']?.toString().toLowerCase() ?? '';
            return s.isEmpty || name.contains(s) || email.contains(s);
          }).toList();
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: q,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Поиск продавца',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.store, color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) {
                          setModalState(() {
                            applyFilter(v);
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length + 1,
                        separatorBuilder: (_, __) => Divider(color: Colors.grey[800], height: 1),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return ListTile(
                              leading: const Icon(Icons.clear, color: Colors.white),
                              title: const Text('Все продавцы', style: TextStyle(color: Colors.white)),
                              onTap: () => Navigator.of(context).pop(<String, dynamic>{}),
                            );
                          }
                          final seller = filtered[index - 1];
                          return ListTile(
                            leading: const Icon(Icons.store, color: Colors.white),
                            title: Text(
                              seller['name']?.toString() ?? 'Seller',
                              style: const TextStyle(color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: seller['email'] != null
                                ? Text(
                                    seller['email'].toString(),
                                    style: TextStyle(color: Colors.grey[500]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(seller),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (selected == null) return;

    final id = selected['id']?.toString();
    if (id == null || id.isEmpty) {
      // cleared
      setState(() {
        _selectedSellerId = null;
        _selectedSellerName = null;
      });
      await _performSearch();
      return;
    }

    setState(() {
      _selectedSellerId = id;
      _selectedSellerName = selected['name']?.toString();
    });
    await _performSearch();
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _focusNode.unfocus();
    _performSearch();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _performSearch();
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'apps': return Icons.apps;
      case 'apple': return Icons.apple;
      case 'eco': return Icons.eco;
      case 'restaurant': return Icons.restaurant;
      case 'egg': return Icons.egg;
      case 'bakery_dining': return Icons.bakery_dining;
      case 'local_drink': return Icons.local_drink;
      case 'spa': return Icons.spa;
      case 'checkroom': return Icons.checkroom;
      case 'devices': return Icons.devices;
      case 'home': return Icons.home;
      default: return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text('search'.tr, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            tooltip: 'Продавец',
            onPressed: _pickSeller,
            icon: const Icon(Icons.store, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  style: const TextStyle(color: Colors.white),
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => _performSearch(),
                  decoration: InputDecoration(
                    hintText: 'search_products'.tr,
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[400]),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _suggestions = [];
                                _searchResults = [];
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),

                if (_selectedSellerId != null && _selectedSellerId!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          backgroundColor: Colors.grey[850],
                          label: Text(
                            'Продавец: ${_selectedSellerName ?? _selectedSellerId}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          deleteIcon: const Icon(Icons.close, color: Colors.white, size: 18),
                          onDeleted: () async {
                            setState(() {
                              _selectedSellerId = null;
                              _selectedSellerName = null;
                            });
                            await _performSearch();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Suggestions dropdown
                if (_showSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _suggestions.map((suggestion) {
                        return ListTile(
                          leading: Icon(Icons.search, color: Colors.grey[500], size: 20),
                          title: Text(
                            suggestion,
                            style: const TextStyle(color: Colors.white),
                          ),
                          dense: true,
                          onTap: () => _selectSuggestion(suggestion),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // Category chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['value'];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(category['icon']!),
                          size: 16,
                          color: isSelected ? Colors.white : Colors.grey[400],
                        ),
                        const SizedBox(width: 6),
                        Text(category['label']!.tr),
                      ],
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[300],
                      fontSize: 13,
                    ),
                    backgroundColor: Colors.grey[850],
                    selectedColor: primaryColor,
                    checkmarkColor: Colors.white,
                    showCheckmark: false,
                    onSelected: (_) => _selectCategory(category['value']!),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 64, color: Colors.grey[700]),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'enter_search_query'.tr
                                  : 'no_results'.tr,
                              style: TextStyle(color: Colors.grey[500], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final product = _searchResults[index];
                          return _buildProductCard(product);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final quantity = product['quantity'] ?? 0;
    final inStock = quantity > 0;
    
    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailScreen(product: product)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: AppNetworkImage(
                      url: product['image_url']?.toString(),
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: Colors.grey[800],
                        child: Icon(Icons.image, color: Colors.grey[600], size: 40),
                      ),
                    ),
                  ),
                  if (!inStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'out_of_stock'.tr,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Category badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getCategoryLabel(product['category']),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatPrice(product['price'])} сум',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.store, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product['seller_name'] ?? 'seller'.tr,
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    final n = asDouble(price);
    return n.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}
