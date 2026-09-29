import 'package:shared_preferences/shared_preferences.dart';

/// Ozinna-style "Recently viewed" (mirror: recently-viewed-products).
/// Persists last 8 product slugs locally. DEMO-safe: empty until browsed.
class RecentlyViewedStore {
  static const String _key = 'og_recently_viewed_v1';
  static const int _max = 8;

  static Future<void> record(String slug) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key) ?? <String>[];
      list.remove(slug);
      list.insert(0, slug);
      await prefs.setStringList(_key, list.take(_max).toList());
    } catch (_) {}
  }

  static Future<List<String>> read({String? exclude}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key) ?? <String>[];
      if (exclude != null) list.remove(exclude);
      return list;
    } catch (_) {
      return [];
    }
  }
}
