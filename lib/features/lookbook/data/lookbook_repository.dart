import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/core/config/demo_config.dart';
import 'package:ochanya_gili/features/lookbook/domain/models/lookbook_entry.dart';

class LookbookRepository {
  final SupabaseClient _client;

  LookbookRepository(this._client);

  // DEMO-SEED START: 3 pitch looks. Delete or set DemoConfig.enabled=false.
  static final List<LookbookEntry> _defaultLookbooks = [
    const LookbookEntry(
      id: 'look-1',
      title: 'Look 01 — The Sovereign Peplum Gown',
      slug: 'look-01-sovereign-peplum-gown',
      description: 'An architectural silhouette cut from structured wool crepe with cascading organza lining.',
      coverImageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?q=80&w=800&h=1000&auto=format&fit=crop',
      fullImageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?q=80&w=1080&h=1440&auto=format&fit=crop',
      designerNotes:
          '“We drafted the waistline to sit precisely 1.5cm higher than classical tailoring, creating a commanding stateliness that honors Benue royalty.”',
      collectionName: 'Autumn / Winter 2026',
      modelName: 'Amina Bello',
      photographer: 'Kola Oshalusi',
      isPublished: true,
      sortOrder: 1,
      linkedProductIds: ['prod-peplum-gown-1', 'prod-gold-cuff-1'],
    ),
    const LookbookEntry(
      id: 'look-2',
      title: 'Look 02 — The Sculpted Kaftan with Filigree',
      slug: 'look-02-sculpted-kaftan-filigree',
      description: 'Fluid heavyweight silk twill embroidered with hand-twisted metallic bullion thread.',
      coverImageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=800&h=1000&auto=format&fit=crop',
      fullImageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=1080&h=1440&auto=format&fit=crop',
      designerNotes:
          '“The bullion thread was sourced directly from Kano artisans and applied by our senior embroiderer over 72 hours.”',
      collectionName: 'Autumn / Winter 2026',
      modelName: 'Faith Johnson',
      photographer: 'Kola Oshalusi',
      isPublished: true,
      sortOrder: 2,
      linkedProductIds: ['prod-sculpted-kaftan-1'],
    ),
    const LookbookEntry(
      id: 'look-3',
      title: 'Look 03 — Modern Ceremonial Two-Piece',
      slug: 'look-03-modern-ceremonial-two-piece',
      description: 'Cropped structural blazer with signature sharp shoulders and wide-leg silk trousers.',
      coverImageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=800&h=1000&auto=format&fit=crop',
      fullImageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=1080&h=1440&auto=format&fit=crop',
      designerNotes:
          '“Clean, unapologetic tailoring for the woman stepping into rooms of global consequence.”',
      collectionName: 'Autumn / Winter 2026',
      modelName: 'Zainab Idris',
      photographer: 'Seyi Adebayo',
      isPublished: true,
      sortOrder: 3,
      linkedProductIds: ['prod-blazer-1', 'prod-trousers-1'],
    ),
  ];

  Future<List<LookbookEntry>> getPublishedLookbooks() async {
    try {
      final res = await _client
          .from('lookbook')
          .select('*, lookbook_items(product_id)')
          .eq('is_published', true)
          .order('sort_order', ascending: true);

      final list = (res as List<dynamic>).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        if (map['lookbook_items'] is List) {
          map['linked_product_ids'] =
              (map['lookbook_items'] as List).map((i) => i['product_id'].toString()).toList();
        }
        return LookbookEntry.fromJson(map);
      }).toList();

      if (list.isNotEmpty) return list;
    } catch (_) {}

    // DEMO-SEED: pitch fallback only when demo enabled.
    if (!DemoConfig.enabled) return [];
    return _defaultLookbooks;
  }

  Future<List<LookbookEntry>> getAllLookbooksAdmin() async {
    try {
      final res = await _client.from('lookbook').select().order('created_at', ascending: false);

      final list = (res as List<dynamic>).map((e) => LookbookEntry.fromJson(e as Map<String, dynamic>)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}

    // DEMO-SEED: admin fallback shares pitch list.
    if (!DemoConfig.enabled) return [];
    return _defaultLookbooks;
  }

  Future<LookbookEntry?> getLookbookBySlug(String slug) async {
    try {
      final res = await _client.from('lookbook').select().eq('slug', slug).maybeSingle();

      if (res != null) {
        return LookbookEntry.fromJson(res);
      }
    } catch (_) {}

    final list = await getPublishedLookbooks();
    return list.firstWhere((l) => l.slug == slug, orElse: () => list.first);
  }

  Future<LookbookEntry> createLookbook(LookbookEntry entry) async {
    final payload = entry.toJson();
    payload.remove('id');
    final res = await _client.from('lookbook').insert(payload).select().single();
    return LookbookEntry.fromJson(res);
  }

  Future<void> updateLookbook(LookbookEntry entry) async {
    await _client.from('lookbook').update(entry.toJson()).eq('id', entry.id);
  }

  Future<void> deleteLookbook(String id) async {
    await _client.from('lookbook').delete().eq('id', id);
  }
}

final lookbookRepositoryProvider = Provider<LookbookRepository>((ref) {
  return LookbookRepository(Supabase.instance.client);
});

final publishedLookbooksProvider = FutureProvider<List<LookbookEntry>>((ref) {
  return ref.watch(lookbookRepositoryProvider).getPublishedLookbooks();
});

final adminLookbooksProvider = FutureProvider<List<LookbookEntry>>((ref) {
  return ref.watch(lookbookRepositoryProvider).getAllLookbooksAdmin();
});
