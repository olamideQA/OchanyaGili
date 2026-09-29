import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/cart/presentation/providers/cart_provider.dart';

class CartDrawer extends ConsumerWidget {
  const CartDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final cartState = ref.watch(cartNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    final currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Drawer(
      backgroundColor: colors.surface,
      elevation: 16,
      width: 440,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SHOPPING BAG (${cartState.totalCount})',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: colors.primaryText,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.primaryText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(color: colors.border, height: 1),

            // Cart Items
            Expanded(
              child: cartState.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 48, color: colors.secondaryText),
                            const SizedBox(height: 16),
                            Text(
                              'Your bag is currently empty',
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 18,
                                color: colors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Explore our seasonal creations and artisanal tailoring.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.secondaryText, fontSize: 14),
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.primaryText,
                                side: BorderSide(color: colors.primaryText),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.go('/shop');
                              },
                              child: const Text('EXPLORE THE CATALOGUE', style: TextStyle(letterSpacing: 1.5, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: cartState.items.length,
                      separatorBuilder: (_, _) => Divider(color: colors.border, height: 32),
                      itemBuilder: (context, index) {
                        final item = cartState.items[index];
                        final primaryImg = item.product.images.isNotEmpty
                            ? item.product.images.first.imageUrl
                            : '';

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            Container(
                              width: 80,
                              height: 100,
                              color: colors.surfaceVariant,
                              child: primaryImg.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: primaryImg,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => const Icon(Icons.broken_image),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Playfair Display',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colors.primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (item.variant != null)
                                    Text(
                                      '${item.variant?.size ?? ""} • ${item.variant?.colour ?? ""}'.trim(),
                                      style: TextStyle(color: colors.secondaryText, fontSize: 12),
                                    ),
                                  if (item.product.productType.isMadeToOrder) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colors.accentVariant.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Text(
                                        'BESPOKE: ${item.measurementProfileName ?? "ANATOMICAL PROFILE"}',
                                        style: TextStyle(color: colors.accentVariant, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    currency.format(item.lineTotal),
                                    style: TextStyle(
                                      color: colors.primaryText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Quantity & Remove
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: colors.border),
                                        ),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () => cartNotifier.updateQuantity(item.id, item.quantity - 1),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Text('–', style: TextStyle(color: colors.primaryText)),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Text('${item.quantity}', style: TextStyle(color: colors.primaryText, fontSize: 12)),
                                            ),
                                            InkWell(
                                              onTap: () => cartNotifier.updateQuantity(item.id, item.quantity + 1),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Text('+', style: TextStyle(color: colors.primaryText)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, size: 18, color: colors.secondaryText),
                                        onPressed: () => cartNotifier.removeItem(item.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),

            // Footer
            if (cartState.isNotEmpty) ...[
              Divider(color: colors.border, height: 1),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SUBTOTAL',
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 12,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          currency.format(cartState.subtotal),
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Taxes, bespoke tailoring, and dispatch calculated at checkout.',
                      style: TextStyle(color: colors.secondaryText, fontSize: 11),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryText,
                        foregroundColor: colors.onAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/checkout');
                      },
                      child: const Text(
                        'PROCEED TO ATELIER CHECKOUT',
                        style: TextStyle(fontSize: 12, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: colors.primaryText),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/cart');
                      },
                      child: const Text('VIEW DETAILED BAG', style: TextStyle(letterSpacing: 1.5, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
