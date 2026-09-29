import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/core/constants/app_breakpoints.dart';
import 'package:ochanya_gili/core/seo/seo_metadata.dart';
import 'package:ochanya_gili/core/seo/seo_service.dart';
import 'package:ochanya_gili/core/services/responsive_image_service.dart';
import 'package:ochanya_gili/features/shop/data/products_repository.dart';
import 'package:ochanya_gili/features/shop/domain/models/product.dart';
import 'package:ochanya_gili/features/shop/domain/models/shop_filter_state.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/footer.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(seoServiceProvider).apply(SeoMetadata.shop());
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final paginatedProductsAsync = ref.watch(paginatedProductsProvider);
    final filterState = ref.watch(shopFilterProvider);
    final filterNotifier = ref.read(shopFilterProvider.notifier);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= AppBreakpoints.desktop;
    final isMobile = screenWidth < AppBreakpoints.tablet;

    final currencyFormatter = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Scaffold(
      endDrawer: isDesktop ? null : _FilterDrawer(colors: colors),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20.0 : 64.0,
                vertical: isMobile ? 32.0 : 56.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editorial Shop Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ATELIER CATALOGUE',
                          style: TextStyle(
                            color: colors.accentVariant,
                            fontSize: 12,
                            letterSpacing: 3.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The Shop',
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: isMobile ? 32 : 44,
                            color: colors.primaryText,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    if (!isDesktop)
                      Builder(
                        builder: (context) => OutlinedButton.icon(
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
                          icon: const Icon(Icons.tune, size: 16),
                          label: const Text('FILTER', style: TextStyle(letterSpacing: 1.5, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.primaryText),
                            foregroundColor: colors.primaryText,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),

                // Product Type Quick Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TypeFilterChip(
                        label: 'ALL CREATIONS',
                        isSelected: filterState.productType == null,
                        onTap: () => filterNotifier.setProductType(null),
                        colors: colors,
                      ),
                      _TypeFilterChip(
                        label: 'READY-TO-WEAR',
                        isSelected: filterState.productType == ProductType.readyToWear,
                        onTap: () => filterNotifier.setProductType(ProductType.readyToWear),
                        colors: colors,
                      ),
                      _TypeFilterChip(
                        label: 'MADE-TO-ORDER',
                        isSelected: filterState.productType == ProductType.madeToOrder,
                        onTap: () => filterNotifier.setProductType(ProductType.madeToOrder),
                        colors: colors,
                      ),
                      _TypeFilterChip(
                        label: 'BESPOKE COUTURE',
                        isSelected: filterState.productType == ProductType.custom,
                        onTap: () => filterNotifier.setProductType(ProductType.custom),
                        colors: colors,
                      ),
                      _TypeFilterChip(
                        label: 'ACCESSORIES',
                        isSelected: filterState.productType == ProductType.accessory,
                        onTap: () => filterNotifier.setProductType(ProductType.accessory),
                        colors: colors,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Controls row: Item count & Sort dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    paginatedProductsAsync.when(
                      data: (paginated) => Text(
                        '${paginated.items.length} CREATIONS',
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 12,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      loading: () => const Text('LOADING...'),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<ShopSortOption>(
                        value: filterState.sortOption,
                        dropdownColor: colors.surface,
                        icon: Icon(Icons.keyboard_arrow_down_sharp, color: colors.primaryText, size: 18),
                        style: TextStyle(color: colors.primaryText, fontSize: 13, letterSpacing: 1.0),
                        items: ShopSortOption.values.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s.displayName));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) filterNotifier.setSortOption(val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: colors.border),
                const SizedBox(height: 40),

                // Main Content (Desktop side filter + Grid, or full Grid)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isDesktop)
                      SizedBox(
                        width: 260,
                        child: _FilterSidebar(colors: colors),
                      ),
                    if (isDesktop) const SizedBox(width: 48),
                    Expanded(
                      child: paginatedProductsAsync.when(
                        data: (paginated) {
                          if (paginated.items.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 80.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 48, color: colors.secondaryText),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No designs match your criteria',
                                      style: TextStyle(
                                        fontFamily: 'Playfair Display',
                                        fontSize: 20,
                                        color: colors.primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: () => filterNotifier.resetFilters(),
                                      child: const Text('RESET ALL FILTERS'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final columns = isDesktop ? 3 : (isMobile ? 2 : 3);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: isMobile ? 16 : 32,
                                  mainAxisSpacing: isMobile ? 32 : 48,
                                  childAspectRatio: isMobile ? 0.62 : 0.68,
                                ),
                                itemCount: paginated.items.length,
                                itemBuilder: (context, index) {
                                  final product = paginated.items[index];
                                  return _ProductGridCard(
                                    product: product,
                                    colors: colors,
                                    currencyFormatter: currencyFormatter,
                                  );
                                },
                              ),
                              if (paginated.totalPages > 1) ...[
                                const SizedBox(height: 48),
                                _PaginationBar(
                                  paginated: paginated,
                                  onPageSelected: (p) => filterNotifier.setPage(p),
                                  colors: colors,
                                ),
                              ],
                            ],
                          );
                        },
                        loading: () => Center(
                          child: CircularProgressIndicator(color: colors.primaryText, strokeWidth: 1.5),
                        ),
                        error: (err, stack) => Center(
                          child: Text('Failed to load products: $err', style: TextStyle(color: colors.error)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      const Footer(),
    ],
  ),
),
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorTokens colors;

  const _TypeFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryText : Colors.transparent,
            border: Border.all(color: isSelected ? colors.primaryText : colors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? colors.onAccent : colors.primaryText,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final AppColorTokens colors;
  final NumberFormat currencyFormatter;

  const _ProductGridCard({
    required this.product,
    required this.colors,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/shop/${product.slug}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Type Badge
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: AdaptiveImage(
                    imageUrl: product.primaryImageUrl,
                    altText: '${product.name} — ${product.productType.displayName}',
                    fit: BoxFit.cover,
                    imageContext: ImageContext.card,
                  ),
                ),
                // Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: Colors.black.withValues(alpha: 0.75),
                    child: Text(
                      product.productType.displayName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Product Name
          Text(
            product.name,
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.primaryText,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Server-verified Price
          Text(
            currencyFormatter.format(product.basePrice),
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 14,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final PaginatedProducts paginated;
  final ValueChanged<int> onPageSelected;
  final AppColorTokens colors;

  const _PaginationBar({
    required this.paginated,
    required this.onPageSelected,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: paginated.hasPreviousPage
                ? () => onPageSelected(paginated.page - 1)
                : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: paginated.hasPreviousPage ? colors.primaryText : colors.border,
              ),
              foregroundColor: colors.primaryText,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('PREV', style: TextStyle(letterSpacing: 1.5, fontSize: 11)),
          ),
          const SizedBox(width: 16),
          ...List.generate(paginated.totalPages, (index) {
            final pageNum = index + 1;
            final isCurrent = pageNum == paginated.page;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => onPageSelected(pageNum),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCurrent ? colors.primaryText : Colors.transparent,
                    border: Border.all(
                      color: isCurrent ? colors.primaryText : colors.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$pageNum',
                    style: TextStyle(
                      color: isCurrent ? colors.onAccent : colors.primaryText,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: paginated.hasNextPage
                ? () => onPageSelected(paginated.page + 1)
                : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: paginated.hasNextPage ? colors.primaryText : colors.border,
              ),
              foregroundColor: colors.primaryText,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('NEXT', style: TextStyle(letterSpacing: 1.5, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _FilterSidebar extends ConsumerStatefulWidget {
  final AppColorTokens colors;

  const _FilterSidebar({required this.colors});

  @override
  ConsumerState<_FilterSidebar> createState() => _FilterSidebarState();
}

class _FilterSidebarState extends ConsumerState<_FilterSidebar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(shopFilterProvider).searchQuery ?? '',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final filter = ref.watch(shopFilterProvider);
    final notifier = ref.read(shopFilterProvider.notifier);

    // Keep controller in sync if cleared externally
    if (filter.searchQuery == null && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('FILTERS', style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            if (filter.hasActiveFilters)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  notifier.resetFilters();
                },
                child: const Text('CLEAR', style: TextStyle(fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Search catalogue input
        TextField(
          controller: _searchController,
          style: TextStyle(color: colors.primaryText, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search atelier...',
            hintStyle: TextStyle(color: colors.secondaryText, fontSize: 13),
            prefixIcon: Icon(Icons.search, size: 18, color: colors.secondaryText),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      notifier.setSearchQuery(null);
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: colors.primaryText),
            ),
          ),
          onSubmitted: (query) {
            notifier.setSearchQuery(query.isEmpty ? null : query);
          },
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('In Stock Only', style: TextStyle(color: colors.primaryText, fontSize: 13)),
          value: filter.inStockOnly,
          onChanged: (val) => notifier.setInStockOnly(val ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }
}

class _FilterDrawer extends ConsumerWidget {
  final AppColorTokens colors;

  const _FilterDrawer({required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: colors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _FilterSidebar(colors: colors),
        ),
      ),
    );
  }
}
