import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/custom_atelier/domain/models/custom_request.dart';
import 'package:ochanya_gili/features/quotations/data/quotations_repository.dart';
import 'package:ochanya_gili/features/quotations/domain/models/quote.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/footer.dart';

/// Provider to fetch a single custom request by ID
final singleCustomRequestProvider =
    FutureProvider.family<CustomRequest?, String>((ref, requestId) async {
  final client = Supabase.instance.client;
  final res = await client
      .from('custom_requests')
      .select(
          '*, custom_request_images(*), profiles!custom_requests_profile_id_fkey(full_name, email, phone), measurement_profiles(*)')
      .eq('id', requestId)
      .maybeSingle();
  if (res == null) return null;
  return CustomRequest.fromJson(res);
});

class CustomRequestDetailScreen extends ConsumerWidget {
  final String requestId;

  const CustomRequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final requestAsync = ref.watch(singleCustomRequestProvider(requestId));
    final quoteAsync = ref.watch(latestQuoteProvider(requestId));

    return Scaffold(
      appBar: AppBar(
        title: requestAsync.when(
          data: (r) => Text(r?.requestNumber ?? 'Commission Detail'),
          loading: () => const Text('Loading...'),
          error: (_, _) => const Text('Commission Detail'),
        ),
        backgroundColor: colors.surface,
        foregroundColor: colors.primaryText,
        elevation: 0,
      ),
      body: requestAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.primaryText)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (request) {
          if (request == null) {
            return Center(
              child: Text('Commission not found.',
                  style: TextStyle(color: colors.secondaryText)),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRequestSummary(context, request, colors),
                    const SizedBox(height: 32),
                    quoteAsync.when(
                      loading: () => Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: colors.primaryText)),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (quote) {
                        if (quote == null) {
                          return _buildAwaitingQuote(colors);
                        }
                        return _buildQuotationCard(
                            context, ref, request, quote, colors);
                      },
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
  },
),
);
  }

  Widget _buildRequestSummary(
      BuildContext context, CustomRequest request, AppColorTokens colors) {
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: colors.surfaceVariant,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      request.requestNumber,
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildStatusChip(request.status, colors),
                  ],
                ),
                Text(
                  request.createdAt != null
                      ? dateFormat.format(request.createdAt!)
                      : '',
                  style: TextStyle(fontSize: 12, color: colors.secondaryText),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 32,
                  runSpacing: 12,
                  children: [
                    _detailPair('OCCASION', request.occasion, colors),
                    _detailPair('SILHOUETTE', request.direction, colors),
                    _detailPair('FABRIC', request.fabric, colors),
                    _detailPair('SHADE', request.colour, colors),
                  ],
                ),
                if (request.inspirationText != null &&
                    request.inspirationText!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('"${request.inspirationText}"',
                      style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                          color: colors.secondaryText)),
                ],
                if (request.designerNotes != null &&
                    request.designerNotes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: colors.surfaceVariant,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DESIGNER REMARKS',
                            style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                                color: colors.accentVariant)),
                        const SizedBox(height: 6),
                        Text(request.designerNotes!,
                            style: TextStyle(
                                fontSize: 13, color: colors.primaryText)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailPair(String label, String value, AppColorTokens colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: colors.secondaryText)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.primaryText)),
      ],
    );
  }

  Widget _buildAwaitingQuote(AppColorTokens colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty, size: 40, color: colors.accentVariant),
          const SizedBox(height: 16),
          Text('QUOTATION PENDING',
              style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                  color: colors.primaryText)),
          const SizedBox(height: 8),
          Text(
            'Our atelier team is reviewing your commission and preparing an itemized quotation. You will be notified when it is ready.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, height: 1.6, color: colors.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationCard(BuildContext context, WidgetRef ref,
      CustomRequest request, Quote quote, AppColorTokens colors) {
    final currency = NumberFormat.currency(
        locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OFFICIAL QUOTATION — VERSION ${quote.version}',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        color: colors.accentVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Itemized Commission Estimate',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                  ],
                ),
                _buildQuoteStatusChip(quote.status, colors),
              ],
            ),
          ),

          // Line Items Table
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  color: colors.surfaceVariant,
                  child: Row(
                    children: [
                      Expanded(
                          flex: 5,
                          child: Text('DESCRIPTION',
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                  color: colors.secondaryText))),
                      Expanded(
                          flex: 1,
                          child: Text('QTY',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                  color: colors.secondaryText))),
                      Expanded(
                          flex: 2,
                          child: Text('UNIT PRICE',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                  color: colors.secondaryText))),
                      Expanded(
                          flex: 2,
                          child: Text('TOTAL',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                  color: colors.secondaryText))),
                    ],
                  ),
                ),

                // Line Items
                ...quote.items.map((item) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border:
                            Border(bottom: BorderSide(color: colors.border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 5,
                              child: Text(item.description,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: colors.primaryText))),
                          Expanded(
                              flex: 1,
                              child: Text('${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: colors.primaryText))),
                          Expanded(
                              flex: 2,
                              child: Text(currency.format(item.unitPrice),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: colors.secondaryText))),
                          Expanded(
                              flex: 2,
                              child: Text(currency.format(item.totalPrice),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.primaryText))),
                        ],
                      ),
                    )),

                const SizedBox(height: 16),

                // Totals
                _totalRow('Subtotal', currency.format(quote.subtotal), colors,
                    isBold: false),
                _totalRow(
                    'Deposit Required (${quote.depositPercentage.toStringAsFixed(0)}%)',
                    currency.format(quote.depositAmount),
                    colors),
                _totalRow('Balance Due After Production',
                    currency.format(quote.balanceAmount), colors,
                    isBold: false),
                const Divider(height: 24),
                _totalRow(
                    'TOTAL', currency.format(quote.total), colors,
                    isBold: true, isLarge: true),

                // Notes
                if (quote.notes != null && quote.notes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('TERMS & NOTES',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          color: colors.secondaryText)),
                  const SizedBox(height: 6),
                  Text(quote.notes!,
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: colors.primaryText)),
                ],

                // Validity
                if (quote.validUntil != null) ...[
                  const SizedBox(height: 12),
                  Text(
                      'Valid Until: ${dateFormat.format(quote.validUntil!)}',
                      style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: colors.secondaryText)),
                ],

                const SizedBox(height: 28),

                // Action Buttons
                _buildQuoteActions(context, ref, request, quote, colors, currency),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, AppColorTokens colors,
      {bool isBold = true, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isLarge ? 14 : 12,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: colors.primaryText)),
          const SizedBox(width: 40),
          SizedBox(
            width: 140,
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: isLarge ? 18 : 13,
                    fontFamily: isLarge ? 'Playfair Display' : null,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    color: colors.primaryText)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteActions(BuildContext context, WidgetRef ref,
      CustomRequest request, Quote quote, AppColorTokens colors, NumberFormat currency) {
    // Quote sent — customer can accept or request changes
    if (quote.canBeAccepted) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () =>
                _showRequestChangesDialog(context, ref, quote, colors),
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('REQUEST CHANGES'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primaryText,
              side: BorderSide(color: colors.border),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _acceptQuote(context, ref, quote, colors),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('ACCEPT QUOTATION'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.success,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      );
    }

    // Quote accepted, awaiting deposit payment
    if (quote.isAccepted &&
        request.status == CustomRequestStatus.customerApproved) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () =>
              _payDeposit(context, ref, quote, colors),
          icon: const Icon(Icons.payment, size: 18),
          label: Text('PAY DEPOSIT — ${currency.format(quote.depositAmount)}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accentVariant,
            foregroundColor: colors.surface,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      );
    }

    // Deposit settled — production underway
    if (request.status == CustomRequestStatus.payment ||
        request.status == CustomRequestStatus.production ||
        request.status == CustomRequestStatus.fitting ||
        request.status == CustomRequestStatus.alteration ||
        request.status == CustomRequestStatus.ready ||
        request.status == CustomRequestStatus.delivered) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: colors.success.withValues(alpha: 0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: colors.success, size: 20),
            const SizedBox(width: 10),
            Text(
              'DEPOSIT SETTLED — PRODUCTION COMMENCED',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                color: colors.success,
              ),
            ),
          ],
        ),
      );
    }

    // Quote rejected / revised — waiting for new version
    if (quote.status == QuoteStatus.rejected ||
        quote.status == QuoteStatus.revised) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: colors.accentVariant.withValues(alpha: 0.1),
        child: Text(
          'Change request submitted. A revised quotation will be issued by the atelier team.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: colors.accentVariant),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _acceptQuote(BuildContext context, WidgetRef ref, Quote quote,
      AppColorTokens colors) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Accept Quotation?'),
        content: const Text(
            'By accepting this quotation, you agree to the itemized pricing and deposit terms. You will then be prompted to pay the deposit to begin production.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('ACCEPT'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(quotationsRepositoryProvider);
      await repo.acceptQuote(quote.id, quote.customRequestId);
      ref.invalidate(singleCustomRequestProvider(requestId));
      ref.invalidate(latestQuoteProvider(requestId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Quotation accepted. Please proceed with deposit payment.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting quote: $e')),
        );
      }
    }
  }

  Future<void> _payDeposit(BuildContext context, WidgetRef ref, Quote quote,
      AppColorTokens colors) async {
    final currency = NumberFormat.currency(
        locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Confirm Deposit Payment'),
        content: Text(
            'You are about to pay a deposit of ${currency.format(quote.depositAmount)} to commence production on your bespoke commission.\n\nIn production, this initiates a secure Paystack checkout.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentVariant,
              foregroundColor: colors.surface,
            ),
            child: const Text('CONFIRM PAYMENT'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(quotationsRepositoryProvider);
      final paymentRef =
          'PAY-${DateTime.now().millisecondsSinceEpoch}';
      await repo.settleDepositPayment(
        customRequestId: quote.customRequestId,
        quoteId: quote.id,
        paymentReference: paymentRef,
        amountPaid: quote.depositAmount,
      );
      ref.invalidate(singleCustomRequestProvider(requestId));
      ref.invalidate(latestQuoteProvider(requestId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Deposit payment settled. Your commission is now in production!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment error: $e')),
        );
      }
    }
  }

  void _showRequestChangesDialog(BuildContext context, WidgetRef ref,
      Quote quote, AppColorTokens colors) {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Request Quotation Changes'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Describe the adjustments you would like made to this quotation. The atelier team will issue a revised version.',
                  style: TextStyle(
                      fontSize: 13, color: colors.secondaryText)),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'e.g., Could we use a lighter fabric? Can the embellishment be simplified?...',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.border),
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final feedback = feedbackController.text.trim();
              if (feedback.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final repo = ref.read(quotationsRepositoryProvider);
                await repo.requestChanges(
                    quote.id, quote.customRequestId, feedback);
                ref.invalidate(singleCustomRequestProvider(requestId));
                ref.invalidate(latestQuoteProvider(requestId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Change request submitted. The atelier team will revise your quotation.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
            ),
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
      CustomRequestStatus status, AppColorTokens colors) {
    Color bg;
    Color fg;

    switch (status) {
      case CustomRequestStatus.requested:
      case CustomRequestStatus.underReview:
        bg = colors.accentVariant.withValues(alpha: 0.15);
        fg = colors.accentVariant;
        break;
      case CustomRequestStatus.designDiscussion:
      case CustomRequestStatus.quoteSent:
      case CustomRequestStatus.customerApproved:
        bg = colors.primaryText.withValues(alpha: 0.1);
        fg = colors.primaryText;
        break;
      case CustomRequestStatus.payment:
      case CustomRequestStatus.production:
      case CustomRequestStatus.fitting:
      case CustomRequestStatus.alteration:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade800;
        break;
      case CustomRequestStatus.ready:
      case CustomRequestStatus.delivered:
        bg = colors.success.withValues(alpha: 0.15);
        fg = colors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: bg,
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.0,
            fontWeight: FontWeight.bold,
            color: fg),
      ),
    );
  }

  Widget _buildQuoteStatusChip(
      QuoteStatus status, AppColorTokens colors) {
    Color bg;
    Color fg;

    switch (status) {
      case QuoteStatus.sent:
        bg = colors.accentVariant.withValues(alpha: 0.15);
        fg = colors.accentVariant;
        break;
      case QuoteStatus.accepted:
        bg = colors.success.withValues(alpha: 0.15);
        fg = colors.success;
        break;
      case QuoteStatus.rejected:
        bg = colors.error.withValues(alpha: 0.15);
        fg = colors.error;
        break;
      case QuoteStatus.revised:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade800;
        break;
      case QuoteStatus.expired:
        bg = colors.secondaryText.withValues(alpha: 0.15);
        fg = colors.secondaryText;
        break;
      case QuoteStatus.draft:
        bg = colors.surfaceVariant;
        fg = colors.secondaryText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: bg,
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.0,
            fontWeight: FontWeight.bold,
            color: fg),
      ),
    );
  }
}
