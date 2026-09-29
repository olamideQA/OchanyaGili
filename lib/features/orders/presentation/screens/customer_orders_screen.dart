import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';
import 'package:ochanya_gili/features/orders/data/orders_repository.dart';
import 'package:ochanya_gili/features/orders/domain/models/order.dart';

enum OrderFilterTab {
  all('ALL COMMISSIONS'),
  active('ACTIVE IN ATELIER'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  final String label;
  const OrderFilterTab(this.label);
}

class CustomerOrdersScreen extends ConsumerStatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  ConsumerState<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends ConsumerState<CustomerOrdersScreen> {
  OrderFilterTab _selectedTab = OrderFilterTab.all;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final user = ref.watch(currentUserProvider).value;
    final currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final dateFormat = DateFormat('MMMM d, yyyy');

    if (user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please sign in to view your bespoke orders.', style: TextStyle(color: colors.primaryText)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('SIGN IN'),
            ),
          ],
        ),
      );
    }

    final ordersAsync = ref.watch(userOrdersProvider(user.id));

    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'MY ATELIER COMMISSIONS',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 28,
                letterSpacing: 2.0,
                color: colors.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Monitor the tailoring progression, anatomical fittings, and delivery status of your garments.',
              style: TextStyle(color: colors.secondaryText, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: OrderFilterTab.values.map((tab) {
                  final isSelected = tab == _selectedTab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: ChoiceChip(
                      label: Text(tab.label),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedTab = tab),
                      selectedColor: colors.primaryText,
                      backgroundColor: colors.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? colors.onAccent : colors.primaryText,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(color: isSelected ? colors.primaryText : colors.border),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 36),

            // Orders List
            ordersAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: colors.primaryText)),
              error: (err, _) => Center(child: Text('Error loading commissions: $err', style: TextStyle(color: colors.error))),
              data: (orders) {
                final filtered = orders.where((order) {
                  switch (_selectedTab) {
                    case OrderFilterTab.all:
                      return true;
                    case OrderFilterTab.active:
                      return order.status.isActive;
                    case OrderFilterTab.completed:
                      return order.status.isCompleted;
                    case OrderFilterTab.cancelled:
                      return order.status.isCancelled;
                  }
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(context, colors);
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    return _buildOrderCard(order, colors, currency, dateFormat, context);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColorTokens colors) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: colors.secondaryText),
            const SizedBox(height: 16),
            Text(
              'NO COMMISSIONS FOUND',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 18,
                letterSpacing: 1.5,
                color: colors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You currently have no commissions under this filter.',
              style: TextStyle(color: colors.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryText,
                side: BorderSide(color: colors.primaryText),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: () => context.go('/shop'),
              child: const Text('EXPLORE THE ATELIER COLLECTION', style: TextStyle(letterSpacing: 1.5, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    AppOrder order,
    AppColorTokens colors,
    NumberFormat currency,
    DateFormat dateFormat,
    BuildContext context,
  ) {
    Color statusColor;
    if (order.status.isCompleted || order.status == OrderStatus.paid) {
      statusColor = colors.success;
    } else if (order.status.isCancelled) {
      statusColor = colors.error;
    } else {
      statusColor = colors.accentVariant;
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: colors.surfaceVariant,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMMISSION NUMBER',
                      style: TextStyle(color: colors.secondaryText, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.orderNumber,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.primaryText, letterSpacing: 1.0),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'COMMISSION DATE',
                      style: TextStyle(color: colors.secondaryText, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(order.createdAt),
                      style: TextStyle(color: colors.secondaryText, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items & Details
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnails preview
                if (order.items.isNotEmpty)
                  Row(
                    children: order.items.take(3).map((item) {
                      return Container(
                        width: 60,
                        height: 75,
                        margin: const EdgeInsets.only(right: 12),
                        color: colors.surfaceVariant,
                        child: const Icon(Icons.checkroom, size: 24),
                      );
                    }).toList(),
                  ),
                const SizedBox(width: 12),

                // Summary
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.items.map((i) => i.productName).join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.primaryText),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            color: statusColor.withValues(alpha: 0.15),
                            child: Text(
                              order.status.displayName.toUpperCase(),
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${order.items.length} ${order.items.length == 1 ? "Piece" : "Pieces"}',
                            style: TextStyle(color: colors.secondaryText, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Total & Action Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(order.total),
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryText,
                        foregroundColor: colors.onAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      onPressed: () {
                        context.go('/account/orders/${order.orderNumber}');
                      },
                      child: const Text('VIEW TIMELINE & DOSSIER', style: TextStyle(fontSize: 11, letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
