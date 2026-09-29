import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';
import 'package:ochanya_gili/features/account/data/customer_account_repository.dart';
import 'package:ochanya_gili/features/account/domain/models/customer_account_models.dart';
import 'package:ochanya_gili/features/cart/presentation/providers/cart_provider.dart';

class CustomerWishlistScreen extends ConsumerWidget {
  const CustomerWishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: userAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: colors.primaryText)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text('Please sign in to view your saved looks.',
                  style: TextStyle(color: colors.primaryText)),
            );
          }

          final wishlistAsync = ref.watch(customerWishlistProvider(user.id));

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CURATED SELECTION',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 2.5,
                                color: colors.accentVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Saved Looks & Wishlist',
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colors.primaryText,
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton(
                          onPressed: () => context.go('/shop'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primaryText,
                            side: BorderSide(color: colors.border),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                          ),
                          child: const Text(
                            'EXPLORE SHOP',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    wishlistAsync.when(
                      loading: () => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: CircularProgressIndicator(
                              color: colors.primaryText),
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Text('Error loading wishlist: $e',
                            style: TextStyle(color: colors.error)),
                      ),
                      data: (items) {
                        if (items.isEmpty) {
                          return _buildEmptyState(context, colors);
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 20,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            return _buildWishlistCard(
                                context, ref, items[index], colors, user.id);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColorTokens colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 48, color: colors.secondaryText),
          const SizedBox(height: 16),
          Text(
            'Your Wishlist is Empty',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save your favorite runway pieces, bespoke inspirations, and made-to-order garments.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.secondaryText),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/collections'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
            child: const Text(
              'BROWSE COLLECTIONS',
              style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistCard(
    BuildContext context,
    WidgetRef ref,
    WishlistItem item,
    AppColorTokens colors,
    String userId,
  ) {
    final product = item.product;
    final currencyFormat =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    final imageUrl = product?.images.isNotEmpty ?? false
        ? product!.images.first.imageUrl
        : null;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Container
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: colors.surfaceVariant,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Icon(Icons.image_outlined,
                                size: 40, color: colors.secondaryText),
                          ),
                        )
                      : Center(
                          child: Icon(Icons.checkroom,
                              size: 40, color: colors.secondaryText),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(Icons.close, color: colors.primaryText, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surface.withValues(alpha: 0.85),
                      padding: const EdgeInsets.all(6),
                    ),
                    onPressed: () async {
                      final repo = ref.read(customerAccountRepositoryProvider);
                      await repo.removeFromWishlist(userId, item.productId);
                      ref.invalidate(customerWishlistProvider(userId));
                    },
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? 'Atelier Garment',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product != null
                      ? currencyFormat.format(product.basePrice)
                      : 'Price on Request',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.accentVariant,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: product == null
                        ? null
                        : () {
                            ref
                                .read(cartNotifierProvider.notifier)
                                .addItem(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                action: SnackBarAction(
                                  label: 'VIEW BAG',
                                  onPressed: () => context.go('/cart'),
                                ),
                              ),
                            );
                          },
                    child: const Text(
                      'ADD TO BAG',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
