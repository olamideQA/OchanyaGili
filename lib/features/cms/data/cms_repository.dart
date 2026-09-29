import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/core/config/demo_config.dart';
import 'package:ochanya_gili/features/cms/domain/models/cms_content.dart';
import 'package:ochanya_gili/features/journal/domain/models/journal_post.dart';
import 'package:ochanya_gili/features/cms/domain/models/navigation_item.dart';
import 'package:ochanya_gili/features/cms/domain/models/brand_header.dart';
import 'package:ochanya_gili/features/cms/domain/models/footer_config.dart';
import 'package:ochanya_gili/features/cms/domain/models/dynamic_theme_tokens.dart';
import 'package:ochanya_gili/features/cms/domain/models/custom_page.dart';

class CmsRepository {
  final SupabaseClient _client;

  CmsRepository(this._client);

  // Known-dead placeholder CDN — treat as missing so pitch shows lively art.
  bool _isDeadImage(String url) =>
      url.isEmpty || url.contains('cdn.ochanyagili.com');

  Future<List<HeroSlide>> getHeroSlides() async {
    try {
      final res = await _client.from('settings').select('value').eq('key', 'hero_slides').maybeSingle();
      if (res != null && res['value'] is List) {
        final list = res['value'] as List<dynamic>;
        final slides = list.map((e) => HeroSlide.fromJson(e as Map<String, dynamic>)).toList();
        // If DB points at dead CDN, ignore it and use lively pitch art.
        final hasDead = slides.any((s) =>
            _isDeadImage(s.desktopImageUrl) || _isDeadImage(s.mobileImageUrl));
        if (slides.isNotEmpty && !hasDead) return slides;
      }
    } catch (_) {}

    // DEMO-SEED START: pitch fallback slides. Delete block or set
    // DemoConfig.enabled=false to strip for clean template handoff.
    if (!DemoConfig.enabled) return const [];
    return const [
      HeroSlide(
        id: 'default-slide-1',
        title: 'OCHANYA GILI',
        subtitle: 'Sartorial Sovereignty. Contemporary African Couture.',
        ctaText: 'EXPLORE THE CAMPAIGN',
        ctaLink: '/collections',
        desktopImageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?q=80&w=1920&h=1080&auto=format&fit=crop',
        mobileImageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?q=80&w=768&h=1024&auto=format&fit=crop',
        sortOrder: 0,
      ),
      HeroSlide(
        id: 'default-slide-2',
        title: 'CREATE YOUR LOOK',
        subtitle: 'Your Vision. Our Craftsmanship.',
        ctaText: 'DISCOVER BESPOKE ATELIER',
        ctaLink: '/account/custom-requests',
        desktopImageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=1920&h=1080&auto=format&fit=crop',
        mobileImageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=768&h=1024&auto=format&fit=crop',
        sortOrder: 1,
      ),
    ];
  }

  Future<void> updateHeroSlides(List<HeroSlide> slides) async {
    final payload = slides.map((e) => e.toJson()).toList();
    await _client.from('settings').upsert({
      'key': 'hero_slides',
      'value': payload,
      'description': 'Homepage hero campaign slides',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<EditorialBlock> getEditorialBlock() async {
    try {
      final res = await _client.from('settings').select('value').eq('key', 'featured_editorial').maybeSingle();
      if (res != null && res['value'] is Map) {
        final block = EditorialBlock.fromJson(res['value'] as Map<String, dynamic>);
        if (!_isDeadImage(block.imageUrl)) return block;
      }
    } catch (_) {}

    // DEMO-SEED START: pitch editorial fallback. Strip with DemoConfig.enabled=false.
    if (!DemoConfig.enabled) {
      return const EditorialBlock(
        headline: '',
        subheadline: '',
        body: '',
        imageUrl: '',
        ctaText: '',
        ctaLink: '/collections',
      );
    }
    return const EditorialBlock(
      headline: 'AUTUMN / WINTER 2026',
      subheadline: 'THE RESORT COLLECTION',
      body:
          'Structured corsetry, sculptural peplums, and hand-woven silks honoring the royal lineages of West Africa, sculpted for the contemporary cosmopolitan woman.',
      imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=1080&h=1350&auto=format&fit=crop',
      ctaText: 'EXPLORE COLLECTION',
      ctaLink: '/collections',
    );
  }

  Future<void> updateEditorialBlock(EditorialBlock block) async {
    await _client.from('settings').upsert({
      'key': 'featured_editorial',
      'value': block.toJson(),
      'description': 'Homepage featured editorial block',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<AboutContent> getAboutContent() async {
    try {
      final res = await _client.from('settings').select('value').eq('key', 'about_content').maybeSingle();
      if (res != null && res['value'] is Map) {
        final about = AboutContent.fromJson(res['value'] as Map<String, dynamic>);
        if (!_isDeadImage(about.heroImageUrl)) return about;
      }
    } catch (_) {}

    // DEMO-SEED START: pitch about fallback. Strip with DemoConfig.enabled=false.
    if (!DemoConfig.enabled) {
      return const AboutContent(
        title: '',
        philosophy: '',
        craftsmanship: '',
        designerBio: '',
        studioAddress: '',
        heroImageUrl: '',
      );
    }
    return const AboutContent(
      title: 'THE HOUSE OF OCHANYA GILI',
      philosophy:
          'We believe luxury is intimate. It is the weight of woven silk falling against the skin, the precision of a dart aligned to within millimeters, and the unspoken presence of sovereign craftsmanship.',
      craftsmanship:
          'Each creation begins with an architectural study of silhouette. Our artisans combine ancestral hand-finishing techniques with modern couture draping, ensuring each garment is both heir-apparent and timeless.',
      designerBio:
          'Founded by Ochanya Gili, the atelier stands at the vanguard of African modernism, dressing leaders, artists, and visionaries across Lagos, Abuja, London, Paris, and New York.',
      studioAddress: 'Plot 104, Maitama Luxury Enclave, Abuja, Nigeria',
      heroImageUrl: 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?q=80&w=1440&auto=format&fit=crop',
    );
  }

  Future<void> updateAboutContent(AboutContent content) async {
    await _client.from('settings').upsert({
      'key': 'about_content',
      'value': content.toJson(),
      'description': 'About page editorial content',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<ContactDetails> getContactDetails() async {
    try {
      final res = await _client.from('settings').select('value').eq('key', 'contact_details').maybeSingle();
      if (res != null && res['value'] is Map) {
        return ContactDetails.fromJson(res['value'] as Map<String, dynamic>);
      }
    } catch (_) {}

    // DEMO-SEED START: pitch contact fallback. TEMPLATE-CUSTOMIZE: replace
    // with BrandConfig values for resale. Strip with DemoConfig.enabled=false.
    if (!DemoConfig.enabled) {
      return const ContactDetails(
        conciergeEmail: '',
        studioPhone: '',
        address: '',
        openingHours: '',
        instagram: '',
      );
    }
    return const ContactDetails(
      conciergeEmail: 'concierge@ochanyagili.com',
      studioPhone: '+234 (0) 808 000 8888',
      address: 'Plot 104, Maitama Luxury District, Abuja, Nigeria',
      openingHours: 'Monday – Saturday: 10:00 – 18:00 (Private Fitting by Appointment)',
      instagram: '@ochanyagiliofficial',
    );
  }

  Future<void> updateContactDetails(ContactDetails details) async {
    await _client.from('settings').upsert({
      'key': 'contact_details',
      'value': details.toJson(),
      'description': 'Studio contact and concierge details',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<JournalPost>> getPublishedJournalPosts() async {
    try {
      final res = await _client
          .from('journal_posts')
          .select()
          .eq('is_published', true)
          .order('published_at', ascending: false);

      final posts = (res as List<dynamic>).map((e) => JournalPost.fromJson(e as Map<String, dynamic>)).toList();
      if (posts.isNotEmpty) {
        final hasDead = posts.any((p) => _isDeadImage(p.coverImageUrl));
        if (!hasDead) return posts;
        // DB has dead CDN art — fall through to lively demo below.
      }
    } catch (_) {
      // fall through to demo
    }
    {
      // DEMO-SEED START: 2 pitch journal posts. Delete block or set
      // DemoConfig.enabled=false to strip for clean template handoff.
      if (!DemoConfig.enabled) return [];
      return [
        JournalPost(
          id: 'post-1',
          title: 'The Architecture of the Peplum: Reimagining Royal Nigerian Silhouettes',
          slug: 'architecture-of-the-peplum',
          excerpt:
              'An exploration of how traditional Benue and Edo court attire inspires the clean structural lines of the Autumn 2026 collection.',
          content:
              'In the quiet sanctuary of the Maitama atelier, the journey of each silhouette begins not with fabric, but with geometry. The Nigerian peplum is not merely decorative; historically, it represented stature, authority, and ceremonial grace...\n\nBy marrying structural wool crepe with supple organza linings, the house explores tension between strength and softness.',
          coverImageUrl:
              'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=1080&auto=format&fit=crop',
          isPublished: true,
          publishedAt: DateTime.now().subtract(const Duration(days: 3)),
          tags: const ['Couture', 'Craftsmanship', 'Silhouettes'],
        ),
        JournalPost(
          id: 'post-2',
          title: 'Sartorial Soliloquy: Inside the Private Fitting Ritual',
          slug: 'inside-the-private-fitting-ritual',
          excerpt: 'Why eighteen distinct anatomical measurements are only the beginning of a true bespoke commission.',
          content:
              'A tape measure records dimensions; a master couturier records posture, rhythm, and confidence. When a client steps into our private salon, the fitting is a collaborative dialogue...\n\nEvery seam is pinned in live harmony with how the woman moves, breaths, and commands space.',
          coverImageUrl:
              'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=1080&auto=format&fit=crop',
          isPublished: true,
          publishedAt: DateTime.now().subtract(const Duration(days: 10)),
          tags: const ['Bespoke', 'Atelier', 'Fittings'],
        ),
      ];
    }
  }

  Future<JournalPost?> getJournalPostBySlug(String slug) async {
    try {
      final res = await _client
          .from('journal_posts')
          .select()
          .eq('slug', slug)
          .eq('is_published', true)
          .maybeSingle();

      if (res != null) {
        return JournalPost.fromJson(res);
      }
    } catch (_) {}

    final posts = await getPublishedJournalPosts();
    return posts.firstWhere(
      (p) => p.slug == slug,
      orElse: () => posts.first,
    );
  }

  // ==========================================
  // CUSTOMIZATION STUDIO: NAVIGATION MENU TABS
  // ==========================================
  Future<List<NavigationItem>> getNavigationItems() async {
    try {
      final res = await _client.from('settings').select('value').eq('key', 'nav_menu').maybeSingle();
      if (res != null && res['value'] is List) {
        final list = res['value'] as List<dynamic>;
        final items = list.map((e) => NavigationItem.fromJson(e as Map<String, dynamic>)).toList();
        items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    return const [
      NavigationItem(id: 'nav-1', title: 'Collections', path: '/collections', sortOrder: 0),
      NavigationItem(id: 'nav-2', title: 'Shop', path: '/shop', sortOrder: 1),
      NavigationItem(id: 'nav-3', title: 'Lookbook', path: '/lookbook', sortOrder: 2),
      NavigationItem(id: 'nav-4', title: 'Journal', path: '/journal', sortOrder: 3),
      NavigationItem(id: 'nav-5', title: 'About', path: '/about', sortOrder: 4),
      NavigationItem(id: 'nav-6', title: 'Contact', path: '/contact', sortOrder: 5),
    ];
  }

  Future<void> saveNavigationItems(List<NavigationItem> items) async {
    final payload = items.map((e) => e.toJson()).toList();
    await _client.from('settings').upsert({
      'key': 'nav_menu',
      'value': payload,
      'description': 'Storefront header navigation tabs and links',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ==========================================
  // CUSTOMIZATION STUDIO: BRAND HEADER & LOGO
  // ==========================================
  Future<BrandHeader> getBrandHeader() async {
    try {
      final res = await _client.from('settings').select('value').eq('key', 'brand_header').maybeSingle();
      if (res != null && res['value'] is Map) {
        return BrandHeader.fromJson(res['value'] as Map<String, dynamic>);
      }
    } catch (_) {}

    return const BrandHeader();
  }

  Future<void> saveBrandHeader(BrandHeader header) async {
    await _client.from('settings').upsert({
      'key': 'brand_header',
      'value': header.toJson(),
      'description': 'Brand identity for header and logo display',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ==========================================
  // CUSTOMIZATION STUDIO: FOOTER CONFIGURATION
  // ==========================================
  Future<FooterConfig> getFooterConfig() async {
    try {
      final res = await _client.from('settings').select('value').eq('key', 'footer_config').maybeSingle();
      if (res != null && res['value'] is Map) {
        return FooterConfig.fromJson(res['value'] as Map<String, dynamic>);
      }
    } catch (_) {}

    return const FooterConfig(
      tagline: 'Sartorial Sovereignty. Contemporary African Couture crafted with architectural poise and artisanal excellence.',
      address: 'Victoria Island, Lagos, Nigeria',
      copyright: '© 2026 Ochanya Gili Atelier. All rights reserved.',
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/ochanyagili',
        whatsapp: 'https://wa.me/2348000000000',
        twitter: 'https://x.com/ochanyagili',
      ),
      columns: [
        FooterColumn(
          title: 'Collections',
          links: [
            FooterLink(title: 'Benue Regalia', url: '/collections/benue-regalia'),
            FooterLink(title: 'Idoma Royal Silk', url: '/collections/idoma-royal-silk'),
            FooterLink(title: 'The Bridal Atelier', url: '/collections/the-bridal-atelier'),
            FooterLink(title: 'Archive & Lookbook', url: '/lookbook'),
          ],
        ),
        FooterColumn(
          title: 'Atelier Concierge',
          links: [
            FooterLink(title: 'Create Your Look', url: '/create-your-look'),
            FooterLink(title: 'Book Private Fitting', url: '/account/appointments/book'),
            FooterLink(title: 'Measurement Guide', url: '/account/measurements'),
            FooterLink(title: 'Shipping & Delivery', url: '/about'),
          ],
        ),
        FooterColumn(
          title: 'The Maison',
          links: [
            FooterLink(title: 'Our Heritage', url: '/about'),
            FooterLink(title: 'Editorial Journal', url: '/journal'),
            FooterLink(title: 'Private Consultations', url: '/contact'),
          ],
        ),
      ],
    );
  }

  Future<void> saveFooterConfig(FooterConfig config) async {
    await _client.from('settings').upsert({
      'key': 'footer_config',
      'value': config.toJson(),
      'description': 'Footer layout, links, columns, and brand legal info',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ==========================================
  // CUSTOMIZATION STUDIO: THEME PALETTE TOKENS
  // ==========================================
  Future<DynamicThemeTokens> getThemeTokens() async {
    try {
      final res = await _client.from('settings').select('value').eq('key', 'theme_tokens').maybeSingle();
      if (res != null && res['value'] is Map) {
        return DynamicThemeTokens.fromJson(res['value'] as Map<String, dynamic>);
      }
    } catch (_) {}

    return const DynamicThemeTokens();
  }

  Future<void> saveThemeTokens(DynamicThemeTokens tokens) async {
    await _client.from('settings').upsert({
      'key': 'theme_tokens',
      'value': tokens.toJson(),
      'description': 'Maison brand color tokens customizable by client',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ==========================================
  // CUSTOMIZATION STUDIO: DYNAMIC CUSTOM PAGES
  // ==========================================
  Future<List<CustomPage>> getCustomPages() async {
    try {
      final res = await _client
          .from('custom_pages')
          .select()
          .order('created_at', ascending: false);
      return (res as List<dynamic>).map((e) => CustomPage.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<CustomPage?> getCustomPageBySlug(String slug) async {
    try {
      final res = await _client
          .from('custom_pages')
          .select()
          .eq('slug', slug)
          .eq('is_published', true)
          .maybeSingle();
      if (res != null) {
        return CustomPage.fromJson(res);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveCustomPage(CustomPage page) async {
    if (page.id.isEmpty) {
      await _client.from('custom_pages').insert(page.toJson(includeId: false));
    } else {
      await _client
          .from('custom_pages')
          .update({...page.toJson(includeId: false), 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', page.id);
    }
  }

  Future<void> deleteCustomPage(String id) async {
    await _client.from('custom_pages').delete().eq('id', id);
  }
}

final cmsRepositoryProvider = Provider<CmsRepository>((ref) {
  return CmsRepository(Supabase.instance.client);
});

final heroSlidesProvider = FutureProvider<List<HeroSlide>>((ref) {
  return ref.watch(cmsRepositoryProvider).getHeroSlides();
});

final editorialBlockProvider = FutureProvider<EditorialBlock>((ref) {
  return ref.watch(cmsRepositoryProvider).getEditorialBlock();
});

final aboutContentProvider = FutureProvider<AboutContent>((ref) {
  return ref.watch(cmsRepositoryProvider).getAboutContent();
});

final contactDetailsProvider = FutureProvider<ContactDetails>((ref) {
  return ref.watch(cmsRepositoryProvider).getContactDetails();
});

final journalPostsProvider = FutureProvider<List<JournalPost>>((ref) {
  return ref.watch(cmsRepositoryProvider).getPublishedJournalPosts();
});

// Customization Studio Providers
final navigationItemsProvider = FutureProvider<List<NavigationItem>>((ref) {
  return ref.watch(cmsRepositoryProvider).getNavigationItems();
});

final brandHeaderProvider = FutureProvider<BrandHeader>((ref) {
  return ref.watch(cmsRepositoryProvider).getBrandHeader();
});

final footerConfigProvider = FutureProvider<FooterConfig>((ref) {
  return ref.watch(cmsRepositoryProvider).getFooterConfig();
});

final dynamicThemeTokensProvider = FutureProvider<DynamicThemeTokens>((ref) {
  return ref.watch(cmsRepositoryProvider).getThemeTokens();
});

final customPagesProvider = FutureProvider<List<CustomPage>>((ref) {
  return ref.watch(cmsRepositoryProvider).getCustomPages();
});

