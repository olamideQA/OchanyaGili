import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/core/seo/seo_metadata.dart';
import 'package:ochanya_gili/core/seo/seo_service.dart';
import 'package:ochanya_gili/core/services/public_content_cache.dart';
import 'package:ochanya_gili/core/services/responsive_image_service.dart';
import 'package:ochanya_gili/core/utils/performance_tracker.dart';
import 'package:ochanya_gili/features/shop/domain/models/product.dart';
import 'package:ochanya_gili/features/shop/domain/models/shop_filter_state.dart';

void main() {
  group('Loop 13: SEO Metadata & Structured Data Tests', () {
    test('SeoMetadata.home generates canonical URL, OpenGraph defaults, and Maison Schema', () {
      final meta = SeoMetadata.home();
      expect(meta.canonicalUrl, 'https://ochanyagili.com/');
      expect(meta.fullTitle, contains('Ochanya Gili'));
      expect(meta.ogType, 'website');
      expect(meta.structuredData, isNotNull);
      expect(meta.structuredData!['@type'], 'ClothingStore');
      expect(meta.structuredData!['name'], 'Ochanya Gili');
      expect(meta.jsonLdString, contains('"@type": "ClothingStore"'));
    });

    test('SeoMetadata.product generates product schema, offer price, and canonical path', () {
      final meta = SeoMetadata.product(
        name: 'Structured Ivory Tuxedo Blazer',
        slug: 'structured-ivory-tuxedo-blazer',
        description: 'Tailored double-breasted blazer with satin lapels.',
        price: 185000.0,
        imageUrl: 'https://images.unsplash.com/photo-blazer',
        category: 'Suits & Tailoring',
        inStock: true,
      );

      expect(meta.canonicalUrl, 'https://ochanyagili.com/shop/structured-ivory-tuxedo-blazer');
      expect(meta.ogType, 'product');
      expect(meta.structuredData, isNotNull);
      expect(meta.structuredData!['@type'], 'Product');
      expect(meta.structuredData!['name'], 'Structured Ivory Tuxedo Blazer');

      final offers = meta.structuredData!['offers'] as Map<String, dynamic>;
      expect(offers['@type'], 'Offer');
      expect(offers['priceCurrency'], 'NGN');
      expect(offers['price'], 185000.0);
      expect(offers['availability'], 'https://schema.org/InStock');
    });

    test('SeoMetadata.collection generates collection page schema', () {
      final meta = SeoMetadata.collection(
        title: 'Benue Regalia',
        slug: 'benue-regalia',
        description: 'Traditional woven regalia tailored for ceremonial presence.',
        season: 'SS26',
        imageUrl: 'https://images.unsplash.com/photo-regalia',
      );

      expect(meta.canonicalUrl, 'https://ochanyagili.com/collections/benue-regalia');
      expect(meta.structuredData!['@type'], 'CollectionPage');
      expect(meta.structuredData!['name'], 'Benue Regalia');
      expect(meta.fullTitle, contains('Benue Regalia — SS26'));
    });

    test('SeoMetadata.journalPost generates article/blog schema with publisher', () {
      final meta = SeoMetadata.journalPost(
        title: 'The Architecture of Idoma Weaving',
        slug: 'the-architecture-of-idoma-weaving',
        excerpt: 'An investigation into structural heritage textiles.',
        publishedDate: '2026-09-29T12:00:00Z',
        author: 'Ochanya Gili',
        imageUrl: 'https://images.unsplash.com/photo-weaving',
      );

      expect(meta.canonicalUrl, 'https://ochanyagili.com/journal/the-architecture-of-idoma-weaving');
      expect(meta.ogType, 'article');
      expect(meta.structuredData!['@type'], 'BlogPosting');
      expect(meta.structuredData!['headline'], 'The Architecture of Idoma Weaving');
      final author = meta.structuredData!['author'] as Map<String, dynamic>;
      expect(author['name'], 'Ochanya Gili');
    });

    test('SeoService applies static route metadata correctly', () {
      final seo = SeoService();
      seo.applyRoute('/shop');
      expect(seo.currentMetadata?.path, '/shop');
      expect(seo.currentMetadata?.title, 'Ready-to-Wear & Couture Archive');

      seo.applyRoute('/about');
      expect(seo.currentMetadata?.path, '/about');
      expect(seo.currentMetadata?.title, 'The Atelier Philosophy & Craftsmanship');

      seo.applyRoute('/contact');
      expect(seo.currentMetadata?.path, '/contact');

      seo.applyRoute('/create-your-look');
      expect(seo.currentMetadata?.path, '/create-your-look');
    });
  });

  group('Loop 13: Public Content In-Memory Cache Tests', () {
    test('PublicContentCacheService caches data and tracks hit/miss statistics', () async {
      final cache = PublicContentCacheService(defaultTtl: const Duration(minutes: 5));
      expect(cache.totalRequests, 0);
      expect(cache.hitRate, 0.0);

      int networkCalls = 0;
      Future<String> fetchMockData() async {
        networkCalls++;
        return 'couture_hero_data_v1';
      }

      // 1. Initial fetch (Miss)
      final res1 = await cache.getOrFetch(key: 'hero_slides', fetcher: fetchMockData);
      expect(res1, 'couture_hero_data_v1');
      expect(networkCalls, 1);
      expect(cache.cacheHits, 0);
      expect(cache.cacheMisses, 1);

      // 2. Second fetch within TTL (Hit)
      final res2 = await cache.getOrFetch(key: 'hero_slides', fetcher: fetchMockData);
      expect(res2, 'couture_hero_data_v1');
      expect(networkCalls, 1); // No new network call!
      expect(cache.cacheHits, 1);
      expect(cache.cacheMisses, 1);
      expect(cache.hitRate, 50.0);

      // 3. Invalidate key
      cache.invalidate('hero_slides');
      final res3 = await cache.getOrFetch(key: 'hero_slides', fetcher: fetchMockData);
      expect(res3, 'couture_hero_data_v1');
      expect(networkCalls, 2);
      expect(cache.cacheMisses, 2);

      // 4. Purge all
      cache.clear();
      expect(cache.totalRequests, 0);
    });
  });

  group('Loop 13: Performance Instrumentation Tests', () {
    test('PerformanceTracker records samples and calculates averages against SLA targets', () {
      final tracker = PerformanceTracker();
      final metrics = tracker.getAllMetrics();
      expect(metrics.length, greaterThanOrEqualTo(6));

      // Test route transition metric
      final routeMetric = tracker.getMetric('route_transition');
      expect(routeMetric, isNotNull);
      expect(routeMetric!.targetMs, 250);

      // Add high-performance samples
      tracker.recordSample('route_transition', 50);
      tracker.recordSample('route_transition', 60);
      expect(routeMetric.averageMs, lessThanOrEqualTo(250.0));
      expect(routeMetric.isOptimal, isTrue);

      // Trace stopwatch utility
      final trace = tracker.startTrace('product_query');
      final elapsed = trace.stop();
      expect(elapsed, greaterThanOrEqualTo(0));
    });
  });

  group('Loop 13: Catalogue Pagination Tests', () {
    test('PaginatedProducts calculates page counts and boundary states accurately', () {
      final dummyProducts = List.generate(
        25,
        (i) => Product(
          id: 'p-$i',
          name: 'Creation $i',
          slug: 'creation-$i',
          basePrice: 100000.0,
          productType: ProductType.readyToWear,
        ),
      );

      // Page 1 with pageSize 10
      final page1 = PaginatedProducts(
        items: dummyProducts.sublist(0, 10),
        totalCount: 25,
        page: 1,
        pageSize: 10,
      );
      expect(page1.totalPages, 3);
      expect(page1.hasPreviousPage, isFalse);
      expect(page1.hasNextPage, isTrue);

      // Page 2
      final page2 = PaginatedProducts(
        items: dummyProducts.sublist(10, 20),
        totalCount: 25,
        page: 2,
        pageSize: 10,
      );
      expect(page2.hasPreviousPage, isTrue);
      expect(page2.hasNextPage, isTrue);

      // Page 3 (Last page with remainder 5 items)
      final page3 = PaginatedProducts(
        items: dummyProducts.sublist(20, 25),
        totalCount: 25,
        page: 3,
        pageSize: 10,
      );
      expect(page3.items.length, 5);
      expect(page3.hasPreviousPage, isTrue);
      expect(page3.hasNextPage, isFalse);

      // Empty results
      const emptyPage = PaginatedProducts(
        items: [],
        totalCount: 0,
        page: 1,
        pageSize: 10,
      );
      expect(emptyPage.totalPages, 1);
      expect(emptyPage.hasNextPage, isFalse);
    });

    test('ShopFilterState handles pagination parameters and resets correctly', () {
      const state = ShopFilterState();
      expect(state.page, 1);
      expect(state.pageSize, 9);

      final nextState = state.copyWith(page: 3);
      expect(nextState.page, 3);

      final searchReset = nextState.copyWith(searchQuery: 'corset', page: 1);
      expect(searchReset.page, 1);
      expect(searchReset.searchQuery, 'corset');
    });
  });

  group('Loop 13: Responsive CDN Image Delivery Tests', () {
    test('ResponsiveImageService transforms Supabase storage URLs with width and WebP format', () {
      const rawUrl = 'https://gfobzdetjbqwrxnutrkj.supabase.co/storage/v1/object/public/products/silk_corset.jpg';
      final cardUrl = ResponsiveImageService.getOptimizedUrl(
        rawUrl,
        context: ImageContext.card,
      );

      expect(cardUrl, contains('/storage/v1/render/image/public/'));
      expect(cardUrl, contains('width=640'));
      expect(cardUrl, contains('format=webp'));
      expect(cardUrl, contains('quality=80'));

      final heroUrl = ResponsiveImageService.getOptimizedUrl(
        rawUrl,
        context: ImageContext.hero,
      );
      expect(heroUrl, contains('width=1920'));
    });

    test('ResponsiveImageService transforms Unsplash URLs with w and auto=format', () {
      const rawUrl = 'https://images.unsplash.com/photo-1509631179647-0177331693ae?q=80';
      final optimized = ResponsiveImageService.getOptimizedUrl(
        rawUrl,
        context: ImageContext.thumbnail,
      );

      expect(optimized, contains('w=240'));
      expect(optimized, contains('auto=format'));
      expect(optimized, contains('fit=crop'));
    });
  });
}
