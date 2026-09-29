import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/orders/data/orders_repository.dart';
import 'package:ochanya_gili/features/orders/domain/models/order.dart';
import 'package:ochanya_gili/features/orders/presentation/widgets/atelier_timeline_widget.dart';

class OrderTimelineScreen extends ConsumerWidget {
  final String orderNumber;

  const OrderTimelineScreen({super.key, required this.orderNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final orderAsync = ref.watch(orderDetailProvider(orderNumber));
    final currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: colors.background,
      body: orderAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: colors.primaryText)),
        error: (err, _) => Center(child: Text('Error loading commission: $err', style: TextStyle(color: colors.error))),
        data: (order) {
          if (order == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Commission #$orderNumber not found.', style: TextStyle(color: colors.primaryText, fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/account/orders'),
                    child: const Text('BACK TO COMMISSIONS'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48.0 : 20.0,
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
                          onTap: () => context.go('/account/orders'),
                          child: Text('MY COMMISSIONS', style: TextStyle(color: colors.secondaryText, fontSize: 11, letterSpacing: 1.5)),
                        ),
                        Text('  /  ', style: TextStyle(color: colors.secondaryText, fontSize: 11)),
                        Text(order.orderNumber, style: TextStyle(color: colors.primaryText, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderNumber,
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: isDesktop ? 32 : 24,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.bold,
                                color: colors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Commission Authenticated on ${dateFormat.format(order.createdAt)}',
                              style: TextStyle(color: colors.secondaryText, fontSize: 13),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          color: colors.accentVariant.withValues(alpha: 0.15),
                          child: Text(
                            order.status.displayName.toUpperCase(),
                            style: TextStyle(
                              color: colors.accentVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Content layout
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Timeline & Pieces
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTimelineCard(order, colors),
                                const SizedBox(height: 36),
                                _buildPiecesDossier(order, colors, currency),
                              ],
                            ),
                          ),
                          const SizedBox(width: 40),
                          // Right: Summary & Concierge
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildOrderSummary(order, colors, currency),
                                const SizedBox(height: 24),
                                _buildDeliveryDetails(order, colors),
                                const SizedBox(height: 24),
                                _buildConciergeCard(context, colors),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildTimelineCard(order, colors),
                          const SizedBox(height: 32),
                          _buildPiecesDossier(order, colors, currency),
                          const SizedBox(height: 32),
                          _buildOrderSummary(order, colors, currency),
                          const SizedBox(height: 24),
                          _buildDeliveryDetails(order, colors),
                          const SizedBox(height: 24),
                          _buildConciergeCard(context, colors),
                        ],
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

  Widget _buildTimelineCard(AppOrder order, AppColorTokens colors) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ATELIER PROGRESSION TIMELINE',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: colors.primaryText,
                ),
              ),
              Icon(Icons.timeline, color: colors.accentVariant, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Every Ochanya Gili commission is crafted with precision. Follow your creation through each artisanal milestone.',
            style: TextStyle(color: colors.secondaryText, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 28),
          Divider(color: colors.border),
          const SizedBox(height: 28),

          // Visual Timeline Widget
          AtelierTimelineWidget(stages: order.timelineStages),
        ],
      ),
    );
  }

  Widget _buildPiecesDossier(AppOrder order, AppColorTokens colors, NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMMISSIONED CREATIONS (${order.items.length})',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: colors.border),
          const SizedBox(height: 20),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (_, _) => Divider(color: colors.border, height: 36),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 90,
                    color: colors.surfaceVariant,
                    child: const Icon(Icons.checkroom, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (item.variantLabel != null)
                          Text(
                            'Specification: ${item.variantLabel}',
                            style: TextStyle(color: colors.secondaryText, fontSize: 13),
                          ),
                        if (item.customOptions != null && item.customOptions!['measurement_profile_name'] != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            color: colors.accentVariant.withValues(alpha: 0.15),
                            child: Text(
                              'TAILORED TO: ${item.customOptions!["measurement_profile_name"]}',
                              style: TextStyle(color: colors.accentVariant, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          '${item.quantity} × ${currency.format(item.unitPrice)}',
                          style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currency.format(item.totalPrice),
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.primaryText,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(AppOrder order, AppColorTokens colors, NumberFormat currency) {
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
            'FINANCIAL STATEMENT',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: colors.border),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Atelier Subtotal', style: TextStyle(color: colors.secondaryText, fontSize: 13)),
              Text(currency.format(order.subtotal), style: TextStyle(color: colors.primaryText, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Courier & Insurance', style: TextStyle(color: colors.secondaryText, fontSize: 13)),
              Text(order.deliveryFee == 0 ? 'Complimentary' : currency.format(order.deliveryFee), style: TextStyle(color: colors.primaryText, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colors.border),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL COMMISSION', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText, fontSize: 13)),
              Text(
                currency.format(order.total),
                style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20, fontWeight: FontWeight.bold, color: colors.primaryText),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            color: colors.surfaceVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment Gateway', style: TextStyle(color: colors.secondaryText, fontSize: 11)),
                    Text(order.paymentProvider?.toUpperCase() ?? 'PAYSTACK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: colors.primaryText)),
                  ],
                ),
                if (order.paymentReference != null) ...[
                  const SizedBox(height: 4),
                  Text('Ref: ${order.paymentReference}', style: TextStyle(color: colors.secondaryText, fontSize: 10)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDetails(AppOrder order, AppColorTokens colors) {
    final addr = order.deliveryAddress;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DELIVERY DESTINATION',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: colors.border),
          const SizedBox(height: 16),

          if (addr != null) ...[
            Text(addr.fullName, style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText, fontSize: 14)),
            const SizedBox(height: 4),
            Text(addr.formattedAddress, style: TextStyle(color: colors.secondaryText, fontSize: 13, height: 1.5)),
            const SizedBox(height: 4),
            Text('Contact: ${addr.phone}', style: TextStyle(color: colors.secondaryText, fontSize: 13)),
          ] else ...[
            Text('Salon Collection / Atelier Maitama Abuja', style: TextStyle(color: colors.secondaryText, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildConciergeCard(BuildContext context, AppColorTokens colors) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.support_agent, color: colors.accentVariant, size: 20),
              const SizedBox(width: 8),
              Text('ATELIER CONCIERGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5, color: colors.primaryText)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Need to schedule a private fitting at our Maitama salon or request custom styling notes for this commission?',
            style: TextStyle(color: colors.secondaryText, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primaryText,
              side: BorderSide(color: colors.primaryText),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () => context.go('/account/appointments'),
            child: const Text('SCHEDULE SALON FITTING', style: TextStyle(fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
