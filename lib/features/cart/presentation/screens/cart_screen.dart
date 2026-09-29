import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/analytics/data/analytics_service.dart';
import 'package:ochanya_gili/features/cart/presentation/providers/cart_provider.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/footer.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final cartState = ref.watch(cartNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);
    final currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return cartState.isEmpty
        ? _buildEmptyState(context, colors)
        : SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 64.0 : 20.0,
                    vertical: 40.0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Breadcrumb
                      Row(
                        children: [
                          InkWell(
                            onTap: () => context.go('/shop'),
                            child: Text('SHOP', style: TextStyle(color: colors.secondaryText, fontSize: 11, letterSpacing: 1.5)),
                          ),
                          Text('  /  ', style: TextStyle(color: colors.secondaryText, fontSize: 11)),
                          Text('SHOPPING BAG', style: TextStyle(color: colors.primaryText, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'YOUR ATELIER BAG',
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: isDesktop ? 36 : 28,
                          letterSpacing: 2.0,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${cartState.totalCount} ${cartState.totalCount == 1 ? "Creation" : "Creations"} selected for tailoring and dispatch.',
                        style: TextStyle(color: colors.secondaryText, fontSize: 14),
                      ),
                      const SizedBox(height: 40),

                      // Layout
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildItemsList(cartState, cartNotifier, colors, currency)),
                            const SizedBox(width: 48),
                            Expanded(flex: 2, child: _buildOrderSummary(cartState, colors, currency)),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildItemsList(cartState, cartNotifier, colors, currency),
                            const SizedBox(height: 40),
                            _buildOrderSummary(cartState, colors, currency),
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
      );
  }

  Widget _buildEmptyState(BuildContext context, AppColorTokens colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: colors.secondaryText),
            const SizedBox(height: 24),
            Text(
              'YOUR SHOPPING BAG IS EMPTY',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 24,
                letterSpacing: 2.0,
                color: colors.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Discover our runway collections, bespoke tailoring, and artisanal evening wear.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryText, fontSize: 15),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryText,
                foregroundColor: colors.onAccent,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: () => context.go('/shop'),
              child: const Text('EXPLORE CREATIONS', style: TextStyle(letterSpacing: 2.0, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(
    dynamic cartState,
    dynamic cartNotifier,
    AppColorTokens colors,
    NumberFormat currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cartState.items.length,
          separatorBuilder: (_, _) => Divider(color: colors.border, height: 48),
          itemBuilder: (context, index) {
            final item = cartState.items[index];
            final primaryImg = item.product.images.isNotEmpty ? item.product.images.first.imageUrl : '';

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artwork
                Container(
                  width: 110,
                  height: 140,
                  color: colors.surfaceVariant,
                  child: primaryImg.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: primaryImg,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const Icon(Icons.broken_image),
                        )
                      : null,
                ),
                const SizedBox(width: 24),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.product.name,
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.primaryText,
                              ),
                            ),
                          ),
                          Text(
                            currency.format(item.lineTotal),
                            style: TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.primaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (item.variant != null)
                        Text(
                          'Size: ${item.variant?.size ?? "Standard"}  |  Colour: ${item.variant?.colour ?? "Default"}',
                          style: TextStyle(color: colors.secondaryText, fontSize: 13),
                        ),
                      if (item.product.productType.isMadeToOrder) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          color: colors.accentVariant.withValues(alpha: 0.15),
                          child: Text(
                            'MADE TO ORDER  •  Fitted to: ${item.measurementProfileName ?? "Saved Anatomy Profile"}',
                            style: TextStyle(
                              color: colors.accentVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Controls
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: () => cartNotifier.updateQuantity(item.id, item.quantity - 1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('${item.quantity}', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () => cartNotifier.updateQuantity(item.id, item.quantity + 1),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: colors.secondaryText),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('REMOVE', style: TextStyle(fontSize: 11, letterSpacing: 1.0)),
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

        const SizedBox(height: 36),
        // Atelier Special Instructions
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ATELIER SPECIAL INSTRUCTIONS / NOTES', style: TextStyle(color: colors.primaryText, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add special tailoring requests, event deadline, or concierge instructions...',
                  hintStyle: TextStyle(color: colors.secondaryText, fontSize: 13),
                  border: OutlineInputBorder(borderSide: BorderSide(color: colors.border)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.border)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(
    dynamic cartState,
    AppColorTokens colors,
    NumberFormat currency,
  ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ORDER SUMMARY',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 18,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: colors.border),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: TextStyle(color: colors.secondaryText, fontSize: 14)),
              Text(
                currency.format(cartState.subtotal),
                style: TextStyle(color: colors.primaryText, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Atelier Shipping', style: TextStyle(color: colors.secondaryText, fontSize: 14)),
              Text('Calculated next', style: TextStyle(color: colors.secondaryText, fontSize: 13, fontStyle: FontStyle.italic)),
            ],
          ),
          if (cartState.hasMadeToOrderItems) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bespoke Anatomical Fitting', style: TextStyle(color: colors.secondaryText, fontSize: 14)),
                Text('COMPLIMENTARY', style: TextStyle(color: colors.accentVariant, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Divider(color: colors.border),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ESTIMATED TOTAL', style: TextStyle(color: colors.primaryText, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              Text(
                currency.format(cartState.subtotal),
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryText,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () {
              ref.read(analyticsServiceProvider).trackCheckoutStarted(
                total: cartState.total,
                itemCount: cartState.totalCount,
              );
              context.go('/checkout');
            },
            child: const Text('PROCEED TO CHECKOUT', style: TextStyle(letterSpacing: 2.0, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Secure Encrypted Checkout • Verified Atelier Dispatch',
              style: TextStyle(color: colors.secondaryText, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
