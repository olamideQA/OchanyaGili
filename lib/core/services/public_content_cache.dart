import 'package:flutter_riverpod/flutter_riverpod.dart';

class CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  CacheEntry({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class PublicContentCacheService {
  final Map<String, CacheEntry<dynamic>> _cache = {};
  final Duration defaultTtl;

  int _cacheHits = 0;
  int _cacheMisses = 0;

  PublicContentCacheService({this.defaultTtl = const Duration(minutes: 5)});

  int get cacheHits => _cacheHits;
  int get cacheMisses => _cacheMisses;
  int get totalRequests => _cacheHits + _cacheMisses;
  double get hitRate => totalRequests == 0 ? 0.0 : (_cacheHits / totalRequests) * 100;

  Future<T> getOrFetch<T>({
    required String key,
    required Future<T> Function() fetcher,
    Duration? ttl,
  }) async {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired && entry.data is T) {
      _cacheHits++;
      return entry.data as T;
    }

    _cacheMisses++;
    final freshData = await fetcher();
    _cache[key] = CacheEntry<T>(
      data: freshData,
      expiresAt: DateTime.now().add(ttl ?? defaultTtl),
    );
    return freshData;
  }

  void invalidate(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
  }
}

final publicContentCacheProvider = Provider<PublicContentCacheService>((ref) {
  return PublicContentCacheService();
});
