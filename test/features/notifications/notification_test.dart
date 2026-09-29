import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/features/cms/domain/models/cms_content.dart';
import 'package:ochanya_gili/features/media/domain/models/media_asset.dart';
import 'package:ochanya_gili/features/notifications/domain/models/notification_template.dart';

void main() {
  group('Notification Templates & Multi-Channel Interpolation', () {
    test('renders order confirmation template with proper variables', () {
      final template = NotificationTemplateRegistry.getTemplate('order', 'confirmed');
      expect(template, isNotNull);

      final vars = {
        'customerName': 'Amina Bello',
        'orderNumber': 'OG-2026-9901',
      };

      final interpolated = template!.interpolate(vars);

      expect(interpolated.inAppTitle, contains('Commission Authenticated'));
      expect(interpolated.inAppBody, contains('OG-2026-9901'));
      expect(interpolated.emailSubject, contains('OG-2026-9901'));
      expect(interpolated.emailHtml, contains('Amina Bello'));
      expect(interpolated.emailHtml, contains('OG-2026-9901'));
      expect(interpolated.pushBody, contains('OG-2026-9901'));

      // Luxury Email HTML Verification
      expect(interpolated.emailHtml, contains('#C9A96E')); // Atelier Gold Accent
      expect(interpolated.emailHtml, contains('Playfair Display'));
    });

    test('supports all required Order state transitions', () {
      final statuses = [
        'confirmed',
        'processing',
        'in_production',
        'ready_for_fitting',
        'ready_for_delivery',
        'shipped',
        'delivered',
        'cancelled',
      ];

      for (final s in statuses) {
        final t = NotificationTemplateRegistry.getTemplate('order', s);
        expect(t, isNotNull, reason: 'Order template for status "$s" must exist');
        expect(t!.inAppTitle.isNotEmpty, isTrue);
        expect(t.emailSubject.isNotEmpty, isTrue);
        expect(t.pushTitle.isNotEmpty, isTrue);
      }
    });

    test('supports all required Custom Request state transitions', () {
      final statuses = [
        'submitted',
        'under_review',
        'quote_sent',
        'customer_approved',
        'in_production',
        'ready_for_fitting',
        'completed',
      ];

      for (final s in statuses) {
        final t = NotificationTemplateRegistry.getTemplate('custom_request', s);
        expect(t, isNotNull, reason: 'Custom Request template for status "$s" must exist');
        expect(t!.inAppTitle.isNotEmpty, isTrue);
        expect(t.emailSubject.isNotEmpty, isTrue);
        expect(t.pushTitle.isNotEmpty, isTrue);
      }
    });

    test('supports all required Appointment state transitions', () {
      final statuses = [
        'confirmed',
        'completed',
        'cancelled',
      ];

      for (final s in statuses) {
        final t = NotificationTemplateRegistry.getTemplate('appointment', s);
        expect(t, isNotNull, reason: 'Appointment template for status "$s" must exist');
        expect(t!.inAppTitle.isNotEmpty, isTrue);
        expect(t.emailSubject.isNotEmpty, isTrue);
        expect(t.pushTitle.isNotEmpty, isTrue);
      }
    });

    test('replaces variables cleanly with empty string on missing values', () {
      const template = NotificationTemplate(
        id: 'test_tpl',
        eventType: 'order',
        status: 'confirmed',
        inAppTitle: 'Hello {customerName}',
        inAppBody: 'Your item {item} is {missingVar}.',
        emailSubject: 'Update for {customerName}',
        emailHtml: '<html>{customerName}</html>',
        pushTitle: 'Push {customerName}',
        pushBody: 'Body {item}',
        actionUrl: '/orders/{orderNumber}',
      );

      final interpolated = template.interpolate({'customerName': 'Ochanya', 'item': 'Silk Corset'});
      expect(interpolated.inAppTitle, equals('Hello Ochanya'));
      expect(interpolated.inAppBody, equals('Your item Silk Corset is {missingVar}.'));
    });
  });

  group('CMS Domain Models & Persistence Serialization', () {
    test('HeroSlide serialization and deserialization', () {
      const slide = HeroSlide(
        id: 'slide-101',
        title: 'AUTUMN SPLENDOR',
        subtitle: 'Bespoke Haute Couture',
        ctaText: 'DISCOVER NOW',
        ctaLink: '/collections/autumn',
        desktopImageUrl: 'https://cdn.ochanyagili.com/hero-desktop.jpg',
        mobileImageUrl: 'https://cdn.ochanyagili.com/hero-mobile.jpg',
        sortOrder: 1,
      );

      final json = slide.toJson();
      final fromJson = HeroSlide.fromJson(json);

      expect(fromJson, equals(slide));
      expect(fromJson.title, equals('AUTUMN SPLENDOR'));
      expect(fromJson.ctaLink, equals('/collections/autumn'));
    });

    test('EditorialBlock serialization and defaults', () {
      const block = EditorialBlock(
        headline: 'THE MAITAMA ATELIER',
        subheadline: 'SAVOIR-FAIRE',
        body: 'Every stitch reflects ancestral Benue craftsmanship.',
        imageUrl: 'https://cdn.ochanyagili.com/editorial.jpg',
        ctaText: 'READ THE SARTORIAL ESSAY',
        ctaLink: '/journal/savoir-faire',
      );

      final json = block.toJson();
      final fromJson = EditorialBlock.fromJson(json);

      expect(fromJson, equals(block));
      expect(fromJson.headline, equals('THE MAITAMA ATELIER'));
    });

    test('AboutContent serialization and fallbacks', () {
      const about = AboutContent(
        title: 'OCHANYA GILI MAISON',
        philosophy: 'Intimate architecture of clothing.',
        craftsmanship: 'Hand-sewn pleats and sculpted bodices.',
        designerBio: 'Founded in 2026 by Ochanya Gili.',
        studioAddress: 'Plot 104, Maitama, Abuja',
        heroImageUrl: 'https://cdn.ochanyagili.com/about-hero.jpg',
      );

      final json = about.toJson();
      final fromJson = AboutContent.fromJson(json);

      expect(fromJson, equals(about));
      expect(fromJson.title, equals('OCHANYA GILI MAISON'));
    });

    test('ContactDetails serialization and validation', () {
      const contact = ContactDetails(
        conciergeEmail: 'salon@ochanyagili.com',
        studioPhone: '+234 808 123 4567',
        address: '104 Maitama Crescent, Abuja, Nigeria',
        openingHours: 'Mon-Fri 10am-6pm (Appointment Only)',
        instagram: '@ochanyagili_couture',
      );

      final json = contact.toJson();
      final fromJson = ContactDetails.fromJson(json);

      expect(fromJson, equals(contact));
      expect(fromJson.conciergeEmail, equals('salon@ochanyagili.com'));
      expect(fromJson.instagram, equals('@ochanyagili_couture'));
    });
  });

  group('Media Asset Domain Model', () {
    test('MediaAsset size formatting and responsive URLs', () {
      const asset = MediaAsset(
        id: 'asset-uuid-1',
        bucket: 'lookbook',
        filePath: 'resort_2026_01.jpg',
        filename: 'resort_2026_01.jpg',
        url: 'https://cdn.ochanyagili.com/lookbook/resort_2026_01.jpg',
        altText: 'Emerald structured silk gown with architectural peplum',
        title: 'Emerald Gown Look 1',
        sizeBytes: 1572864, // ~1.5 MB
        responsiveUrls: {
          'desktop': 'https://cdn.ochanyagili.com/lookbook/resort_2026_01.jpg?w=1920',
          'tablet': 'https://cdn.ochanyagili.com/lookbook/resort_2026_01.jpg?w=1080',
          'thumbnail': 'https://cdn.ochanyagili.com/lookbook/resort_2026_01.jpg?w=400',
        },
      );

      expect(asset.formattedSize, equals('1.50 MB'));
      expect(asset.responsiveUrls['desktop'], contains('w=1920'));
      expect(asset.responsiveUrls['thumbnail'], contains('w=400'));

      final json = asset.toJson();
      final fromJson = MediaAsset.fromJson(json);

      expect(fromJson.id, equals('asset-uuid-1'));
      expect(fromJson.bucket, equals('lookbook'));
      expect(fromJson.altText, contains('Emerald'));
      expect(fromJson.responsiveUrls.length, equals(3));
    });
  });
}
