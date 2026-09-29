import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/core/config/demo_config.dart';
import 'package:ochanya_gili/features/collections/domain/models/collection_item.dart';

class CollectionsRepository {
  final SupabaseClient _client;

  CollectionsRepository(this._client);

  // DEMO-SEED START: 3 pitch collections. Delete or set DemoConfig.enabled=false.
  static final List<CollectionItem> _defaultCollections = [
    const CollectionItem(
      id: 'coll-autumn-2026',
      name: 'Autumn / Winter 2026 — The Royal Peplum',
      slug: 'autumn-winter-2026',
      description:
          'A celebration of ceremonial court majesty. Sculptural peplums, hand-woven silks, and architectural silhouettes tailored in the Maitama atelier.',
      coverImageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=1200&auto=format&fit=crop',
      heroImageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?q=80&w=1920&auto=format&fit=crop',
      season: 'Autumn / Winter',
      year: 2026,
      isFeatured: true,
      isPublished: true,
      productCount: 14,
    ),
    const CollectionItem(
      id: 'coll-resort-2026',
      name: 'Resort 2026 — Sovereign Linen & Silk',
      slug: 'resort-2026',
      description:
          'Effortless lightweight silhouettes designed for warm-climate soirees and coastal getaways. Fluid drapes and breathable luxury fibers.',
      coverImageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=1200&auto=format&fit=crop',
      heroImageUrl: 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?q=80&w=1920&auto=format&fit=crop',
      season: 'Resort',
      year: 2026,
      isFeatured: false,
      isPublished: true,
      productCount: 8,
    ),
    const CollectionItem(
      id: 'coll-bridal-couture',
      name: 'Atelier Bridal & Ceremonial',
      slug: 'bridal-couture',
      description:
          'Bespoke bridal masterpieces created through personal consultation. Hand-beaded lace, traditional embroidery, and timeless royalty.',
      coverImageUrl: 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?q=80&w=1200&auto=format&fit=crop',
      heroImageUrl: 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?q=80&w=1920&auto=format&fit=crop',
      season: 'Perennial',
      year: 2026,
      isFeatured: false,
      isPublished: true,
      productCount: 10,
    ),
  ];

  Future<List<CollectionItem>> getPublishedCollections() async {
    try {
      final res = await _client
          .from('collections')
          .select()
          .eq('is_published', true)
          .eq('is_archived', false)
          .order('sort_order', ascending: true);

      final list = (res as List<dynamic>).map((e) => CollectionItem.fromJson(e as Map<String, dynamic>)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}

    // DEMO-SEED: pitch fallback only when demo enabled.
    if (!DemoConfig.enabled) return [];
    return _defaultCollections;
  }

  Future<List<CollectionItem>> getAllCollectionsAdmin() async {
    try {
      final res = await _client.from('collections').select().order('created_at', ascending: false);

      final list = (res as List<dynamic>).map((e) => CollectionItem.fromJson(e as Map<String, dynamic>)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}

    // DEMO-SEED: admin fallback shares pitch list.
    if (!DemoConfig.enabled) return [];
    return _defaultCollections;
  }

  Future<CollectionItem?> getCollectionBySlug(String slug) async {
    try {
      final res = await _client.from('collections').select().eq('slug', slug).maybeSingle();

      if (res != null) {
        return CollectionItem.fromJson(res);
      }
    } catch (_) {}

    final collections = await getPublishedCollections();
    return collections.firstWhere(
      (c) => c.slug == slug,
      orElse: () => collections.first,
    );
  }

  Future<CollectionItem> createCollection(CollectionItem item) async {
    final payload = item.toJson();
    payload.remove('id'); // let Postgres generate uuid
    final res = await _client.from('collections').insert(payload).select().single();
    return CollectionItem.fromJson(res);
  }

  Future<void> updateCollection(CollectionItem item) async {
    await _client.from('collections').update(item.toJson()).eq('id', item.id);
  }

  Future<void> toggleFeatured(String id, bool isFeatured) async {
    await _client.from('collections').update({'is_featured': isFeatured}).eq('id', id);
  }

  Future<void> archiveCollection(String id, bool isArchived) async {
    await _client.from('collections').update({'is_archived': isArchived}).eq('id', id);
  }
}

final collectionsRepositoryProvider = Provider<CollectionsRepository>((ref) {
  return CollectionsRepository(Supabase.instance.client);
});

final publishedCollectionsProvider = FutureProvider<List<CollectionItem>>((ref) {
  return ref.watch(collectionsRepositoryProvider).getPublishedCollections();
});

final adminCollectionsProvider = FutureProvider<List<CollectionItem>>((ref) {
  return ref.watch(collectionsRepositoryProvider).getAllCollectionsAdmin();
});

final featuredCollectionProvider = FutureProvider<CollectionItem?>((ref) async {
  final collections = await ref.watch(publishedCollectionsProvider.future);
  return collections.firstWhere(
    (c) => c.isFeatured,
    orElse: () => collections.isNotEmpty ? collections.first : CollectionsRepository._defaultCollections.first,
  );
});
