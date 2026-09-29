import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/custom_atelier/domain/models/custom_request.dart';
import 'package:ochanya_gili/features/quotations/data/quotations_repository.dart';

class _QuoteLineItemDraft {
  final TextEditingController descController;
  final TextEditingController qtyController;
  final TextEditingController priceController;

  _QuoteLineItemDraft({
    String description = '',
    int quantity = 1,
    double unitPrice = 0.0,
  })  : descController = TextEditingController(text: description),
        qtyController = TextEditingController(text: quantity.toString()),
        priceController = TextEditingController(text: unitPrice > 0 ? unitPrice.toStringAsFixed(0) : '');

  void dispose() {
    descController.dispose();
    qtyController.dispose();
    priceController.dispose();
  }
}

class AdminQuoteComposerDialog extends ConsumerStatefulWidget {
  final CustomRequest request;
  final VoidCallback? onQuoteIssued;

  const AdminQuoteComposerDialog({
    super.key,
    required this.request,
    this.onQuoteIssued,
  });

  static Future<void> show(
    BuildContext context, {
    required CustomRequest request,
    VoidCallback? onQuoteIssued,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AdminQuoteComposerDialog(
        request: request,
        onQuoteIssued: onQuoteIssued,
      ),
    );
  }

  @override
  ConsumerState<AdminQuoteComposerDialog> createState() =>
      _AdminQuoteComposerDialogState();
}

class _AdminQuoteComposerDialogState
    extends ConsumerState<AdminQuoteComposerDialog> {
  final List<_QuoteLineItemDraft> _items = [];
  double _depositPercentage = 50.0;
  final _notesController = TextEditingController();
  final DateTime _validUntil = DateTime.now().add(const Duration(days: 14));
  bool _isIssuing = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with typical atelier line items based on request
    _items.add(_QuoteLineItemDraft(
      description: 'Base Pattern Drafting & Construction (${widget.request.direction})',
      quantity: 1,
      unitPrice: 280000,
    ));
    _items.add(_QuoteLineItemDraft(
      description: 'Fabric Allocation: ${widget.request.fabric}',
      quantity: 1,
      unitPrice: 120000,
    ));
    _items.add(_QuoteLineItemDraft(
      description: 'Hand Embellishment & Atelier Finishing',
      quantity: 1,
      unitPrice: 85000,
    ));
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal {
    double sum = 0.0;
    for (final item in _items) {
      final qty = int.tryParse(item.qtyController.text) ?? 1;
      final price = double.tryParse(item.priceController.text) ?? 0.0;
      sum += (qty * price);
    }
    return sum;
  }

  double get _total => _subtotal;
  double get _depositAmount => _total * (_depositPercentage / 100.0);
  double get _balanceAmount => _total - _depositAmount;

  Future<void> _issueQuote() async {
    if (_items.isEmpty) return;

    setState(() => _isIssuing = true);

    try {
      final lineItems = _items.map((draft) {
        return (
          description: draft.descController.text.trim().isNotEmpty
              ? draft.descController.text.trim()
              : 'Atelier Tailoring Service',
          quantity: int.tryParse(draft.qtyController.text) ?? 1,
          unitPrice: double.tryParse(draft.priceController.text) ?? 0.0,
        );
      }).toList();

      final repo = ref.read(quotationsRepositoryProvider);
      await repo.createQuote(
        customRequestId: widget.request.id,
        lineItems: lineItems,
        depositPercentage: _depositPercentage,
        validUntil: _validUntil,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onQuoteIssued?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Official quotation issued for commission ${widget.request.requestNumber}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error issuing quote: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isIssuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 860),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ATELIER QUOTE COMPOSER',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                            color: colors.accentVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Compose Quotation for ${widget.request.requestNumber}',
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryText,
                          ),
                        ),
                        Text(
                          'Client: ${widget.request.customerName ?? widget.request.customerEmail ?? "Guest"}  •  ${widget.request.occasion} (${widget.request.direction})',
                          style: TextStyle(fontSize: 12, color: colors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.primaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Line Items Table
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ITEMIZED ATELIER SERVICES & MATERIALS',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryText,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _items.add(_QuoteLineItemDraft());
                            });
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('ADD LINE ITEM'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Items list
                    ..._items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: item.descController,
                                decoration: InputDecoration(
                                  labelText: 'Line Description',
                                  border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 70,
                              child: TextFormField(
                                controller: item.qtyController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Qty',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: item.priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Unit Price (₦)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              onPressed: _items.length > 1
                                  ? () {
                                      setState(() {
                                        _items.removeAt(idx).dispose();
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Deposit Configuration Bar
                    Row(
                      children: [
                        Text(
                          'DEPOSIT SPLIT:',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryText,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ...[30.0, 50.0, 70.0, 100.0].map((pct) {
                          final isSelected = _depositPercentage == pct;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text('${pct.toInt()}% DEPOSIT'),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _depositPercentage = pct),
                              selectedColor: colors.primaryText,
                              labelStyle: TextStyle(
                                color: isSelected ? colors.onAccent : colors.primaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Financial Summary Box
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: colors.surfaceVariant,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Commission Value:', style: TextStyle(fontSize: 14, color: colors.secondaryText)),
                              Text(currency.format(_total), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.primaryText)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Deposit Required to Begin (${_depositPercentage.toInt()}%):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.accentVariant)),
                              Text(currency.format(_depositAmount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.accentVariant)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Balance Due at Salon Fitting:', style: TextStyle(fontSize: 13, color: colors.secondaryText)),
                              Text(currency.format(_balanceAmount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.primaryText)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Notes & Validity
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Atelier Terms & Tailor Notes for Client',
                        hintText: 'E.g. Price includes 2 fittings in our Abuja salon. Silk organza under-toile included.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                  ElevatedButton(
                    onPressed: _isIssuing ? null : _issueQuote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: _isIssuing
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: colors.onAccent),
                          )
                        : const Text(
                            'ISSUE OFFICIAL QUOTATION',
                            style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
