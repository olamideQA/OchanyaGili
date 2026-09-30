import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/core/config/demo_config.dart';
import 'package:ochanya_gili/features/collections/domain/models/collection_item.dart';

class CollectionsRepository {
  final SupabaseClient _client;

  CollectionsRepository(this._client);

  // DEMO-SEED START: Nigerian Haute Couture & Bridal collections.
  static final List<CollectionItem> _defaultCollections = [
    const CollectionItem(
      id: 'coll-bridal-couture',
      name: 'The Royal Bridal & Ceremonial Atelier',
      slug: 'bridal-couture',
      description:
          'Bespoke white wedding masterpieces, reception corsetry, and royal traditional bridal attire crafted with cathedral trains, hand-beaded French lace, and authentic coral regalia.',
      coverImageUrl: 'https://gfobzdetjbqwrxnutrkj.supabase.co/storage/v1/object/public/products/nigerian_wedding_bride_white.jpg',
      heroImageUrl: 'https://gfobzdetjbqwrxnutrkj.supabase.co/storage/v1/object/public/products/nigerian_couture_veil.jpg',
      season: 'Perennial Bridal',
      year: 2026,
      isFeatured: true,
      isPublished: true,
      productCount: 12,
    ),
    const CollectionItem(
      id: 'coll-owambe-eclat',
      name: 'Owambe Éclat — Haute Soirée & Gala',
      slug: 'owambe-eclat',
      description:
          'Celebration wear engineered for the grandest Lagos soirees, milestone birthdays, and red carpets. Structural corsetry, hand-appliquéd crystals, and sculptural peplums.',
      coverImageUrl: 'https://gfobzdetjbqwrxnutrkj.supabase.co/storage/v1/object/public/products/yoruba_bride_aso_oke.jpg',
      heroImageUrl: 'https://gfobzdetjbqwrxnutrkj.supabase.co/storage/v1/object/public/products/yoruba_bride_traditional.jpg',
      season: 'Autumn / Winter',
      year: 2026,
      isFeatured: true,
      isPublished: true,
      productCount: 16,
    ),
    const CollectionItem(
      id: 'coll-heritage-weavers',
      name: 'Heritage Weavers — Modern Aso-Oke & Silk',
      slug: 'heritage-weavers',
      description:
          'Handwoven Nigerian textiles reimagined into sharp contemporary power tailoring, architectural cropped blazers, and liquid silk co-ord sets.',
      coverImageUrl: 'https://gfobzdetjbqwrxnutrkj.supabase.co/storage/v1/object/public/products/lagos_fashion_week_runway.jpg',
      heroImageUrl: 'https://gfobzdetjbqwrxnutrkj.supabase.co/storage/v1/object/public/products/lagos_couture_model.jpg',
      season: 'Spring / Summer',
      year: 2026,
      isFeatured: false,
      isPublished: true,
      productCount: 10,
    ),
    const CollectionItem(
      id: 'coll-lagos-solstice',
      name: 'Lagos Solstice — Sovereign Resort & Leisure',
      slug: 'lagos-solstice',
      description:
          'Fluid lightweight silhouettes designed for warm-climate soirees, Ilashe beach getaways, and tropical escapes. Hand-dyed Adire and pure mulberry silk.',
      coverImageUrl: 'https://gfobzdetjbqwrxnutrkj.supabase.co/storage/v1/object/public/products/nigerian_gele_headgear.jpg',
      heroImageUrl: 'https://gfobzdetjbqwrxnutrkj.supabase.co/storage/v1/object/public/products/nigerian_models_fashion.jpg',
      season: 'Resort',
      year: 2026,
      isFeatured: false,
      isPublished: true,
      productCount: 8,
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

      final list = (res as List<dynamic>)
          .map((e) => CollectionItem.fromJson(e as Map<String, dynamic>))
          .where((c) => !c.name.toUpperCase().contains('QA ') && !(c.description?.toUpperCase().contains('QA REGRESSION') ?? false))
          .toList();
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
