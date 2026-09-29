import 'package:flutter/material.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_field.dart';

class MeasurementGuideModal extends StatefulWidget {
  final String? initialFieldKey;

  const MeasurementGuideModal({super.key, this.initialFieldKey});

  static Future<void> show(BuildContext context, {String? initialFieldKey}) {
    return showDialog(
      context: context,
      builder: (context) => MeasurementGuideModal(initialFieldKey: initialFieldKey),
    );
  }

  @override
  State<MeasurementGuideModal> createState() => _MeasurementGuideModalState();
}

class _MeasurementGuideModalState extends State<MeasurementGuideModal> {
  late String _selectedKey;
  MeasurementCategory _selectedCategory = MeasurementCategory.upperBody;

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.initialFieldKey ?? MeasurementField.bust;
    final initialField = MeasurementField.byKey(_selectedKey);
    _selectedCategory = initialField.category;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final currentField = MeasurementField.byKey(_selectedKey);

    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 780),
        child: Column(
          children: [
            // Modal Header
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
                          'OCHANYA GILI ATELIER',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2.5,
                            color: colors.accentVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Anatomical Bespoke Measurement Guide',
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 22,
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

            // Category Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: colors.surfaceVariant,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: MeasurementCategory.values.map((cat) {
                    final isCatSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(cat.title),
                        selected: isCatSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat;
                              final firstInCat = MeasurementField.allFields
                                  .firstWhere((f) => f.category == cat);
                              _selectedKey = firstInCat.key;
                            });
                          }
                        },
                        selectedColor: colors.primaryText,
                        labelStyle: TextStyle(
                          color: isCatSelected ? colors.onAccent : colors.primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: colors.surface,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: isCatSelected ? colors.primaryText : colors.border),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Main Content Area
            Expanded(
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left: Field Selector List
                        SizedBox(
                          width: 320,
                          child: _buildFieldList(colors),
                        ),
                        VerticalDivider(width: 1, color: colors.border),
                        // Right: Interactive Dossier
                        Expanded(
                          child: _buildFieldDossier(currentField, colors),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: 60,
                          child: _buildFieldHorizontalChips(colors),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: _buildFieldDossier(currentField, colors),
                        ),
                      ],
                    ),
            ),

            // Modal Footer Tip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              color: colors.surfaceVariant,
              child: Row(
                children: [
                  Icon(Icons.straighten, size: 18, color: colors.accentVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'For haute couture creations, we recommend measuring twice or visiting our Abuja Salon for complimentary bespoke tailoring.',
                      style: TextStyle(fontSize: 12, color: colors.secondaryText),
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

  Widget _buildFieldList(AppColorTokens colors) {
    final fieldsInCat =
        MeasurementField.allFields.where((f) => f.category == _selectedCategory).toList();

    return ListView.builder(
      itemCount: fieldsInCat.length,
      itemBuilder: (context, index) {
        final field = fieldsInCat[index];
        final isSelected = field.key == _selectedKey;

        return ListTile(
          selected: isSelected,
          selectedTileColor: colors.surfaceVariant,
          title: Text(
            field.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? colors.accentVariant : colors.primaryText,
            ),
          ),
          subtitle: Text(
            'Typical: ${field.sampleInches}" / ${field.sampleCm}cm',
            style: TextStyle(fontSize: 11, color: colors.secondaryText),
          ),
          trailing: isSelected
              ? Icon(Icons.arrow_forward_ios, size: 14, color: colors.accentVariant)
              : null,
          onTap: () {
            setState(() {
              _selectedKey = field.key;
            });
          },
        );
      },
    );
  }

  Widget _buildFieldHorizontalChips(AppColorTokens colors) {
    final fieldsInCat =
        MeasurementField.allFields.where((f) => f.category == _selectedCategory).toList();

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: fieldsInCat.length,
      itemBuilder: (context, index) {
        final field = fieldsInCat[index];
        final isSelected = field.key == _selectedKey;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(field.label),
            backgroundColor: isSelected ? colors.primaryText : colors.surface,
            labelStyle: TextStyle(
              color: isSelected ? colors.onAccent : colors.primaryText,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            onPressed: () => setState(() => _selectedKey = field.key),
          ),
        );
      },
    );
  }

  Widget _buildFieldDossier(MeasurementField field, AppColorTokens colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Silhouette Illustration Card
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(field.category),
                    size: 54,
                    color: colors.accentVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'POINT OF ANATOMICAL MEASUREMENT: ${field.label.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                      color: colors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Field Title & Tag
          Row(
            children: [
              Text(
                field.label,
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colors.primaryText,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: colors.accentVariant.withValues(alpha: 0.15),
                child: Text(
                  field.category.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: colors.accentVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // How to Measure
          Text(
            'HOW TO MEASURE',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
              color: colors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            field.instruction,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 24),

          // Master Tailor Advice Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: colors.accentVariant, width: 3)),
              color: colors.surfaceVariant.withValues(alpha: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: colors.accentVariant),
                    const SizedBox(width: 8),
                    Text(
                      'OCHANYA GILI ATELIER TIP',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                        color: colors.accentVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  field.atelierTip,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: colors.primaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Baseline Proportions
          Row(
            children: [
              Text(
                'Reference Standard: ',
                style: TextStyle(fontSize: 13, color: colors.secondaryText),
              ),
              Text(
                '${field.sampleInches}" (${field.sampleCm} cm)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.primaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(MeasurementCategory cat) {
    switch (cat) {
      case MeasurementCategory.upperBody:
        return Icons.person_outline;
      case MeasurementCategory.lowerBody:
        return Icons.accessibility_new;
      case MeasurementCategory.lengths:
        return Icons.height;
      case MeasurementCategory.arms:
        return Icons.pan_tool_outlined;
    }
  }
}
