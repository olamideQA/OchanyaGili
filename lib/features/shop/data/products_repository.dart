import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/core/config/demo_config.dart';
import 'package:ochanya_gili/features/shop/domain/models/product.dart';
import 'package:ochanya_gili/features/shop/domain/models/shop_filter_state.dart';
import 'package:ochanya_gili/features/analytics/data/analytics_service.dart';

class ProductsRepository {
  final SupabaseClient _client;

  ProductsRepository(this._client);

  // DEMO-SEED START: Calibrated Nigerian Haute Couture, Bridal & RTW products.
  static final List<Product> _defaultProducts = [
    // 1. WEDDING GOWN (Made-to-Order / Bridal)
    Product(
      id: 'prod-bridal-althea-gown',
      name: 'The Althea Corseted Cathedral Wedding Gown',
      slug: 'the-althea-corseted-cathedral-wedding-gown',
      shortDescription: 'Hand-beaded French chantilly lace gown with boned illusion corset and a 2.5-meter cathedral train.',
      description:
          'An ethereal masterpiece of bridal architecture. Features an internal multi-boned corset that sculpts the waist with precision, hand-appliquéd floral lace motifs descending across a shimmering tulle skirt, and a dramatic detachable cathedral lace train. Each pearl and crystal bead is hand-sewn over 180 hours in our Lagos atelier.',
      productType: ProductType.madeToOrder,
      basePrice: 1450000.0,
      materials: 'French Chantilly Lace, Silk Tulle, Duchess Satin inner lining, hand-strung glass crystals and micro-pearls.',
      careInstructions: 'Specialist bridal preservation only. Shipped in museum-grade archival garment chest.',
      sizeGuide: 'Custom tailored to your 18-point bridal anatomical measurements profile.',
      productionTimeDays: 28,
      deliveryEstimate: '4 – 6 Weeks Atelier Creation & Bridal Salon Fitting',
      isFeatured: true,
      images: const [
        ProductImage(
          id: 'img-bridal-1a',
          productId: 'prod-bridal-althea-gown',
          imageUrl: 'https://images.unsplash.com/photo-1594552072238-b8a33785b261?q=80&w=900&h=1200&auto=format&fit=crop',
          isPrimary: true,
        ),
        ProductImage(
          id: 'img-bridal-1b',
          productId: 'prod-bridal-althea-gown',
          imageUrl: 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?q=80&w=900&h=1200&auto=format&fit=crop',
        ),
      ],
      variants: const [
        ProductVariant(id: 'var-ba1', productId: 'prod-bridal-althea-gown', size: 'Bespoke Bridal Sizing', colour: 'Alabaster Ivory', sku: 'OG-BRD-ALT-IV', stockQuantity: 99),
      ],
    ),

    // 2. WEDDING GOWN (Ready-to-Wear / Silk Mikado)
    Product(
      id: 'prod-bridal-seraphina-gown',
      name: 'The Seraphina Mikado Silk Bridal Gown',
      slug: 'the-seraphina-mikado-silk-bridal-gown',
      shortDescription: 'Architectural off-shoulder mermaid wedding gown sculpted in heavyweight Italian silk mikado.',
      description:
          'For the modern bride who commands minimalist grandeur. Sculpted in lustrous ivory silk mikado with a folded off-shoulder portrait neckline, precision princess seams, and a flowing trumpet silhouette with an architectural back bow.',
      productType: ProductType.readyToWear,
      basePrice: 920000.0,
      compareAtPrice: 1050000.0,
      materials: '100% Italian Silk Mikado, Silk Habotai lining.',
      careInstructions: 'Specialist bridal dry clean only.',
      sizeGuide: 'UK 8 (Bust 34", Waist 26", Hips 37"), UK 10, UK 12, UK 14.',
      deliveryEstimate: '3 – 5 Business Days Express Dispatch with garment bag',
      isFeatured: true,
      images: const [
        ProductImage(
          id: 'img-seraphina-1',
          productId: 'prod-bridal-seraphina-gown',
          imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?q=80&w=900&h=1200&auto=format&fit=crop',
          isPrimary: true,
        ),
        ProductImage(
          id: 'img-seraphina-2',
          productId: 'prod-bridal-seraphina-gown',
          imageUrl: 'https://images.unsplash.com/photo-1568252542512-9fe8fe9c87bb?q=80&w=900&h=1200&auto=format&fit=crop',
        ),
      ],
      variants: const [
        ProductVariant(id: 'var-ser-8', productId: 'prod-bridal-seraphina-gown', size: 'UK 8 / S', colour: 'Pure Ivory', sku: 'OG-BRD-SER-8', stockQuantity: 2),
        ProductVariant(id: 'var-ser-10', productId: 'prod-bridal-seraphina-gown', size: 'UK 10 / M', colour: 'Pure Ivory', sku: 'OG-BRD-SER-10', stockQuantity: 3),
        ProductVariant(id: 'var-ser-12', productId: 'prod-bridal-seraphina-gown', size: 'UK 12 / L', colour: 'Pure Ivory', sku: 'OG-BRD-SER-12', stockQuantity: 2),
        ProductVariant(id: 'var-ser-14', productId: 'prod-bridal-seraphina-gown', size: 'UK 14 / XL', colour: 'Pure Ivory', sku: 'OG-BRD-SER-14', stockQuantity: 1),
      ],
    ),

    // 3. READY_TO_WEAR: Ivory Tuxedo Blazer
    Product(
      id: 'prod-rtw-blazer-1',
      name: 'Structured Ivory Tuxedo Blazer',
      slug: 'structured-ivory-tuxedo-blazer',
      shortDescription: 'Tailored double-breasted blazer with sharp shoulders and satin peak lapels.',
      description:
          'Cut from premium mid-weight wool crepe with pure silk satin lapels, this blazer embodies contemporary power tailoring. Features functional surgeon cuffs, internal pocketing, and hand-finished pick stitching.',
      productType: ProductType.readyToWear,
      basePrice: 165000.0,
      compareAtPrice: 195000.0,
      materials: '100% Wool Crepe outer, 100% Silk Satin lapel, Cupro lining.',
      careInstructions: 'Dry clean only by luxury garment specialist.',
      sizeGuide: 'Model is 178cm wearing size S (UK 8). True to size.',
      deliveryEstimate: '2 – 4 Business Days Express Dispatch',
      isFeatured: true,
      images: const [
        ProductImage(
          id: 'img-blazer-1',
          productId: 'prod-rtw-blazer-1',
          imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=900&h=1200&auto=format&fit=crop',
          isPrimary: true,
        ),
        ProductImage(
          id: 'img-blazer-2',
          productId: 'prod-rtw-blazer-1',
          imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=900&h=1200&auto=format&fit=crop',
        ),
      ],
      variants: const [
        ProductVariant(id: 'var-b1', productId: 'prod-rtw-blazer-1', size: 'UK 8 / S', colour: 'Ivory', sku: 'OG-BLZ-IV-8', stockQuantity: 4),
        ProductVariant(id: 'var-b2', productId: 'prod-rtw-blazer-1', size: 'UK 10 / M', colour: 'Ivory', sku: 'OG-BLZ-IV-10', stockQuantity: 6),
        ProductVariant(id: 'var-b3', productId: 'prod-rtw-blazer-1', size: 'UK 12 / L', colour: 'Ivory', sku: 'OG-BLZ-IV-12', stockQuantity: 2),
      ],
    ),

    // 4. MADE_TO_ORDER: Sovereign Peplum Evening Gown
    Product(
      id: 'prod-mto-peplum-gown-1',
      name: 'The Sovereign Peplum Evening Gown',
      slug: 'sovereign-peplum-evening-gown',
      shortDescription: 'Architectural column gown with detachable sculptural peplum and organza lining.',
      description:
          'Constructed from structured crepe and sculpted with internalized boning. The peplum is meticulously engineered to maintain dramatic volume while remaining featherlight. Requires customer anatomical measurements for bespoke fitting.',
      productType: ProductType.madeToOrder,
      basePrice: 380000.0,
      materials: 'Heavyweight Italian Silk Crepe, Silk Organza under-structure.',
      careInstructions: 'Specialist couture dry cleaning only. Store on padded hanger.',
      sizeGuide: 'Made to your specific measurements profile upon order submission.',
      productionTimeDays: 14,
      deliveryEstimate: '14 – 21 Days Atelier Craftsmanship & Delivery',
      isFeatured: true,
      images: const [
        ProductImage(
          id: 'img-gown-1',
          productId: 'prod-mto-peplum-gown-1',
          imageUrl: 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?q=80&w=900&h=1200&auto=format&fit=crop',
          isPrimary: true,
        ),
        ProductImage(
          id: 'img-gown-2',
          productId: 'prod-mto-peplum-gown-1',
          imageUrl: 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?q=80&w=900&h=1200&auto=format&fit=crop',
        ),
      ],
      variants: const [
        ProductVariant(id: 'var-g1', productId: 'prod-mto-peplum-gown-1', size: 'Custom Sized', colour: 'Emerald Gold', sku: 'OG-GWN-EG', stockQuantity: 99),
        ProductVariant(id: 'var-g2', productId: 'prod-mto-peplum-gown-1', size: 'Custom Sized', colour: 'Midnight Black', sku: 'OG-GWN-MB', stockQuantity: 99),
      ],
    ),

    // 5. MADE_TO_ORDER: Amina Corseted Reception Gown
    Product(
      id: 'prod-mto-amina-reception',
      name: 'The Amina Corseted Mermaid Reception Gown',
      slug: 'the-amina-corseted-mermaid-reception-gown',
      shortDescription: 'Emerald French lace with hand-sewn bugle beads, boned internal corset, and godet train.',
      description:
          'Designed for the modern Nigerian bride\'s second look or prestigious wedding guests. Features an internal waist-cinching corset, sheer illusion sleeves, and high-shine emerald bugle beading that dazzles under evening reception chandeliers.',
      productType: ProductType.madeToOrder,
      basePrice: 480000.0,
      materials: 'Hand-beaded French Lace, Silk Georgette, Internal Steel Boning.',
      careInstructions: 'Luxury specialist dry clean only.',
      sizeGuide: 'Made to customer anatomical measurements profile.',
      productionTimeDays: 14,
      deliveryEstimate: '14 – 18 Days Atelier Craftsmanship',
      isFeatured: true,
      images: const [
        ProductImage(
          id: 'img-amina-1',
          productId: 'prod-mto-amina-reception',
          imageUrl: 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?q=80&w=900&h=1200&auto=format&fit=crop',
          isPrimary: true,
        ),
        ProductImage(
          id: 'img-amina-2',
          productId: 'prod-mto-amina-reception',
          imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=900&h=1200&auto=format&fit=crop',
        ),
      ],
      variants: const [
        ProductVariant(id: 'var-am-em', productId: 'prod-mto-amina-reception', size: 'Custom Sized', colour: 'Emerald Green', sku: 'OG-REC-AM-EM', stockQuantity: 99),
        ProductVariant(id: 'var-am-cob', productId: 'prod-mto-amina-reception', size: 'Custom Sized', colour: 'Royal Cobalt', sku: 'OG-REC-AM-COB', stockQuantity: 99),
      ],
    ),

    // 6. READY_TO_WEAR: Alaari Handwoven Aso-Oke Suit
    Product(
      id: 'prod-rtw-alaari-suit',
      name: 'The Alaari Handwoven Aso-Oke Tailored Suit',
      slug: 'the-alaari-handwoven-aso-oke-tailored-suit',
      shortDescription: 'Crimson & metallic gold handwoven Aso-Oke cropped blazer with high-waist cigarette trousers.',
      description:
          'Woven on traditional vertical looms in southwestern Nigeria using heritage cotton and metallic lurex threads. Tailored with sharp 80s-inspired padded shoulders, horn buttons, and sleek tapered trousers with side silk piping.',
      productType: ProductType.readyToWear,
      basePrice: 235000.0,
      compareAtPrice: 260000.0,
      materials: '100% Handwoven Cotton Aso-Oke with Lurex threads, Silk Cupro lining.',
      careInstructions: 'Dry clean only by luxury garment specialist.',
      sizeGuide: 'UK 8 (S), UK 10 (M), UK 12 (L), UK 14 (XL).',
      deliveryEstimate: '2 – 4 Business Days Express Dispatch',
      isFeatured: false,
      images: const [
        ProductImage(
          id: 'img-alaari-1',
          productId: 'prod-rtw-alaari-suit',
          imageUrl: 'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?q=80&w=900&h=1200&auto=format&fit=crop',
          isPrimary: true,
        ),
        ProductImage(
          id: 'img-alaari-2',
          productId: 'prod-rtw-alaari-suit',
          imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=900&h=1200&auto=format&fit=crop',
        ),
      ],
      variants: const [
        ProductVariant(id: 'var-al-8', productId: 'prod-rtw-alaari-suit', size: 'UK 8 / S', colour: 'Alaari Crimson & Gold', sku: 'OG-ASO-AL-8', stockQuantity: 3),
        ProductVariant(id: 'var-al-10', productId: 'prod-rtw-alaari-suit', size: 'UK 10 / M', colour: 'Alaari Crimson & Gold', sku: 'OG-ASO-AL-10', stockQuantity: 4),
        ProductVariant(id: 'var-al-12', productId: 'prod-rtw-alaari-suit', size: 'UK 12 / L', colour: 'Alaari Crimson & Gold', sku: 'OG-ASO-AL-12', stockQuantity: 2),
      ],
    ),

    // 7. READY_TO_WEAR: Abeokuta Indigo Silk Robe Dress
    Product(
      id: 'prod-rtw-adire-robe',
      name: 'The Abeokuta Indigo Silk Adire Robe Dress',
      slug: 'the-abeokuta-indigo-silk-adire-robe-dress',
      shortDescription: 'Mulberry silk twill kimono dress hand-dyed in authentic Abeokuta Adire Eleko motifs.',
      description:
          'Crafted from heavyweight fluid silk twill, each piece is hand-stenciled and resist-dyed with natural indigo by female artisan guilds in Ogun State. Features kimono drop sleeves, a detachable sash belt, and hidden side seam pockets.',
      productType: ProductType.readyToWear,
      basePrice: 145000.0,
      materials: '100% Pure Mulberry Silk Twill.',
      careInstructions: 'Hand wash cold or gentle dry clean.',
      sizeGuide: 'Relaxed fit. S/M fits UK 6–10, M/L fits UK 12–16.',
      deliveryEstimate: '2 – 3 Business Days Express Shipping',
      isFeatured: false,
      images: const [
        ProductImage(
          id: 'img-adire-1',
          productId: 'prod-rtw-adire-robe',
          imageUrl: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?q=80&w=900&h=1200&auto=format&fit=crop',
          isPrimary: true,
        ),
        ProductImage(
          id: 'img-adire-2',
          productId: 'prod-rtw-adire-robe',
          imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=900&h=1200&auto=format&fit=crop',
        ),
      ],
      variants: const [
        ProductVariant(id: 'var-ad-sm', productId: 'prod-rtw-adire-robe', size: 'S / M', colour: 'Indigo & Alabaster', sku: 'OG-ADR-SM', stockQuantity: 5),
        ProductVariant(id: 'var-ad-ml', productId: 'prod-rtw-adire-robe', size: 'M / L', colour: 'Indigo & Alabaster', sku: 'OG-ADR-ML', stockQuantity: 4),
      ],
    ),

    // 8. CUSTOM: Bespoke Royal Ceremonial Ensemble
    Product(
      id: 'prod-custom-royal-ensemble-1',
      name: 'Bespoke Royal Ceremonial Ensemble',
      slug: 'bespoke-royal-ceremonial-ensemble',
      shortDescription: 'One-of-a-kind haute couture design personalized by our master designer.',
      description:
          'A collaborative masterpiece created between client and designer. Includes private sketch consultation, personalized fabric selection (heritage lace, bullion embroidery, woven silks), muslin toile fitting, and final salon fitting in Abuja/Lagos or private delivery.',
      productType: ProductType.custom,
      basePrice: 750000.0,
      materials: 'Hand-selected client textiles, pure gold bullion thread, French lace.',
      careInstructions: 'Archive preservation casing provided.',
      productionTimeDays: 30,
      deliveryEstimate: '4 – 6 Weeks Collaborative Couture Creation',
      isFeatured: true,
      images: const [
        ProductImage(
          id: 'img-custom-1',
          productId: 'prod-custom-royal-ensemble-1',
          imageUrl: 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?q=80&w=900&h=1200&auto=format&fit=crop',
          isPrimary: true,
        ),
      ],
      variants: const [
        ProductVariant(id: 'var-c1', productId: 'prod-custom-royal-ensemble-1', size: 'Bespoke Individual', colour: 'Custom Palette', sku: 'OG-BESPOKE', stockQuantity: 99),
      ],
    ),

    // 9. ACCESSORY: Benin Bullion Cuff
    Product(
      id: 'prod-acc-gold-cuff-1',
      name: 'Hand-Chiseled Bullion Architectural Cuff',
      slug: 'hand-chiseled-bullion-architectural-cuff',
      shortDescription: 'Sculptural 24k gold-plated brass cuff hand-chiseled with Benin court motifs.',
      description:
          'Created in collaboration with master metalsmiths, this heavyweight statement cuff features engraved architectural lines and an ergonomic contour for all-day comfort.',
      productType: ProductType.accessory,
      basePrice: 65000.0,
      materials: '24k Gold-Plated Jewelers Brass, anti-tarnish protective micro-coating.',
      careInstructions: 'Wipe gently with micro-fiber cloth after wearing. Keep away from water and perfume.',
      deliveryEstimate: '1 – 3 Business Days Express Shipping',
      isFeatured: false,
      images: const [
        ProductImage(
          id: 'img-cuff-1',
          productId: 'prod-acc-gold-cuff-1',
          imageUrl: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?q=80&w=900&h=1200&auto=format&fit=crop',
          isPrimary: true,
        ),
      ],
      variants: const [
        ProductVariant(id: 'var-acc-1', productId: 'prod-acc-gold-cuff-1', size: 'One Size (Adjustable)', colour: 'Polished Gold', sku: 'OG-ACC-CUFF-G', stockQuantity: 15),
      ],
    ),
  ];

  Future<List<Product>> getPublishedProducts() async {
    try {
      final res = await _client
          .from('products')
          .select('*, product_images(*), product_variants(*)')
          .eq('is_published', true)
          .eq('is_archived', false)
          .order('sort_order', ascending: true);

      final list = (res as List<dynamic>)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .where((p) => p.images.isNotEmpty && p.primaryImageUrl.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}

    // DEMO-SEED: return pitch products only when demo enabled.
    if (!DemoConfig.enabled) return [];
    return _defaultProducts;
  }

  Future<List<Product>> getAllProductsAdmin() async {
    try {
      final res = await _client
          .from('products')
          .select('*, product_images(*), product_variants(*)')
          .order('created_at', ascending: false);

      final list = (res as List<dynamic>).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}

    // DEMO-SEED: admin fallback shares same pitch list.
    if (!DemoConfig.enabled) return [];
    return _defaultProducts;
  }

  Future<Product?> getProductBySlug(String slug) async {
    try {
      final res = await _client
          .from('products')
          .select('*, product_images(*), product_variants(*)')
          .eq('slug', slug)
          .maybeSingle();

      if (res != null) {
        return Product.fromJson(res);
      }
    } catch (_) {}

    final list = await getPublishedProducts();
    return list.firstWhere((p) => p.slug == slug, orElse: () => list.first);
  }

  Future<Product> createProduct(Product product) async {
    final payload = product.toJson();
    payload.remove('id');
    final res = await _client.from('products').insert(payload).select().single();
    return Product.fromJson(res);
  }

  Future<void> updateProduct(Product product) async {
    await _client.from('products').update(product.toJson()).eq('id', product.id);
  }

  Future<void> archiveProduct(String id, bool isArchived) async {
    await _client.from('products').update({'is_archived': isArchived}).eq('id', id);
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(Supabase.instance.client);
});

final allPublishedProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productsRepositoryProvider).getPublishedProducts();
});

final adminProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productsRepositoryProvider).getAllProductsAdmin();
});

class ShopFilterNotifier extends Notifier<ShopFilterState> {
  @override
  ShopFilterState build() => const ShopFilterState();

  void setCategory(String? cat) => state = state.copyWith(category: cat, clearCategory: cat == null, page: 1);
  void setCollection(String? col) => state = state.copyWith(collection: col, clearCollection: col == null, page: 1);
  void setProductType(ProductType? type) => state = state.copyWith(productType: type, clearProductType: type == null, page: 1);
  void setSize(String? size) => state = state.copyWith(size: size, clearSize: size == null, page: 1);
  void setColour(String? colour) => state = state.copyWith(colour: colour, clearColour: colour == null, page: 1);
  void setPriceRange(double? min, double? max) => state = state.copyWith(minPrice: min, maxPrice: max, page: 1);
  void setInStockOnly(bool inStock) => state = state.copyWith(inStockOnly: inStock, page: 1);
  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query, page: 1);
    if (query != null && query.trim().isNotEmpty) {
      ref.read(analyticsServiceProvider).trackSearchQuery(query.trim());
    }
  }
  void setSortOption(ShopSortOption sort) => state = state.copyWith(sortOption: sort, page: 1);
  void setPage(int page) => state = state.copyWith(page: page);
  void resetFilters() => state = const ShopFilterState();
}

final shopFilterProvider = NotifierProvider<ShopFilterNotifier, ShopFilterState>(() {
  return ShopFilterNotifier();
});

final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(allPublishedProductsProvider);
  final filter = ref.watch(shopFilterProvider);

  return productsAsync.whenData((products) {
    var list = products.toList();

    // 1. Product Type filter
    if (filter.productType != null) {
      list = list.where((p) => p.productType == filter.productType).toList();
    }

    // 2. Collection filter
    if (filter.collection != null && filter.collection!.isNotEmpty) {
      list = list.where((p) => p.collectionId == filter.collection || p.collectionName == filter.collection).toList();
    }

    // 3. Category filter
    if (filter.category != null && filter.category!.isNotEmpty) {
      list = list.where((p) => p.categoryId == filter.category || p.categoryName == filter.category).toList();
    }

    // 4. Size filter
    if (filter.size != null && filter.size!.isNotEmpty) {
      list = list.where((p) => p.availableSizes.any((s) => s.toLowerCase().contains(filter.size!.toLowerCase()))).toList();
    }

    // 5. Colour filter
    if (filter.colour != null && filter.colour!.isNotEmpty) {
      list = list.where((p) => p.availableColours.any((c) => c.toLowerCase().contains(filter.colour!.toLowerCase()))).toList();
    }

    // 6. Price filter
    if (filter.minPrice != null) {
      list = list.where((p) => p.basePrice >= filter.minPrice!).toList();
    }
    if (filter.maxPrice != null) {
      list = list.where((p) => p.basePrice <= filter.maxPrice!).toList();
    }

    // 7. In stock only
    if (filter.inStockOnly) {
      list = list.where((p) => p.inStock).toList();
    }

    // 8. Search query
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = filter.searchQuery!.trim().toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q) || (p.description?.toLowerCase().contains(q) ?? false)).toList();
    }

    // 9. Sorting
    switch (filter.sortOption) {
      case ShopSortOption.featured:
        list.sort((a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0));
        break;
      case ShopSortOption.newest:
        break; // original order
      case ShopSortOption.priceAsc:
        list.sort((a, b) => a.basePrice.compareTo(b.basePrice));
        break;
      case ShopSortOption.priceDesc:
        list.sort((a, b) => b.basePrice.compareTo(a.basePrice));
        break;
    }

    return list;
  });
});

final paginatedProductsProvider = Provider<AsyncValue<PaginatedProducts>>((ref) {
  final filteredAsync = ref.watch(filteredProductsProvider);
  final filter = ref.watch(shopFilterProvider);

  return filteredAsync.whenData((products) {
    final totalCount = products.length;
    final startIndex = (filter.page - 1) * filter.pageSize;
    final clampedStart = startIndex.clamp(0, totalCount);
    final clampedEnd = (clampedStart + filter.pageSize).clamp(0, totalCount);
    final pageItems = products.sublist(clampedStart, clampedEnd);

    return PaginatedProducts(
      items: pageItems,
      totalCount: totalCount,
      page: filter.page,
      pageSize: filter.pageSize,
    );
  });
});

