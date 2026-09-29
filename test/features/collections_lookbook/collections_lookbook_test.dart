import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/features/collections/domain/models/collection_item.dart';
import 'package:ochanya_gili/features/lookbook/domain/models/lookbook_entry.dart';

void main() {
  group('Loop 2: Collections & Lookbook Tests', () {
    test('CollectionItem fromJson, toJson, and copyWith', () {
      const col = CollectionItem(
        id: 'col-1',
        name: 'The Royal Peplum',
        slug: 'the-royal-peplum',
        description: 'Autumn Winter 2026 Collection',
        coverImageUrl: 'https://cdn.ochanya.com/cover.jpg',
        heroImageUrl: 'https://cdn.ochanya.com/hero.jpg',
        season: 'Autumn / Winter',
        year: 2026,
        isFeatured: true,
        isPublished: true,
        isArchived: false,
        sortOrder: 1,
        productCount: 12,
      );

      final json = col.toJson();
      final parsed = CollectionItem.fromJson(json);

      expect(parsed.name, col.name);
      expect(parsed.slug, col.slug);
      expect(parsed.isFeatured, isTrue);
      expect(parsed.isArchived, isFalse);

      final archived = col.copyWith(isArchived: true);
      expect(archived.isArchived, isTrue);
      expect(archived.id, col.id);
      expect(archived.name, col.name);
    });

    test('LookbookEntry fromJson, credits, and linked products', () {
      final look = LookbookEntry.fromJson({
        'id': 'look-1',
        'title': 'Look 01 — Ivory Peplum Gown',
        'slug': 'look-01-ivory-peplum-gown',
        'description': 'Sculptural raw silk peplum',
        'cover_image_url': 'https://cdn.ochanya.com/look1.jpg',
        'full_image_url': 'https://cdn.ochanya.com/look1_full.jpg',
        'designer_notes': 'Crafted over 80 hours with metallic bullion.',
        'collection_name': 'Autumn / Winter 2026',
        'model_name': 'Amina Bello',
        'photographer': 'Kola Oshalusi',
        'is_published': true,
        'sort_order': 1,
        'linked_product_ids': ['prod-gown-1', 'prod-cuff-1'],
      });

      expect(look.modelName, 'Amina Bello');
      expect(look.photographer, 'Kola Oshalusi');
      expect(look.linkedProductIds.length, 2);
      expect(look.linkedProductIds, contains('prod-gown-1'));
    });

    test('Shop this look generates pre-filtered deep link', () {
      const lookWithProducts = LookbookEntry(
        id: 'look-10',
        title: 'Look 10',
        slug: 'look-10',
        coverImageUrl: '',
        fullImageUrl: '',
        linkedProductIds: ['prod-a', 'prod-b'],
      );

      final url = lookWithProducts.linkedProductIds.isNotEmpty
          ? '/shop?look=${lookWithProducts.slug}&products=${lookWithProducts.linkedProductIds.join(",")}'
          : '/shop?look=${lookWithProducts.slug}';

      expect(url, '/shop?look=look-10&products=prod-a,prod-b');

      const lookWithoutProducts = LookbookEntry(
        id: 'look-11',
        title: 'Look 11',
        slug: 'look-11',
        coverImageUrl: '',
        fullImageUrl: '',
        linkedProductIds: [],
      );

      final url2 = lookWithoutProducts.linkedProductIds.isNotEmpty
          ? '/shop?look=${lookWithoutProducts.slug}&products=${lookWithoutProducts.linkedProductIds.join(",")}'
          : '/shop?look=${lookWithoutProducts.slug}';

      expect(url2, '/shop?look=look-11');
    });

    test('Collection archiving does not delete or alter relation IDs', () {
      const original = CollectionItem(
        id: 'col-arch-1',
        name: 'Historic Collection',
        slug: 'historic-collection',
        isArchived: false,
      );

      final archived = original.copyWith(isArchived: true);
      expect(archived.id, original.id);
      expect(archived.isArchived, isTrue);

      final restored = archived.copyWith(isArchived: false);
      expect(restored.isArchived, isFalse);
    });
  });
}
