enum ProductSort {
  relevance,
  priceLowToHigh,
  priceHighToLow,
}

double? tryParsePrice(dynamic price) {
  if (price == null) return null;
  if (price is num) return price.toDouble();
  final s = price.toString().trim();
  if (s.isEmpty) return null;

  // Allow "12 000", "12,000", "12000.50", etc.
  final normalized = s.replaceAll(RegExp(r'[\s,]'), '');
  return double.tryParse(normalized);
}

bool _matchesQuery(Map<String, dynamic> product, String queryLower) {
  if (queryLower.isEmpty) return true;

  final name = product['name']?.toString().toLowerCase() ?? '';
  final description = product['description']?.toString().toLowerCase() ?? '';
  final category = product['category']?.toString().toLowerCase() ?? '';
  final sellerName = product['seller_name']?.toString().toLowerCase() ?? '';

  return name.contains(queryLower) ||
      description.contains(queryLower) ||
      category.contains(queryLower) ||
      sellerName.contains(queryLower);
}

List<Map<String, dynamic>> filterAndSortProducts({
  required List<Map<String, dynamic>> products,
  required String query,
  required String selectedCategory,
  double? minPrice,
  double? maxPrice,
  ProductSort sort = ProductSort.relevance,
}) {
  final queryLower = query.trim().toLowerCase();

  final filtered = products.where((product) {
    if (selectedCategory != 'all' && product['category'] != selectedCategory) {
      return false;
    }

    if (!_matchesQuery(product, queryLower)) {
      return false;
    }

    final price = tryParsePrice(product['price']) ?? 0.0;
    if (minPrice != null && price < minPrice) return false;
    if (maxPrice != null && price > maxPrice) return false;

    return true;
  }).toList();

  switch (sort) {
    case ProductSort.relevance:
      return filtered;
    case ProductSort.priceLowToHigh:
      filtered.sort((a, b) {
        final ap = tryParsePrice(a['price']) ?? 0.0;
        final bp = tryParsePrice(b['price']) ?? 0.0;
        return ap.compareTo(bp);
      });
      return filtered;
    case ProductSort.priceHighToLow:
      filtered.sort((a, b) {
        final ap = tryParsePrice(a['price']) ?? 0.0;
        final bp = tryParsePrice(b['price']) ?? 0.0;
        return bp.compareTo(ap);
      });
      return filtered;
  }
}

