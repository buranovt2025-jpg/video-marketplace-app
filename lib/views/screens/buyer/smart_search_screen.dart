import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/controllers/marketplace_controller.dart';
import 'package:tiktok_tutorial/services/recent_searches_service.dart';
import 'package:tiktok_tutorial/utils/product_search.dart';
import 'package:tiktok_tutorial/views/screens/buyer/product_detail_screen.dart';

class SmartSearchScreen extends StatefulWidget {
  const SmartSearchScreen({super.key});

  @override
  State<SmartSearchScreen> createState() => _SmartSearchScreenState();
}

class _SmartSearchScreenState extends State<SmartSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final MarketplaceController _controller = Get.find<MarketplaceController>();
  final FocusNode _focusNode = FocusNode();
  
  String _selectedCategory = 'all';
  ProductSort _sort = ProductSort.relevance;
  double? _minPrice;
  double? _maxPrice;
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _suggestions = [];
  List<String> _recentQueries = [];
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
    _loadRecentQueries();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
      });
    });
  }

  Future<void> _loadRecentQueries() async {
    final recent = await RecentSearchesService.load();
    if (!mounted) return;
    setState(() {
      _recentQueries = recent;
      if (_searchController.text.isEmpty) {
        _suggestions = recent;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _suggestions = _recentQueries;
        _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
      });
      return;
    }

    // Generate suggestions from products
    final products = _controller.products;
    final Set<String> suggestionSet = {};
    
    for (var product in products) {
      final name = product['name']?.toString().toLowerCase() ?? '';
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

  Future<void> _rememberQuery(String query) async {
    if (query.trim().isEmpty) return;
    final next = await RecentSearchesService.addQuery(query);
    if (!mounted) return;
    setState(() {
      _recentQueries = next;
    });
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    setState(() {
      _isSearching = true;
      _showSuggestions = false;
    });

    final results = filterAndSortProducts(
      products: _controller.products,
      query: query,
      selectedCategory: _selectedCategory,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      sort: _sort,
    );

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });

    // Fire-and-forget persistence
    _rememberQuery(query);
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

  void _openFilters() {
    _minPriceController.text = _minPrice?.toStringAsFixed(0) ?? '';
    _maxPriceController.text = _maxPrice?.toStringAsFixed(0) ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'filters'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await RecentSearchesService.clear();
                      if (!mounted) return;
                      setState(() {
                        _recentQueries = [];
                        if (_searchController.text.isEmpty) {
                          _suggestions = [];
                          _showSuggestions = false;
                        }
                      });
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: Text('clear_history'.tr),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text('sort_by'.tr, style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 8),
              DropdownButtonFormField<ProductSort>(
                initialValue: _sort,
                dropdownColor: Colors.grey[900],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: ProductSort.relevance,
                    child: Text('sort_by'.tr, style: const TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: ProductSort.priceLowToHigh,
                    child: Text('price_low_to_high'.tr, style: const TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: ProductSort.priceHighToLow,
                    child: Text('price_high_to_low'.tr, style: const TextStyle(color: Colors.white)),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _sort = v);
                },
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'price_from'.tr,
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[850],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'price_to'.tr,
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[850],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _minPrice = null;
                          _maxPrice = null;
                          _sort = ProductSort.relevance;
                        });
                        Navigator.of(context).pop();
                        _performSearch();
                      },
                      child: Text('reset_filters'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      onPressed: () {
                        setState(() {
                          _minPrice = tryParsePrice(_minPriceController.text);
                          _maxPrice = tryParsePrice(_maxPriceController.text);
                        });
                        Navigator.of(context).pop();
                        _performSearch();
                      },
                      child: Text('apply_filters'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
                                _suggestions = _recentQueries;
                                _searchResults = [];
                                _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
                              });
                            },
                          )
                        : IconButton(
                            icon: Icon(Icons.tune, color: Colors.grey[400]),
                            onPressed: _openFilters,
                          ),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                
                // Suggestions dropdown
                if (_showSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _suggestions.map((suggestion) {
                        return ListTile(
                          leading: Icon(
                            _recentQueries.contains(suggestion) ? Icons.history : Icons.search,
                            color: Colors.grey[500],
                            size: 20,
                          ),
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
                    child: product['image_url'] != null
                        ? Image.network(
                            product['image_url'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[800],
                              child: Icon(Icons.image, color: Colors.grey[600], size: 40),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: Icon(Icons.image, color: Colors.grey[600], size: 40),
                          ),
                  ),
                  if (!inStock)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                        color: primaryColor.withValues(alpha: 0.9),
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
                      style: const TextStyle(
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
    if (price == null) return '0';
    final numPrice = price is num ? price : double.tryParse(price.toString()) ?? 0;
    return numPrice.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}
