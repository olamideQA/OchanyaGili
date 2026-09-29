import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/admin/data/admin_repository.dart';

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  String _selectedFilter = 'all';

  void _openRecordPaymentDialog(BuildContext context, AppColorTokens colors) {
    final profileIdCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    String selectedProvider = 'bank_transfer';
    String selectedType = 'order';
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
                'LOG MANUAL / OFFLINE PAYMENT',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colors.primaryText,
                ),
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: profileIdCtrl,
                      decoration: InputDecoration(
                        labelText: 'CLIENT PROFILE UUID *',
                        hintText: 'e.g. 5eab2f72-0003-4fc8-a6a2-0f5ee31bc291',
                        labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'AMOUNT (₦) *',
                        hintText: '150000',
                        labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedProvider,
                      decoration: InputDecoration(
                        labelText: 'PAYMENT METHOD / CHANNEL',
                        labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'bank_transfer', child: Text('Direct Atelier Bank Transfer')),
                        DropdownMenuItem(value: 'pos', child: Text('POS Terminal in Salon')),
                        DropdownMenuItem(value: 'cash', child: Text('Salon Cash Payment')),
                        DropdownMenuItem(value: 'paystack', child: Text('Paystack Gateway (Manual Record)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedProvider = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: 'PAYMENT TYPE',
                        labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'order', child: Text('Full Order Commission')),
                        DropdownMenuItem(value: 'deposit', child: Text('Bespoke Custom Deposit (70%)')),
                        DropdownMenuItem(value: 'balance', child: Text('Bespoke Final Balance (30%)')),
                        DropdownMenuItem(value: 'booking_fee', child: Text('Salon Consultation Fee')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: refCtrl,
                      decoration: InputDecoration(
                        labelText: 'TRANSACTION REFERENCE / TELLER NO.',
                        hintText: 'e.g. TRF-2026-0929-8812',
                        labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                      ),
                    ),
                  ],
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
                          final profileId = profileIdCtrl.text.trim();
                          final amount = double.tryParse(amountCtrl.text.trim());
                          if (profileId.isEmpty || amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter valid client ID and amount')),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          try {
                            await ref.read(adminRepositoryProvider).recordPayment(
                                  profileId: profileId,
                                  amount: amount,
                                  currency: 'NGN',
                                  provider: selectedProvider,
                                  providerReference: refCtrl.text.trim().isEmpty ? null : refCtrl.text.trim(),
                                  status: 'successful',
                                  paymentType: selectedType,
                                );

                            if (context.mounted) {
                              Navigator.pop(dialogCtx);
                              ref.invalidate(adminPaymentsProvider(_selectedFilter));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Payment of ₦${amount.toStringAsFixed(0)} logged successfully'),
                                  backgroundColor: colors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error recording payment: $e')),
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
                      : const Text('LOG PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final paymentsAsync = ref.watch(adminPaymentsProvider(_selectedFilter));
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
                      'PAYMENTS AUDIT & FINANCIAL LEDGER',
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
                      'Reconciliation of gateway transactions, bank deposits, and bespoke balances',
                      style: TextStyle(color: colors.secondaryText, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(adminPaymentsProvider(_selectedFilter)),
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
                      onPressed: () => _openRecordPaymentDialog(context, colors),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('LOG PAYMENT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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

            // Filter Tabs
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  _filterButton('ALL TRANSACTIONS', 'all', colors),
                  _filterButton('SUCCESSFUL', 'successful', colors),
                  _filterButton('PENDING', 'pending', colors),
                  _filterButton('FAILED', 'failed', colors),
                  _filterButton('REFUNDED', 'refunded', colors),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payments Table
            paymentsAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: CircularProgressIndicator(color: colors.primaryText),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text('Error loading payments: $err', style: TextStyle(color: colors.error)),
                ),
              ),
              data: (payments) {
                if (payments.isEmpty) {
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
                          Icon(Icons.payment_outlined, size: 48, color: colors.secondaryText),
                          const SizedBox(height: 12),
                          Text(
                            'No payment records found for filter "$_selectedFilter".',
                            style: TextStyle(color: colors.secondaryText, fontSize: 14),
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
                            Expanded(flex: 2, child: _HeaderCell('DATE & TIME', colors)),
                            Expanded(flex: 3, child: _HeaderCell('CLIENT', colors)),
                            Expanded(flex: 2, child: _HeaderCell('CHANNEL / PROVIDER', colors)),
                            Expanded(flex: 3, child: _HeaderCell('REFERENCE', colors)),
                            Expanded(flex: 2, child: _HeaderCell('TYPE', colors)),
                            Expanded(flex: 2, child: _HeaderCell('AMOUNT', colors)),
                            Expanded(flex: 2, child: _HeaderCell('STATUS', colors, align: TextAlign.right)),
                          ],
                        ),
                      ),
                      Divider(color: colors.border, height: 1),

                      // Rows
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: payments.length,
                        separatorBuilder: (context, index) => Divider(color: colors.border, height: 1),
                        itemBuilder: (context, index) {
                          final p = payments[index];
                          final isSuccess = p.status == 'successful';

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Row(
                              children: [
                                // Date
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM yyyy').format(p.createdAt),
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.primaryText),
                                      ),
                                      Text(
                                        DateFormat('HH:mm').format(p.createdAt),
                                        style: TextStyle(fontSize: 11, color: colors.secondaryText),
                                      ),
                                    ],
                                  ),
                                ),

                                // Client
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.customerName ?? 'Private Client',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.primaryText),
                                      ),
                                      if (p.customerEmail != null)
                                        Text(
                                          p.customerEmail!,
                                          style: TextStyle(fontSize: 11, color: colors.secondaryText),
                                        ),
                                    ],
                                  ),
                                ),

                                // Provider
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    p.provider.toUpperCase().replaceAll('_', ' '),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.primaryText),
                                  ),
                                ),

                                // Reference
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    p.providerReference ?? '—',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      color: colors.secondaryText,
                                    ),
                                  ),
                                ),

                                // Type
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    p.paymentType.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(fontSize: 11, color: colors.secondaryText),
                                  ),
                                ),

                                // Amount
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    currencyFormatter.format(p.amount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: colors.primaryText,
                                    ),
                                  ),
                                ),

                                // Status Badge
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      color: isSuccess
                                          ? colors.success.withValues(alpha: 0.1)
                                          : (p.status == 'pending'
                                              ? colors.warning.withValues(alpha: 0.1)
                                              : colors.error.withValues(alpha: 0.1)),
                                      child: Text(
                                        p.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                          color: isSuccess
                                              ? colors.success
                                              : (p.status == 'pending' ? colors.warning : colors.error),
                                        ),
                                      ),
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

  Widget _filterButton(String label, String value, AppColorTokens colors) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: isSelected ? colors.primaryText : Colors.transparent,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: isSelected ? colors.surface : colors.secondaryText,
          ),
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
