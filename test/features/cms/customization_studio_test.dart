import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/cms/domain/models/navigation_item.dart';
import 'package:ochanya_gili/features/cms/domain/models/brand_header.dart';
import 'package:ochanya_gili/features/cms/domain/models/footer_config.dart';
import 'package:ochanya_gili/features/cms/domain/models/dynamic_theme_tokens.dart';
import 'package:ochanya_gili/features/cms/domain/models/custom_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('White-Label Customization Studio — Domain & Architecture Tests', () {
    test('NavigationItem parses JSON, serializes, and toggles properties', () {
      final json = {
        'id': 'nav-test-1',
        'title': 'Bespoke Atelier',
        'path': '/account/custom-requests',
        'sort_order': 2,
        'is_visible': true,
        'is_external': false,
      };

      final item = NavigationItem.fromJson(json);
      expect(item.id, equals('nav-test-1'));
      expect(item.title, equals('Bespoke Atelier'));
      expect(item.path, equals('/account/custom-requests'));
      expect(item.sortOrder, equals(2));
      expect(item.isVisible, isTrue);
      expect(item.isExternal, isFalse);

      final modified = item.copyWith(
        title: 'VIP Salon',
        isVisible: false,
        sortOrder: 5,
        isExternal: true,
      );
      expect(modified.title, equals('VIP Salon'));
      expect(modified.isVisible, isFalse);
      expect(modified.sortOrder, equals(5));
      expect(modified.isExternal, isTrue);

      final serialized = modified.toJson();
      expect(serialized['title'], equals('VIP Salon'));
      expect(serialized['is_visible'], isFalse);
      expect(serialized['sort_order'], equals(5));
      expect(serialized['is_external'], isTrue);
    });

    test('BrandHeader manages logo, brand name, and announcement ticker', () {
      const defaultHeader = BrandHeader();
      expect(defaultHeader.brandName, equals('OCHANYA GILI'));
      expect(defaultHeader.showAnnouncement, isTrue);
      expect(defaultHeader.announcementText, contains('COMPLIMENTARY DELIVERY'));

      final customJson = {
        'brand_name': 'MAISON OCHANYA',
        'logo_url': 'https://storage.ochanyagili.com/brand/logo.png',
        'tagline': 'CONTEMPORARY COUTURE',
        'announcement_text': 'PRIVATE SALON RE-OPENING THIS FRIDAY',
        'show_announcement': false,
      };

      final custom = BrandHeader.fromJson(customJson);
      expect(custom.brandName, equals('MAISON OCHANYA'));
      expect(custom.logoUrl, equals('https://storage.ochanyagili.com/brand/logo.png'));
      expect(custom.showAnnouncement, isFalse);

      final exported = custom.toJson();
      expect(exported['brand_name'], equals('MAISON OCHANYA'));
      expect(exported['show_announcement'], isFalse);
    });

    test('FooterConfig parses multi-column layout and social handles', () {
      final json = {
        'tagline': 'Haute Couture Excellence',
        'address': 'Maitama, Abuja',
        'copyright': '© 2026 Maison Ochanya',
        'social_links': {
          'instagram': 'https://instagram.com/maison',
          'whatsapp': 'https://wa.me/234800000',
          'twitter': 'https://x.com/maison',
          'facebook': '',
        },
        'columns': [
          {
            'title': 'Concierge',
            'links': [
              {'title': 'Book Fitting', 'url': '/account/appointments/book', 'is_external': false},
              {'title': 'Press Inquiries', 'url': 'https://press.ochanyagili.com', 'is_external': true},
            ],
          },
        ],
      };

      final footer = FooterConfig.fromJson(json);
      expect(footer.tagline, equals('Haute Couture Excellence'));
      expect(footer.address, equals('Maitama, Abuja'));
      expect(footer.socialLinks.instagram, equals('https://instagram.com/maison'));
      expect(footer.columns.length, equals(1));
      expect(footer.columns.first.title, equals('Concierge'));
      expect(footer.columns.first.links.length, equals(2));
      expect(footer.columns.first.links[1].isExternal, isTrue);

      final serialized = footer.toJson();
      expect(serialized['columns'], isA<List>());
    });

    test('DynamicThemeTokens parses hex colors, presets, and builds AppColorTokens', () {
      // Hex parsing test
      final color = DynamicThemeTokens.parseHex('#C9A96E', Colors.black);
      expect(color.toARGB32(), equals(0xFFC9A96E));

      // Preset test
      expect(DynamicThemeTokens.classicOchanya.accentHex, equals('#1A1A1A'));
      expect(DynamicThemeTokens.royalEmerald.accentHex, equals('#0E3B2F'));
      expect(DynamicThemeTokens.midnightCouture.accentHex, equals('#0F172A'));
      expect(DynamicThemeTokens.luxuryDarkMode.backgroundHex, equals('#121212'));

      // Token conversion test
      final dynamicTokens = DynamicThemeTokens.royalEmerald;
      final appTokens = dynamicTokens.toAppColorTokens();
      expect(appTokens.accent, equals(const Color(0xFF0E3B2F)));
      expect(appTokens.accentVariant, equals(const Color(0xFFC29B38)));

      // Dark mode token conversion
      final darkAppTokens = DynamicThemeTokens.luxuryDarkMode.toAppColorTokens();
      expect(darkAppTokens.background, equals(const Color(0xFF121212)));
      expect(darkAppTokens.onAccent, equals(const Color(0xFF121212)));

      // Build ThemeData with tokens
      final theme = AppTheme.buildTheme(appTokens);
      expect(theme.colorScheme.primary, equals(const Color(0xFF0E3B2F)));
      expect(theme.extension<AppColorTokens>()!.accent, equals(const Color(0xFF0E3B2F)));
    });

    test('CustomPage model validates serialization, slug, and publication state', () {
      final now = DateTime.now();
      final page = CustomPage(
        id: 'page-101',
        title: 'Sustainability & Heritage',
        slug: 'sustainability-and-heritage',
        content: 'We source raw indigenous silks and honor generational weaving techniques.',
        metaDescription: 'Our commitment to ancestral preservation.',
        isPublished: true,
        createdAt: now,
      );

      expect(page.id, equals('page-101'));
      expect(page.slug, equals('sustainability-and-heritage'));
      expect(page.isPublished, isTrue);

      final jsonWithId = page.toJson(includeId: true);
      expect(jsonWithId['id'], equals('page-101'));
      expect(jsonWithId['title'], equals('Sustainability & Heritage'));

      final jsonWithoutId = page.toJson(includeId: false);
      expect(jsonWithoutId.containsKey('id'), isFalse);
      expect(jsonWithoutId['slug'], equals('sustainability-and-heritage'));

      final parsed = CustomPage.fromJson(jsonWithId);
      expect(parsed.title, equals(page.title));
      expect(parsed.content, equals(page.content));
    });
  });
}
