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
      title: 'Look 01 — The Althea Cathedral Bridal Gown',
      slug: 'look-01-althea-cathedral-bridal-gown',
      description: 'Hand-beaded French chantilly lace gown with boned illusion corset and a 2.5-meter cathedral train.',
      coverImageUrl: 'https://images.unsplash.com/photo-1594552072238-b8a33785b261?q=80&w=800&h=1000&auto=format&fit=crop',
      fullImageUrl: 'https://images.unsplash.com/photo-1594552072238-b8a33785b261?q=80&w=1080&h=1440&auto=format&fit=crop',
      designerNotes:
          '“Each micro-pearl and crystal bead is hand-sewn over 180 hours in our Lagos atelier to achieve an ethereal illusion of floating lace on melanin skin.”',
      collectionName: 'The Royal Bridal Atelier',
      modelName: 'Ngozi Onwuka',
      photographer: 'Kola Oshalusi',
      isPublished: true,
      sortOrder: 1,
      linkedProductIds: ['prod-bridal-althea-gown'],
    ),
    const LookbookEntry(
      id: 'look-2',
      title: 'Look 02 — The Seraphina Silk Mikado Bridal Gown',
      slug: 'look-02-seraphina-silk-mikado-bridal-gown',
      description: 'Architectural off-shoulder mermaid wedding gown sculpted in heavyweight Italian silk mikado.',
      coverImageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?q=80&w=800&h=1000&auto=format&fit=crop',
      fullImageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?q=80&w=1080&h=1440&auto=format&fit=crop',
      designerNotes:
          '“Clean, unapologetic architectural majesty for the modern bride commanding quiet luxury.”',
      collectionName: 'The Royal Bridal Atelier',
      modelName: 'Amina Bello',
      photographer: 'Seyi Adebayo',
      isPublished: true,
      sortOrder: 2,
      linkedProductIds: ['prod-bridal-seraphina-gown'],
    ),
    const LookbookEntry(
      id: 'look-3',
      title: 'Look 03 — The Amina Corseted Reception Gown',
      slug: 'look-03-amina-corseted-reception-gown',
      description: 'Emerald French lace with hand-sewn bugle beads, boned internal corset, and godet train.',
      coverImageUrl: 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?q=80&w=800&h=1000&auto=format&fit=crop',
      fullImageUrl: 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?q=80&w=1080&h=1440&auto=format&fit=crop',
      designerNotes:
          '“Engineered with our signature cinching corset structure to give the bride effortless movement for a 12-hour Nigerian wedding reception.”',
      collectionName: 'Owambe Éclat',
      modelName: 'Faith Johnson',
      photographer: 'Kola Oshalusi',
      isPublished: true,
      sortOrder: 3,
      linkedProductIds: ['prod-mto-amina-reception', 'prod-acc-gold-cuff-1'],
    ),
    const LookbookEntry(
      id: 'look-4',
      title: 'Look 04 — The Alaari Handwoven Aso-Oke Suit',
      slug: 'look-04-alaari-handwoven-aso-oke-suit',
      description: 'Crimson & metallic gold handwoven Aso-Oke cropped blazer with high-waist cigarette trousers.',
      coverImageUrl: 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?q=80&w=800&h=1000&auto=format&fit=crop',
      fullImageUrl: 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?q=80&w=1080&h=1440&auto=format&fit=crop',
      designerNotes:
          '“Woven on traditional vertical looms in southwestern Nigeria using heritage cotton and metallic lurex threads.”',
      collectionName: 'Heritage Weavers',
      modelName: 'Zainab Idris',
      photographer: 'Seyi Adebayo',
      isPublished: true,
      sortOrder: 4,
      linkedProductIds: ['prod-rtw-alaari-suit'],
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
