import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/orders/data/orders_repository.dart';
import 'package:ochanya_gili/features/orders/domain/models/order.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  OrderStatus? _selectedStatusFilter;
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openStatusDialog(BuildContext context, AppOrder order, AppColorTokens colors) {
    OrderStatus targetStatus = order.status;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UPDATE COMMISSION STATUS',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Order: ${order.orderNumber}', style: TextStyle(color: colors.secondaryText, fontSize: 13)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select New Atelier Stage:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primaryText),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<OrderStatus>(
                        initialValue: targetStatus,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: OrderStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => targetStatus = val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Atelier Log Note / Craftsman Observation (Recorded in Immutable History):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primaryText),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Muslin toile fitted at Maitama salon. Adjusting bustline dart by 0.5cm.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text('Cancel', style: TextStyle(color: colors.secondaryText)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryText,
                    foregroundColor: colors.onAccent,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    try {
                      final repo = ref.read(ordersRepositoryProvider);
                      await repo.updateOrderStatus(
                        order.id,
                        targetStatus,
                        notes: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                      );
                      ref.invalidate(adminOrdersProvider);
                      ref.invalidate(orderDetailProvider(order.orderNumber));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Order ${order.orderNumber} updated to ${targetStatus.displayName} and logged into audit history.'),
                            backgroundColor: colors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Update failed: $e'), backgroundColor: colors.error),
                        );
                      }
                    }
                  },
                  child: const Text('CONFIRM TRANSITION & LOG', style: TextStyle(fontSize: 11, letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final ordersAsync = ref.watch(adminOrdersProvider((_selectedStatusFilter, _searchQuery)));
    final currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ATELIER ORDERS & PRODUCTION',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 26,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage client commissions, update craftsmanship milestones, and record immutable audit logs.',
                      style: TextStyle(color: colors.secondaryText, fontSize: 13),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(adminOrdersProvider),
                  tooltip: 'Refresh Commissions',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Controls & Filters Bar
            Container(
              padding: const EdgeInsets.all(20),
              color: colors.surface,
              child: Row(
                children: [
                  // Search
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by Order Number or Client...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = null);
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Status Filter
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<OrderStatus?>(
                      initialValue: _selectedStatusFilter,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Status',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Statuses')),
                        ...OrderStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))),
                      ],
                      onChanged: (val) => setState(() => _selectedStatusFilter = val),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Orders List
            ordersAsync.when(
              loading: () => Center(child: Padding(padding: const EdgeInsets.all(40), child: CircularProgressIndicator(color: colors.primaryText))),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(24),
                color: colors.error.withValues(alpha: 0.1),
                child: Text('Error loading orders: $err', style: TextStyle(color: colors.error)),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(48),
                    color: colors.surface,
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: colors.secondaryText),
                          const SizedBox(height: 16),
                          Text('No commissions match your query.', style: TextStyle(color: colors.primaryText, fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.border),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => Divider(color: colors.border, height: 1),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      Color statusColor;
                      if (order.status.isCompleted || order.status == OrderStatus.paid) {
                        statusColor = colors.success;
                      } else if (order.status.isCancelled) {
                        statusColor = colors.error;
                      } else {
                        statusColor = colors.accentVariant;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Order Number & Date
                            SizedBox(
                              width: 180,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.orderNumber,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.primaryText, letterSpacing: 1.0),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateFormat.format(order.createdAt),
                                    style: TextStyle(color: colors.secondaryText, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            // Items preview
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.items.map((i) => '${i.productName} (${i.quantity})').join(', '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.primaryText),
                                  ),
                                  if (order.deliveryAddress != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Client: ${order.deliveryAddress!.fullName} • ${order.deliveryAddress!.city}',
                                      style: TextStyle(color: colors.secondaryText, fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Total
                            SizedBox(
                              width: 140,
                              child: Text(
                                currency.format(order.total),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.primaryText),
                              ),
                            ),

                            // Status badge
                            SizedBox(
                              width: 180,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  color: statusColor.withValues(alpha: 0.15),
                                  child: Text(
                                    order.status.displayName.toUpperCase(),
                                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                  ),
                                ),
                              ),
                            ),

                            // Action
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primaryText,
                                foregroundColor: colors.onAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              ),
                              onPressed: () => _openStatusDialog(context, order, colors),
                              child: const Text('UPDATE STATUS & NOTE', style: TextStyle(fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
