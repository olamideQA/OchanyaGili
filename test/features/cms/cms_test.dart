import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/features/cms/domain/models/cms_content.dart';
import 'package:ochanya_gili/features/journal/domain/models/journal_post.dart';

void main() {
  group('Loop 1: CMS & Editorial Content Models Tests', () {
    test('HeroSlide fromJson and toJson round-trip', () {
      const slide = HeroSlide(
        id: 'slide-101',
        title: 'AUTUMN 2026 CAMPAIGN',
        subtitle: 'The Anatomy of Haute Couture',
        ctaText: 'EXPLORE LOOKS',
        ctaLink: '/collections/autumn-2026',
        desktopImageUrl: 'https://cdn.ochanya.com/desktop.jpg',
        mobileImageUrl: 'https://cdn.ochanya.com/mobile.jpg',
        sortOrder: 1,
      );

      final json = slide.toJson();
      final parsed = HeroSlide.fromJson(json);

      expect(parsed, equals(slide));
      expect(parsed.title, 'AUTUMN 2026 CAMPAIGN');
      expect(parsed.ctaLink, '/collections/autumn-2026');
      expect(parsed.desktopImageUrl, 'https://cdn.ochanya.com/desktop.jpg');
      expect(parsed.mobileImageUrl, 'https://cdn.ochanya.com/mobile.jpg');
    });

    test('EditorialBlock fromJson and fallback defaults', () {
      final block = EditorialBlock.fromJson({
        'headline': 'THE RESORT COLLECTION',
        'subheadline': 'HAUTE COUTURE',
        'body': 'Artisanal hand-woven silk garments tailored to royal precision.',
        'image_url': 'https://cdn.ochanya.com/campaign.jpg',
        'cta_text': 'DISCOVER',
        'cta_link': '/collections',
      });

      expect(block.headline, 'THE RESORT COLLECTION');
      expect(block.subheadline, 'HAUTE COUTURE');
      expect(block.ctaText, 'DISCOVER');

      final emptyBlock = EditorialBlock.fromJson({});
      expect(emptyBlock.headline, isNotEmpty);
      expect(emptyBlock.body, isNotEmpty);
    });

    test('AboutContent and ContactDetails defaults', () {
      final about = AboutContent.fromJson({});
      expect(about.title, isNotEmpty);
      expect(about.philosophy, contains('Ochanya Gili'));
      expect(about.studioAddress, contains('Maitama'));

      final contact = ContactDetails.fromJson({});
      expect(contact.conciergeEmail, contains('@ochanyagili.com'));
      expect(contact.address, contains('Maitama'));
    });

    test('JournalPost model parsing and tags list', () {
      final post = JournalPost.fromJson({
        'id': 'jp-1',
        'title': 'The Architecture of Modern Peplums',
        'slug': 'architecture-of-peplums',
        'excerpt': 'A study in West African tailoring.',
        'content': 'Extended essay content here...',
        'cover_image_url': 'https://cdn.ochanya.com/post.jpg',
        'is_published': true,
        'published_at': '2026-09-28T12:00:00Z',
        'tags': ['Couture', 'Runway'],
      });

      expect(post.slug, 'architecture-of-peplums');
      expect(post.tags.length, 2);
      expect(post.tags.first, 'Couture');
      expect(post.isPublished, isTrue);
    });
  });
}
