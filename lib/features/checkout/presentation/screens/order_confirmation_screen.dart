import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/orders/data/orders_repository.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  final String orderNumber;

  const OrderConfirmationScreen({super.key, required this.orderNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final orderAsync = ref.watch(orderDetailProvider(orderNumber));
    final currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: orderAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: colors.primaryText),
              ),
              error: (err, _) => Center(
                child: Text('Error loading order confirmation: $err', style: TextStyle(color: colors.error)),
              ),
              data: (order) {
                if (order == null) {
                  return Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: colors.success),
                      const SizedBox(height: 24),
                      Text('THANK YOU FOR YOUR ORDER', style: TextStyle(fontFamily: 'Playfair Display', fontSize: 24, color: colors.primaryText)),
                      const SizedBox(height: 8),
                      Text('Order #$orderNumber has been confirmed.', style: TextStyle(color: colors.secondaryText)),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryText,
                          foregroundColor: colors.onAccent,
                        ),
                        onPressed: () => context.go('/shop'),
                        child: const Text('CONTINUE SHOPPING'),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Atelier Seal
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.success.withValues(alpha: 0.1),
                        border: Border.all(color: colors.success, width: 2),
                      ),
                      child: Icon(Icons.check, size: 36, color: colors.success),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'ORDER CONFIRMED',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 28,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your commission has been received and scheduled for atelier production.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.secondaryText, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Order Number & Status Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('REFERENCE: ', style: TextStyle(color: colors.secondaryText, fontSize: 12, letterSpacing: 1.0)),
                          Text(order.orderNumber, style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText, fontSize: 13, letterSpacing: 1.0)),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            color: colors.success.withValues(alpha: 0.15),
                            child: Text(
                              order.status.displayName.toUpperCase(),
                              style: TextStyle(color: colors.success, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Dossier Container
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('COMMISSION DETAILS', style: TextStyle(fontSize: 12, letterSpacing: 2.0, fontWeight: FontWeight.bold, color: colors.primaryText)),
                          const SizedBox(height: 16),
                          Divider(color: colors.border),
                          const SizedBox(height: 16),

                          // Line Items
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: order.items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final item = order.items[idx];
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.productName, style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText, fontSize: 14)),
                                        if (item.variantLabel != null)
                                          Text(item.variantLabel!, style: TextStyle(color: colors.secondaryText, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Text('${item.quantity} × ${currency.format(item.unitPrice)}', style: TextStyle(color: colors.primaryText, fontSize: 13)),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Divider(color: colors.border),
                          const SizedBox(height: 16),

                          // Pricing
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal', style: TextStyle(color: colors.secondaryText, fontSize: 13)),
                              Text(currency.format(order.subtotal), style: TextStyle(color: colors.primaryText, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Delivery & Courier', style: TextStyle(color: colors.secondaryText, fontSize: 13)),
                              Text(order.deliveryFee == 0 ? 'Complimentary' : currency.format(order.deliveryFee), style: TextStyle(color: colors.primaryText, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(color: colors.border),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TOTAL PAID (PAYSTACK)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.primaryText, letterSpacing: 1.0)),
                              Text(currency.format(order.total), style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20, fontWeight: FontWeight.bold, color: colors.primaryText)),
                            ],
                          ),

                          if (order.deliveryAddress != null) ...[
                            const SizedBox(height: 32),
                            Text('DELIVERY DESTINATION', style: TextStyle(fontSize: 11, letterSpacing: 2.0, fontWeight: FontWeight.bold, color: colors.primaryText)),
                            const SizedBox(height: 8),
                            Text(order.deliveryAddress!.fullName, style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(order.deliveryAddress!.formattedAddress, style: TextStyle(color: colors.secondaryText, fontSize: 13, height: 1.5)),
                            Text('Tel: ${order.deliveryAddress!.phone}', style: TextStyle(color: colors.secondaryText, fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primaryText,
                            side: BorderSide(color: colors.primaryText),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          onPressed: () => context.go('/shop'),
                          child: const Text('CONTINUE SHOPPING', style: TextStyle(letterSpacing: 1.5, fontSize: 11)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryText,
                            foregroundColor: colors.onAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          onPressed: () => context.go('/account/orders'),
                          child: const Text('VIEW ORDER TIMELINE', style: TextStyle(letterSpacing: 1.5, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
