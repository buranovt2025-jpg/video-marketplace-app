import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_tutorial/utils/product_search.dart';

void main() {
  final products = <Map<String, dynamic>>[
    {
      'id': '1',
      'name': 'Apple',
      'description': 'Fresh red apple',
      'category': 'fruits',
      'seller_name': 'Market A',
      'price': 1000,
    },
    {
      'id': '2',
      'name': 'Banana',
      'description': 'Yellow banana',
      'category': 'fruits',
      'seller_name': 'Market B',
      'price': '2 500',
    },
    {
      'id': '3',
      'name': 'TV',
      'description': 'Smart TV 55',
      'category': 'electronics',
      'seller_name': 'Electro',
      'price': 2000000,
    },
  ];

  test('tryParsePrice parses numbers and formatted strings', () {
    expect(tryParsePrice(10), 10.0);
    expect(tryParsePrice('12 000'), 12000.0);
    expect(tryParsePrice('12,000'), 12000.0);
    expect(tryParsePrice(null), isNull);
    expect(tryParsePrice(''), isNull);
  });

  test('filterAndSortProducts filters by query and category', () {
    final r1 = filterAndSortProducts(
      products: products,
      query: 'app',
      selectedCategory: 'all',
    );
    expect(r1.map((p) => p['id']).toList(), ['1']);

    final r2 = filterAndSortProducts(
      products: products,
      query: '',
      selectedCategory: 'fruits',
    );
    expect(r2.map((p) => p['id']).toSet(), {'1', '2'});
  });

  test('filterAndSortProducts filters by price range', () {
    final r = filterAndSortProducts(
      products: products,
      query: '',
      selectedCategory: 'all',
      minPrice: 1100,
      maxPrice: 3000,
    );
    expect(r.map((p) => p['id']).toList(), ['2']);
  });

  test('filterAndSortProducts sorts by price', () {
    final lowToHigh = filterAndSortProducts(
      products: products,
      query: '',
      selectedCategory: 'all',
      sort: ProductSort.priceLowToHigh,
    );
    expect(lowToHigh.map((p) => p['id']).toList(), ['1', '2', '3']);

    final highToLow = filterAndSortProducts(
      products: products,
      query: '',
      selectedCategory: 'all',
      sort: ProductSort.priceHighToLow,
    );
    expect(highToLow.map((p) => p['id']).toList(), ['3', '2', '1']);
  });
}

