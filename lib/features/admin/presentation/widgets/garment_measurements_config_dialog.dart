import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/measurements/data/measurements_repository.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_field.dart';
import 'package:ochanya_gili/features/shop/domain/models/product.dart';

class GarmentMeasurementsConfigDialog extends ConsumerStatefulWidget {
  final Product product;
  final VoidCallback? onSaved;

  const GarmentMeasurementsConfigDialog({
    super.key,
    required this.product,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
    VoidCallback? onSaved,
  }) {
    return showDialog(
      context: context,
      builder: (context) => GarmentMeasurementsConfigDialog(
        product: product,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<GarmentMeasurementsConfigDialog> createState() =>
      _GarmentMeasurementsConfigDialogState();
}

class _GarmentMeasurementsConfigDialogState
    extends ConsumerState<GarmentMeasurementsConfigDialog> {
  late Set<String> _selectedKeys;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedKeys = Set<String>.from(widget.product.effectiveRequiredMeasurements);
  }

  void _applyPreset(List<String> keys) {
    setState(() {
      _selectedKeys = Set<String>.from(keys);
    });
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(measurementsRepositoryProvider);
      await repo.updateGarmentRequiredMeasurements(
        widget.product.id,
        _selectedKeys.toList(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Required measurements updated for ${widget.product.name} (${_selectedKeys.length} points active).',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating requirements: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;

    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 800),
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
                          'ATELIER DESIGNER CONFIGURATION',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                            color: colors.accentVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Required Garment Measurements: ${widget.product.name}',
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.primaryText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Presets Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: colors.surfaceVariant,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'QUICK PRESETS:',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: colors.secondaryText,
                    ),
                  ),
                  ActionChip(
                    label: const Text('Gown / Dress'),
                    onPressed: () => _applyPreset([
                      MeasurementField.shoulder,
                      MeasurementField.bust,
                      MeasurementField.underBust,
                      MeasurementField.waist,
                      MeasurementField.hip,
                      MeasurementField.frontLength,
                      MeasurementField.dressLength,
                    ]),
                  ),
                  ActionChip(
                    label: const Text('Trousers / Pants'),
                    onPressed: () => _applyPreset([
                      MeasurementField.trouserWaist,
                      MeasurementField.trouserHip,
                      MeasurementField.trouserLength,
                      MeasurementField.inseam,
                      MeasurementField.thigh,
                    ]),
                  ),
                  ActionChip(
                    label: const Text('Full Bespoke (All 18)'),
                    onPressed: () => _applyPreset(
                      MeasurementField.allFields.map((f) => f.key).toList(),
                    ),
                  ),
                  ActionChip(
                    label: const Text('Clear All'),
                    onPressed: () => _applyPreset([]),
                  ),
                ],
              ),
            ),

            // Checklist of All 18 Fields Grouped by Category
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: MeasurementCategory.values.map((cat) {
                  final fieldsInCat =
                      MeasurementField.allFields.where((f) => f.category == cat).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          cat.title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                            color: colors.accentVariant,
                          ),
                        ),
                      ),
                      ...fieldsInCat.map((field) {
                        final isChecked = _selectedKeys.contains(field.key);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            field.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                              color: colors.primaryText,
                            ),
                          ),
                          subtitle: Text(
                            field.instruction,
                            style: TextStyle(fontSize: 12, color: colors.secondaryText),
                          ),
                          value: isChecked,
                          activeColor: colors.primaryText,
                          onChanged: (bool? val) {
                            setState(() {
                              if (val == true) {
                                _selectedKeys.add(field.key);
                              } else {
                                _selectedKeys.remove(field.key);
                              }
                            });
                          },
                        );
                      }),
                      const Divider(height: 24),
                    ],
                  );
                }).toList(),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedKeys.length} measurement points selected',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.primaryText,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: colors.onAccent),
                          )
                        : const Text(
                            'SAVE GARMENT REQUIREMENTS',
                            style: TextStyle(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
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
