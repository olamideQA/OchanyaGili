import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/core/config/demo_config.dart';
import 'package:ochanya_gili/core/seo/seo_metadata.dart';
import 'package:ochanya_gili/core/seo/seo_service.dart';
import 'package:ochanya_gili/features/analytics/data/analytics_service.dart';
import 'package:ochanya_gili/features/account/data/customer_account_repository.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';
import 'package:ochanya_gili/features/cart/presentation/providers/cart_provider.dart';
import 'package:ochanya_gili/features/measurements/presentation/dialogs/select_or_enter_measurements_dialog.dart';
import 'package:ochanya_gili/features/shop/data/products_repository.dart';
import 'package:ochanya_gili/features/shop/data/recently_viewed_store.dart';
import 'package:ochanya_gili/features/shop/domain/models/product.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/footer.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String slug;

  const ProductDetailScreen({
    super.key,
    required this.slug,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  String? _selectedSize;
  String? _selectedColour;
  int _quantity = 1;
  bool _addedToBagFeedback = false;

  void _shareProduct(BuildContext context, Product product) {
    final url = 'https://ochanyagili.com/shop/${product.slug}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharable link copied to clipboard: $url'),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSizeGuide(BuildContext context, AppColorTokens colors, String guideText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ATELIER SIZE GUIDE', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 22, color: colors.primaryText)),
              const SizedBox(height: 16),
              Text(guideText, style: TextStyle(color: colors.secondaryText, fontSize: 15, height: 1.6)),
              const SizedBox(height: 24),
              Text('Standard UK / US / EU Conversion Chart:', style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('• Size XS — UK 6 / US 2 / EU 34 (Bust: 32", Waist: 25", Hip: 35")\n• Size S — UK 8 / US 4 / EU 36 (Bust: 34", Waist: 27", Hip: 37")\n• Size M — UK 10 / US 6 / EU 38 (Bust: 36", Waist: 29", Hip: 39")\n• Size L — UK 12 / US 8 / EU 40 (Bust: 38", Waist: 31", Hip: 41")\n• Size XL — UK 14 / US 10 / EU 42 (Bust: 40", Waist: 33", Hip: 43")', style: TextStyle(color: colors.secondaryText, height: 1.6)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  /// Returns true when the item landed in the bag (for Buy-Now redirect).
  Future<bool> _handleCta(Product product, BuildContext context) async {
    if (product.productType.isCustom) {
      // CUSTOM NEVER adds to bag directly — routes to Atelier custom wizard
      context.go('/create-your-look');
      return false;
    }

    if (product.productType.isMadeToOrder) {
      final user = ref.read(currentUserProvider).value;
      final result = await SelectOrEnterMeasurementsDialog.show(
        context,
        product: product,
        userId: user?.id,
      );

      if (result != null) {
        final (profileId, profileName) = result;
        _addToCart(
          product,
          measurementProfileId: profileId,
          measurementProfileName: profileName,
        );
        return true;
      }
      return false;
    }

    // Ready to wear or accessory
    _addToCart(product);
    return true;
  }

  Future<void> _handleBuyNow(Product product, BuildContext context) async {
    if (product.productType.isCustom) {
      context.go('/create-your-look');
      return;
    }
    final added = await _handleCta(product, context);
    if (added && context.mounted) context.go('/cart');
  }

  void _addToCart(
    Product product, {
    String? measurementProfileId,
    String? measurementProfileName,
  }) {
    ProductVariant? variant;
    if (product.variants.isNotEmpty) {
      try {
        variant = product.variants.firstWhere(
          (v) => (v.size == _selectedSize || _selectedSize == null) &&
                 (v.colour == _selectedColour || _selectedColour == null),
        );
      } catch (_) {
        variant = product.variants.first;
      }
    }

    ref.read(cartNotifierProvider.notifier).addItem(
      product,
      variant: variant,
      measurementProfileId: measurementProfileId,
      measurementProfileName: measurementProfileName,
      quantity: _quantity,
    );

    ref.read(analyticsServiceProvider).trackAddToCart(
      productId: product.id,
      name: product.name,
      price: product.basePrice,
      size: _selectedSize,
      colour: _selectedColour,
      quantity: _quantity,
    );

    setState(() => _addedToBagFeedback = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 768;

    final currencyFormatter = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Scaffold(
      body: Builder(
        builder: (context) {
          final productsAsync = ref.watch(allPublishedProductsProvider);
          return productsAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: colors.primaryText, strokeWidth: 1.5)),
            error: (err, _) => Center(child: Text('Failed to load creation', style: TextStyle(color: colors.error))),
            data: (products) {
              Product? product;
              try {
                product = products.firstWhere((p) => p.slug == widget.slug);
              } catch (_) {
                product = null;
              }
              if (product == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Creation not found', style: TextStyle(color: colors.primaryText, fontSize: 20)),
                      const SizedBox(height: 16),
                      TextButton(onPressed: () => context.go('/shop'), child: const Text('Back to Catalogue')),
                    ],
                  ),
                );
              }
              final current = product;
              final currentIndex = products.indexWhere((p) => p.slug == widget.slug);
              final next = products[(currentIndex + 1) % products.length];
              final related = products.where((p) => p.slug != widget.slug).take(4).toList();
              return _buildBody(context, ref, current, related, next, colors, isDesktop, isMobile, currencyFormatter);
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    Product product,
    List<Product> related,
    Product next,
    AppColorTokens colors,
    bool isDesktop,
    bool isMobile,
    NumberFormat currencyFormatter,
  ) {
          // DEMO-SEED: Unsplash fallback for pitch. Strip with DemoConfig.enabled=false.
          final images = product.images.isNotEmpty
              ? product.images
              : (DemoConfig.enabled
                  ? [
                      ProductImage(
                          id: 'demo-1',
                          productId: product.id,
                          imageUrl:
                              'https://gfobzdetjbqwrxnutrkj.supabase.co/storage/v1/object/public/products/nigerian_wedding_bride_white.jpg')
                    ]
                  : const <ProductImage>[]);

          final currentImage = images.isNotEmpty
              ? images[_selectedImageIndex < images.length ? _selectedImageIndex : 0].imageUrl
              : '';

          // Apply SEO Metadata for product + record recently-viewed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(seoServiceProvider).apply(
                  SeoMetadata.product(
                    name: product.name,
                    slug: product.slug,
                    description: product.description ?? product.shortDescription ?? '',
                    price: product.basePrice,
                    imageUrl: product.primaryImageUrl,
                    category: product.categoryName,
                    inStock: product.inStock,
                  ),
                );
            RecentlyViewedStore.record(product.slug);
            ref.read(analyticsServiceProvider).trackProductView(
                  productId: product.id,
                  name: product.name,
                  slug: product.slug,
                  price: product.basePrice,
                  category: product.categoryName,
                );
          });

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20.0 : 64.0,
                    vertical: isMobile ? 24.0 : 48.0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    // Ozinna-style breadcrumbs & NEXT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              InkWell(
                                onTap: () => context.go('/'),
                                child: Text('HOME', style: TextStyle(color: colors.accentVariant, fontSize: 12, letterSpacing: 1.5)),
                              ),
                              Text('/', style: TextStyle(color: colors.textMuted)),
                              InkWell(
                                onTap: () => context.go('/shop'),
                                child: Text('CATALOGUE', style: TextStyle(color: colors.accentVariant, fontSize: 12, letterSpacing: 1.5)),
                              ),
                              Text('/', style: TextStyle(color: colors.textMuted)),
                              Text(product.name.toUpperCase(),
                                  style: TextStyle(color: colors.textMuted, fontSize: 12, letterSpacing: 1.5)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/shop/${next.slug}'),
                          child: Text('NEXT >', style: TextStyle(color: colors.accentVariant, fontSize: 12, letterSpacing: 1.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Two column editorial product layout (Ozinna: thumbs left, image center, details right)
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (images.length > 1)
                            SizedBox(
                              width: 88,
                              child: Column(
                                children: [
                                  for (var i = 0; i < images.length; i++)
                                    GestureDetector(
                                      onTap: () => setState(() => _selectedImageIndex = i),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: i == _selectedImageIndex ? colors.primaryText : Colors.transparent,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: AspectRatio(
                                          aspectRatio: 3 / 4,
                                          child: CachedNetworkImage(
                                            imageUrl: images[i].imageUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(color: colors.surfaceVariant),
                                            errorWidget: (context, url, error) => Container(color: colors.surfaceVariant),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if (images.length > 1) const SizedBox(width: 20),
                          Expanded(
                            flex: 6,
                            child: _buildGallery(images, currentImage, colors, hideThumbs: images.length > 1),
                          ),
                          const SizedBox(width: 56),
                          // Right: Product Details & Branching CTAs
                          Expanded(
                            flex: 5,
                            child: _buildProductDossier(product, colors, currencyFormatter),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGallery(images, currentImage, colors),
                          const SizedBox(height: 36),
                          _buildProductDossier(product, colors, currencyFormatter),
                        ],
                      ),
                    const SizedBox(height: 64),
                    // YOU MAY ALSO LIKE (Ozinna-style)
                    if (related.isNotEmpty) ...[
                      Center(
                        child: Text('YOU MAY ALSO LIKE',
                            style: TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: isMobile ? 24 : 32,
                              letterSpacing: 2.0,
                              color: colors.primaryText,
                            )),
                      ),
                      const SizedBox(height: 32),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 4 : 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 32,
                          childAspectRatio: isMobile ? 0.65 : 0.74,
                        ),
                        itemCount: related.length,
                        itemBuilder: (context, index) {
                          final r = related[index];
                          return _RelatedCard(product: r, colors: colors, currencyFormatter: currencyFormatter);
                        },
                      ),
                      const SizedBox(height: 64),
                    ],
                    _RecentlyViewedSection(
                      currentSlug: product.slug,
                      colors: colors,
                      isMobile: isMobile,
                      currencyFormatter: currencyFormatter,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }

  Widget _buildGallery(List<ProductImage> images, String currentImage, AppColorTokens colors, {bool hideThumbs = false}) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRect(
              child: currentImage.isEmpty
                  ? Container(color: colors.surfaceVariant)
                  : CachedNetworkImage(
                      imageUrl: currentImage,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      placeholder: (context, url) => Container(color: colors.surfaceVariant),
                      errorWidget: (context, url, error) => Container(color: colors.surfaceVariant),
                    ),
            ),
          ),
        ),
        if (images.length > 1 && !hideThumbs) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedImageIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? colors.primaryText : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: images[index].imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductDossier(Product product, AppColorTokens colors, NumberFormat currencyFormatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: colors.accentVariant.withValues(alpha: 0.15),
          child: Text(
            product.productType.displayName.toUpperCase(),
            style: TextStyle(
              color: colors.accentVariant,
              fontSize: 11,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Vendor / atelier line (Ozinna-style gold vendor)
        Text(
          (product.collectionName ?? 'OCHANYA GILI ATELIER').toUpperCase(),
          style: TextStyle(
            color: colors.accentVariant,
            fontSize: 13,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Title
        Text(
          product.name,
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 32,
            color: colors.primaryText,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        // Server-verified price
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              currencyFormatter.format(product.basePrice),
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            if (product.compareAtPrice != null) ...[
              const SizedBox(width: 12),
              Text(
                currencyFormatter.format(product.compareAtPrice!),
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 16,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
            if (product.productType.isCustom) ...[
              const SizedBox(width: 8),
              Text(
                '(Starting Consultation Estimate)',
                style: TextStyle(color: colors.secondaryText, fontSize: 12),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        Divider(color: colors.border),
        const SizedBox(height: 24),

        // Description
        Text(
          product.description ?? product.shortDescription ?? '',
          style: TextStyle(color: colors.secondaryText, fontSize: 15, height: 1.7),
        ),
        const SizedBox(height: 28),

        // Size Selector (if variants exist)
        if (product.availableSizes.isNotEmpty && !product.productType.isCustom) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SELECT SIZE', style: TextStyle(color: colors.primaryText, fontSize: 11, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
              if (product.sizeGuide != null)
                InkWell(
                  onTap: () => _showSizeGuide(context, colors, product.sizeGuide!),
                  child: Text('SIZE GUIDE', style: TextStyle(color: colors.accentVariant, fontSize: 11, letterSpacing: 1.5, decoration: TextDecoration.underline)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: product.availableSizes.map((size) {
              final isSelected = size == _selectedSize;
              return InkWell(
                onTap: () => setState(() => _selectedSize = size),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primaryText : Colors.transparent,
                    border: Border.all(color: isSelected ? colors.primaryText : colors.border),
                  ),
                  child: Text(
                    size,
                    style: TextStyle(
                      color: isSelected ? colors.onAccent : colors.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Colour Selector (if variants exist)
        if (product.availableColours.isNotEmpty && !product.productType.isCustom) ...[
          Text('SELECT SHADE / PALETTE', style: TextStyle(color: colors.primaryText, fontSize: 11, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: product.availableColours.map((colour) {
              final isSelected = colour == _selectedColour;
              return InkWell(
                onTap: () => setState(() => _selectedColour = colour),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primaryText : Colors.transparent,
                    border: Border.all(color: isSelected ? colors.primaryText : colors.border),
                  ),
                  child: Text(
                    colour,
                    style: TextStyle(
                      color: isSelected ? colors.onAccent : colors.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Production & Delivery Estimate
        if (product.deliveryEstimate != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 18, color: colors.secondaryText),
                const SizedBox(width: 8),
                Text(product.deliveryEstimate!, style: TextStyle(color: colors.secondaryText, fontSize: 13)),
              ],
            ),
          ),

        // Added to bag feedback alert
        if (_addedToBagFeedback)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 24),
            color: colors.success.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.check, size: 16, color: colors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Added to Shopping Bag.', style: TextStyle(color: colors.success, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primaryText,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => context.go('/cart'),
                  child: const Text('VIEW BAG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),

        // === QTY STEPPER (Ozinna-style) ===
        if (!product.productType.isCustom) ...[
          Text('Qty', style: TextStyle(color: colors.primaryText, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            width: 180,
            decoration: BoxDecoration(border: Border.all(color: colors.border)),
            child: Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _quantity = (_quantity - 1).clamp(1, 99)),
                  child: const SizedBox(width: 48, height: 48, child: Icon(Icons.remove)),
                ),
                Expanded(
                  child: Center(
                    child: Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _quantity = (_quantity + 1).clamp(1, 99)),
                  child: const SizedBox(width: 48, height: 48, child: Icon(Icons.add)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // === TYPE-SPECIFIC CALL TO ACTION (Ozinna: Add to Cart + Buy Now + Wishlist) ===
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleCta(product, context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.primaryText),
                  foregroundColor: colors.primaryText,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: const Text('ADD TO CART', style: TextStyle(letterSpacing: 2.0, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleBuyNow(product, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: Text(
                  product.productType.isCustom ? 'BOOK CONSULTATION' : 'BUY NOW',
                  style: const TextStyle(letterSpacing: 2.0, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                border: Border.all(color: colors.border),
              ),
              child: IconButton(
                icon: Icon(Icons.favorite_border, color: colors.primaryText, size: 20),
                tooltip: 'Add to Wishlist',
                onPressed: () async {
                  final user = ref.read(currentUserProvider).value;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please log in to save to your wishlist.')),
                    );
                    return;
                  }
                  await ref.read(customerAccountRepositoryProvider).addToWishlist(user.id, product.id);
                  ref.read(analyticsServiceProvider).trackWishlistAdded(
                        productId: product.id,
                        name: product.name,
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${product.name} saved to your Wishlist.')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        Center(
          child: TextButton(
            onPressed: () => context.go('/cart'),
            child: Text('More payment options',
                style: TextStyle(color: colors.accentVariant, decoration: TextDecoration.underline)),
          ),
        ),
        const SizedBox(height: 8),
        // Share row (Ozinna-style)
        Row(
          children: [
            _ShareIcon(icon: Icons.close, tooltip: 'Share on X', colors: colors, onTap: () => _shareProduct(context, product)),
            const SizedBox(width: 12),
            _ShareIcon(icon: Icons.facebook, tooltip: 'Share on Facebook', colors: colors, onTap: () => _shareProduct(context, product)),
            const SizedBox(width: 12),
            _ShareIcon(icon: Icons.push_pin_outlined, tooltip: 'Pin it', colors: colors, onTap: () => _shareProduct(context, product)),
            const SizedBox(width: 12),
            _ShareIcon(icon: Icons.mail_outline, tooltip: 'Share via email', colors: colors, onTap: () => _shareProduct(context, product)),
          ],
        ),

        const SizedBox(height: 36),
        // Materials & Care Accordion
        if (product.materials != null) ...[
          Text('MATERIALS & FABRICATION', style: TextStyle(color: colors.primaryText, fontSize: 11, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(product.materials!, style: TextStyle(color: colors.secondaryText, fontSize: 14)),
          const SizedBox(height: 16),
        ],
        if (product.careInstructions != null) ...[
          Text('CARE INSTRUCTIONS', style: TextStyle(color: colors.primaryText, fontSize: 11, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(product.careInstructions!, style: TextStyle(color: colors.secondaryText, fontSize: 14)),
        ],
      ],
    );
  }
}

class _RecentlyViewedSection extends ConsumerWidget {
  final String currentSlug;
  final AppColorTokens colors;
  final bool isMobile;
  final NumberFormat currencyFormatter;
  const _RecentlyViewedSection({
    required this.currentSlug,
    required this.colors,
    required this.isMobile,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allPublishedProductsProvider);
    return FutureBuilder<List<String>>(
      future: RecentlyViewedStore.read(exclude: currentSlug),
      builder: (context, snapshot) {
        final slugs = snapshot.data ?? const <String>[];
        if (slugs.isEmpty) return const SizedBox.shrink();
        return productsAsync.when(
          data: (products) {
            final items = [
              for (final s in slugs)
                for (final p in products.where((p) => p.slug == s).take(1)) p
            ].take(4).toList();
            if (items.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                Center(
                  child: Text('RECENTLY VIEWED',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: isMobile ? 22 : 28,
                        letterSpacing: 2.0,
                        color: colors.primaryText,
                      )),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, i) => Container(
                      width: 200,
                      margin: EdgeInsets.only(right: i == items.length - 1 ? 0 : 20),
                      child: _RelatedCard(product: items[i], colors: colors, currencyFormatter: currencyFormatter),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, s) => const SizedBox.shrink(),
        );
      },
    );
  }
}

class _ShareIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final AppColorTokens colors;
  final VoidCallback onTap;
  const _ShareIcon({required this.icon, required this.tooltip, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(border: Border.all(color: colors.border)),
          child: Icon(icon, size: 18, color: colors.primaryText),
        ),
      ),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  final Product product;
  final AppColorTokens colors;
  final NumberFormat currencyFormatter;
  const _RelatedCard({required this.product, required this.colors, required this.currencyFormatter});

  @override
  Widget build(BuildContext context) {
    final hasSale = product.compareAtPrice != null && product.compareAtPrice! > product.basePrice;
    return InkWell(
      onTap: () => context.go('/shop/${product.slug}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: CachedNetworkImage(
                    imageUrl: product.primaryImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: colors.surfaceVariant),
                    errorWidget: (context, url, error) => Container(color: colors.surfaceVariant),
                  ),
                ),
                if (hasSale)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: colors.accentVariant,
                      child: const Text('SALE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(product.name.toUpperCase(),
              style: TextStyle(fontSize: 13, letterSpacing: 1.5, color: colors.primaryText, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(currencyFormatter.format(product.basePrice),
                  style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.w600)),
              if (hasSale) ...[
                const SizedBox(width: 8),
                Text(currencyFormatter.format(product.compareAtPrice!),
                    style: TextStyle(color: colors.textMuted, decoration: TextDecoration.lineThrough, fontSize: 13)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
