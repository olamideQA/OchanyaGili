import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/admin/data/admin_repository.dart';
import 'package:ochanya_gili/features/admin/domain/models/admin_dashboard_models.dart';

class AdminDiscountsScreen extends ConsumerStatefulWidget {
  const AdminDiscountsScreen({super.key});

  @override
  ConsumerState<AdminDiscountsScreen> createState() => _AdminDiscountsScreenState();
}

class _AdminDiscountsScreenState extends ConsumerState<AdminDiscountsScreen> {
  void _openCreateDiscountDialog(BuildContext context, AppColorTokens colors) {
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final minOrderCtrl = TextEditingController();
    final maxUsesCtrl = TextEditingController();
    String selectedType = 'percentage';
    DateTime? selectedExpiresAt;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              title: Text(
                'CREATE DISCOUNT VOUCHER',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colors.primaryText,
                ),
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'PROMO CODE *',
                          hintText: 'e.g. ATELIER10, BRIDAL2026',
                          labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedType,
                              decoration: InputDecoration(
                                labelText: 'DISCOUNT TYPE',
                                labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                                DropdownMenuItem(value: 'fixed_amount', child: Text('Fixed Amount (₦)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedType = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: valueCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: selectedType == 'percentage' ? 'VALUE (%) *' : 'VALUE (₦) *',
                                hintText: selectedType == 'percentage' ? '15' : '50000',
                                labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minOrderCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'MINIMUM ORDER (₦)',
                                hintText: 'Optional',
                                labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: maxUsesCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'MAX USES LIMIT',
                                hintText: 'Unlimited if empty',
                                labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          selectedExpiresAt == null
                              ? 'No expiration date'
                              : 'Expires: ${DateFormat('dd MMM yyyy').format(selectedExpiresAt!)}',
                          style: TextStyle(fontSize: 13, color: colors.primaryText),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedExpiresAt = picked);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.border),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: const Text('PICK DATE'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'DESCRIPTION / CAMPAIGN NOTES',
                          hintText: 'e.g. Exclusive 15% discount for Couture Gala attendees',
                          labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: Text('CANCEL', style: TextStyle(color: colors.secondaryText)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final code = codeCtrl.text.trim().toUpperCase();
                          final val = double.tryParse(valueCtrl.text.trim());
                          if (code.isEmpty || val == null || val <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid code and discount value')),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          try {
                            final discount = AdminDiscount(
                              id: '',
                              code: code,
                              description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                              type: selectedType,
                              value: val,
                              minOrderAmount: double.tryParse(minOrderCtrl.text.trim()),
                              maxUses: int.tryParse(maxUsesCtrl.text.trim()),
                              startsAt: DateTime.now(),
                              expiresAt: selectedExpiresAt,
                              isActive: true,
                              createdAt: DateTime.now(),
                            );

                            await ref.read(adminRepositoryProvider).createDiscount(discount);
                            if (context.mounted) {
                              Navigator.pop(dialogCtx);
                              ref.invalidate(adminDiscountsProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Voucher $code created successfully'),
                                  backgroundColor: colors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error creating discount: $e')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryText,
                    foregroundColor: colors.surface,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('CREATE VOUCHER', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final discountsAsync = ref.watch(adminDiscountsProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROMOTIONAL VOUCHERS & DISCOUNTS',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage bespoke vouchers, seasonal campaigns, and atelier courtesy codes',
                      style: TextStyle(color: colors.secondaryText, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(adminDiscountsProvider),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('REFRESH'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryText,
                        side: BorderSide(color: colors.border),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _openCreateDiscountDialog(context, colors),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('NEW VOUCHER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryText,
                        foregroundColor: colors.surface,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Discounts List
            discountsAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: CircularProgressIndicator(color: colors.primaryText),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text('Error loading discounts: $err', style: TextStyle(color: colors.error)),
                ),
              ),
              data: (discounts) {
                if (discounts.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(60),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.border),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_offer_outlined, size: 48, color: colors.secondaryText),
                          const SizedBox(height: 12),
                          Text(
                            'No promotional vouchers configured yet.',
                            style: TextStyle(color: colors.secondaryText, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _openCreateDiscountDialog(context, colors),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primaryText,
                              foregroundColor: colors.surface,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            child: const Text('CREATE FIRST VOUCHER'),
                          ),
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
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        color: colors.surfaceVariant,
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: _HeaderCell('CODE', colors)),
                            Expanded(flex: 2, child: _HeaderCell('DISCOUNT', colors)),
                            Expanded(flex: 3, child: _HeaderCell('CONDITIONS & MINIMUM', colors)),
                            Expanded(flex: 2, child: _HeaderCell('USAGE', colors)),
                            Expanded(flex: 2, child: _HeaderCell('VALID UNTIL', colors)),
                            Expanded(flex: 2, child: _HeaderCell('ACTIVE', colors, align: TextAlign.right)),
                          ],
                        ),
                      ),
                      Divider(color: colors.border, height: 1),

                      // Rows
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: discounts.length,
                        separatorBuilder: (context, index) => Divider(color: colors.border, height: 1),
                        itemBuilder: (context, index) {
                          final d = discounts[index];
                          final isExpired = d.isExpired;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Row(
                              children: [
                                // Code
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    d.code,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 1.2,
                                      color: colors.primaryText,
                                    ),
                                  ),
                                ),

                                // Value
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    d.type == 'percentage'
                                        ? '${d.value.toStringAsFixed(0)}% OFF'
                                        : '${currencyFormatter.format(d.value)} OFF',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: colors.accentVariant,
                                    ),
                                  ),
                                ),

                                // Conditions
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (d.description != null)
                                        Text(
                                          d.description!,
                                          style: TextStyle(fontSize: 12, color: colors.primaryText),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      Text(
                                        d.minOrderAmount != null
                                            ? 'Min order: ${currencyFormatter.format(d.minOrderAmount)}'
                                            : 'No min order amount',
                                        style: TextStyle(fontSize: 11, color: colors.secondaryText),
                                      ),
                                    ],
                                  ),
                                ),

                                // Usage
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    d.maxUses != null
                                        ? '${d.usedCount} / ${d.maxUses} used'
                                        : '${d.usedCount} used (unlimited)',
                                    style: TextStyle(fontSize: 12, color: colors.secondaryText),
                                  ),
                                ),

                                // Expiration
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    d.expiresAt != null
                                        ? DateFormat('dd MMM yyyy').format(d.expiresAt!)
                                        : 'Never expires',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isExpired ? colors.error : colors.secondaryText,
                                      fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),

                                // Active Switch
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Switch(
                                      value: d.isActive && !isExpired,
                                      activeThumbColor: colors.primaryText,
                                      onChanged: isExpired
                                          ? null
                                          : (val) async {
                                              await ref
                                                  .read(adminRepositoryProvider)
                                                  .toggleDiscountActive(d.id, val);
                                              ref.invalidate(adminDiscountsProvider);
                                            },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
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

class _HeaderCell extends StatelessWidget {
  final String title;
  final AppColorTokens colors;
  final TextAlign align;

  const _HeaderCell(this.title, this.colors, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: align,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: colors.primaryText,
      ),
    );
  }
}
