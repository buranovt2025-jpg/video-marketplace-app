import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchesService {
  static const _key = 'recent_search_queries';
  static const _maxItems = 10;

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? <String>[];
  }

  static Future<void> save(List<String> queries) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = queries
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toList();
    final unique = <String>[];
    for (final q in trimmed) {
      if (!unique.contains(q)) unique.add(q);
    }
    await prefs.setStringList(_key, unique.take(_maxItems).toList());
  }

  static Future<List<String>> addQuery(String query) async {
    final q = query.trim();
    if (q.isEmpty) return load();

    final current = await load();
    final next = <String>[q, ...current.where((x) => x != q)];
    await save(next);
    return next.take(_maxItems).toList();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

