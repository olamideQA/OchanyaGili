import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/admin/data/admin_repository.dart';
import 'package:ochanya_gili/features/admin/domain/models/admin_dashboard_models.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';

class AdminInventoryScreen extends ConsumerStatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  ConsumerState<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
    });
  }

  void _openStockAdjustmentDialog(BuildContext context, InventoryItem item, AppColorTokens colors) {
    final qtyController = TextEditingController(text: item.quantity.toStringAsFixed(1));
    final reasonController = TextEditingController();
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
                'ADJUST STOCK LEVEL',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colors.primaryText,
                ),
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Material / Item: ${item.name} (${item.sku})',
                      style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current Stock: ${item.quantity} ${item.unit}',
                      style: TextStyle(color: colors.secondaryText, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'NEW QUANTITY (${item.unit})',
                        labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: colors.primaryText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'REASON FOR ADJUSTMENT',
                        hintText: 'e.g., Fabric bolt receipt, pattern cutting wastage, physical audit...',
                        labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: colors.primaryText),
                        ),
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
                          final newQty = double.tryParse(qtyController.text.trim());
                          final reason = reasonController.text.trim();
                          if (newQty == null || reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid quantity and reason')),
                            );
                            return;
                          }

                          final user = ref.read(currentUserProvider).value;
                          setDialogState(() => isSubmitting = true);

                          try {
                            await ref.read(adminRepositoryProvider).adjustStock(
                                  inventoryId: item.id,
                                  newQuantity: newQty,
                                  reason: reason,
                                  performedBy: user?.id ?? '',
                                );
                            if (context.mounted) {
                              Navigator.pop(dialogCtx);
                              ref.invalidate(adminInventoryProvider(_searchQuery));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Stock for ${item.name} adjusted to $newQty ${item.unit}'),
                                  backgroundColor: colors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error adjusting stock: $e')),
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
                      : const Text('CONFIRM ADJUSTMENT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openCreateItemDialog(BuildContext context, AppColorTokens colors) {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '0');
    final unitCtrl = TextEditingController(text: 'meters');
    final costCtrl = TextEditingController(text: '0');
    final supplierCtrl = TextEditingController();
    final thresholdCtrl = TextEditingController(text: '5');
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
                'NEW ATELIER MATERIAL / STOCK ITEM',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colors.primaryText,
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'ITEM NAME *',
                          hintText: 'e.g. Italian Silk Mikado, Black Horn Buttons...',
                          labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: skuCtrl,
                              decoration: InputDecoration(
                                labelText: 'SKU *',
                                hintText: 'MAT-SLK-01',
                                labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: unitCtrl,
                              decoration: InputDecoration(
                                labelText: 'UNIT *',
                                hintText: 'meters / pcs / rolls',
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
                              controller: qtyCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'INITIAL QUANTITY *',
                                labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: costCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'COST PER UNIT (₦)',
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
                              controller: supplierCtrl,
                              decoration: InputDecoration(
                                labelText: 'SUPPLIER / TEXTILE MILL',
                                labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: thresholdCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'REORDER THRESHOLD',
                                labelStyle: TextStyle(color: colors.secondaryText, fontSize: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: colors.border)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'DESCRIPTION / WEAVE SPECS',
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
                          final name = nameCtrl.text.trim();
                          final sku = skuCtrl.text.trim();
                          final unit = unitCtrl.text.trim();
                          final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
                          final cost = double.tryParse(costCtrl.text.trim()) ?? 0.0;
                          final threshold = double.tryParse(thresholdCtrl.text.trim()) ?? 5.0;

                          if (name.isEmpty || sku.isEmpty || unit.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill out Name, SKU, and Unit')),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          try {
                            await ref.read(adminRepositoryProvider).createInventoryItem(
                                  name: name,
                                  sku: sku,
                                  description: descCtrl.text.trim(),
                                  quantity: qty,
                                  unit: unit,
                                  costPerUnit: cost,
                                  supplier: supplierCtrl.text.trim(),
                                  reorderThreshold: threshold,
                                );
                            if (context.mounted) {
                              Navigator.pop(dialogCtx);
                              ref.invalidate(adminInventoryProvider(_searchQuery));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Material $name added to atelier ledger'),
                                  backgroundColor: colors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error creating material: $e')),
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
                      : const Text('SAVE MATERIAL', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final inventoryAsync = ref.watch(adminInventoryProvider(_searchQuery));
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
                      'INVENTORY & RAW MATERIALS',
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
                      'Fabrics, silks, notions, haberdashery, and atelier stock control',
                      style: TextStyle(color: colors.secondaryText, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(adminInventoryProvider(_searchQuery)),
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
                      onPressed: () => _openCreateItemDialog(context, colors),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('ADD MATERIAL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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

            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _onSearch(),
                      style: TextStyle(color: colors.primaryText, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by material name, SKU, or supplier...',
                        hintStyle: TextStyle(color: colors.secondaryText, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: colors.secondaryText),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchQuery != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = null);
                      },
                    ),
                  ElevatedButton(
                    onPressed: _onSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryText,
                      foregroundColor: colors.surface,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: const Text('SEARCH', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Inventory List
            inventoryAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: CircularProgressIndicator(color: colors.primaryText),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text('Error loading inventory: $err', style: TextStyle(color: colors.error)),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
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
                          Icon(Icons.inventory_2_outlined, size: 48, color: colors.secondaryText),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery != null
                                ? 'No materials matching "$_searchQuery".'
                                : 'No atelier materials registered yet.',
                            style: TextStyle(color: colors.secondaryText, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _openCreateItemDialog(context, colors),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primaryText,
                              foregroundColor: colors.surface,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            child: const Text('ADD FIRST MATERIAL'),
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
                            Expanded(flex: 3, child: _HeaderCell('MATERIAL / SKU', colors)),
                            Expanded(flex: 2, child: _HeaderCell('IN STOCK', colors)),
                            Expanded(flex: 2, child: _HeaderCell('COST/UNIT', colors)),
                            Expanded(flex: 2, child: _HeaderCell('SUPPLIER', colors)),
                            Expanded(flex: 2, child: _HeaderCell('STATUS', colors)),
                            Expanded(flex: 2, child: _HeaderCell('ACTION', colors, align: TextAlign.right)),
                          ],
                        ),
                      ),
                      Divider(color: colors.border, height: 1),

                      // Rows
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => Divider(color: colors.border, height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Row(
                              children: [
                                // Name & SKU
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: colors.primaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'SKU: ${item.sku}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colors.secondaryText,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // In Stock
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${item.quantity.toStringAsFixed(1)} ${item.unit}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: item.isOutOfStock
                                          ? colors.error
                                          : (item.isLowStock ? colors.warning : colors.primaryText),
                                    ),
                                  ),
                                ),

                                // Cost
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    currencyFormatter.format(item.costPerUnit),
                                    style: TextStyle(fontSize: 13, color: colors.secondaryText),
                                  ),
                                ),

                                // Supplier
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.supplier?.isNotEmpty == true ? item.supplier! : '—',
                                    style: TextStyle(fontSize: 13, color: colors.secondaryText),
                                  ),
                                ),

                                // Status Badge
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      color: item.isOutOfStock
                                          ? colors.error.withValues(alpha: 0.1)
                                          : (item.isLowStock
                                              ? colors.warning.withValues(alpha: 0.1)
                                              : colors.success.withValues(alpha: 0.1)),
                                      child: Text(
                                        item.isOutOfStock
                                            ? 'OUT OF STOCK'
                                            : (item.isLowStock ? 'LOW STOCK' : 'IN STOCK'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                          color: item.isOutOfStock
                                              ? colors.error
                                              : (item.isLowStock ? colors.warning : colors.success),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Action
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton(
                                      onPressed: () => _openStockAdjustmentDialog(context, item, colors),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: colors.primaryText,
                                        side: BorderSide(color: colors.border),
                                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      child: const Text('ADJUST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
