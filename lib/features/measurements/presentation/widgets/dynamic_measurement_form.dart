import 'package:flutter/material.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_field.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_profile.dart';
import 'package:ochanya_gili/features/measurements/presentation/widgets/measurement_guide_modal.dart';

class DynamicMeasurementForm extends StatefulWidget {
  final MeasurementProfile? initialProfile;
  final List<String>? requiredFields; // If non-null and not empty, renders ONLY these fields
  final String? profileNameHint;
  final bool showProfileNameField;
  final bool showSaveProfileCheckbox;
  final String submitButtonLabel;
  final Future<void> Function(MeasurementProfile profile, bool saveAsProfile) onSubmit;

  const DynamicMeasurementForm({
    super.key,
    this.initialProfile,
    this.requiredFields,
    this.profileNameHint,
    this.showProfileNameField = true,
    this.showSaveProfileCheckbox = false,
    this.submitButtonLabel = 'SAVE MEASUREMENTS',
    required this.onSubmit,
  });

  @override
  State<DynamicMeasurementForm> createState() => _DynamicMeasurementFormState();
}

class _DynamicMeasurementFormState extends State<DynamicMeasurementForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  final Map<String, TextEditingController> _fieldControllers = {};

  String _unit = 'inches';
  bool _saveAsProfile = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _unit = widget.initialProfile?.unit ?? 'inches';
    _saveAsProfile = widget.showSaveProfileCheckbox;

    _nameController = TextEditingController(
      text: widget.initialProfile?.name ?? widget.profileNameHint ?? 'My Measurements',
    );
    _notesController = TextEditingController(
      text: widget.initialProfile?.notes ?? '',
    );

    _initControllers();
  }

  void _initControllers() {
    for (final field in MeasurementField.allFields) {
      final existingVal = widget.initialProfile?.getValue(field.key);
      _fieldControllers[field.key] = TextEditingController(
        text: existingVal != null && existingVal > 0 ? existingVal.toString() : '',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose;
    _notesController.dispose;
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _switchUnit(String newUnit) {
    if (newUnit == _unit) return;
    setState(() {
      for (final entry in _fieldControllers.entries) {
        final val = double.tryParse(entry.value.text);
        if (val != null && val > 0) {
          if (newUnit == 'cm') {
            // inches -> cm
            entry.value.text = (val * 2.54).toStringAsFixed(1);
          } else {
            // cm -> inches
            entry.value.text = (val / 2.54).toStringAsFixed(1);
          }
        }
      }
      _unit = newUnit;
    });
  }

  List<MeasurementField> get _renderedFields {
    if (widget.requiredFields != null && widget.requiredFields!.isNotEmpty) {
      return MeasurementField.forKeys(widget.requiredFields!);
    }
    return MeasurementField.allFields;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final base = widget.initialProfile ??
          MeasurementProfile(
            id: '',
            profileId: '',
            unit: _unit,
          );

      var updated = base.copyWith(
        name: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : 'My Measurements',
        unit: _unit,
        notes: _notesController.text.trim(),
      );

      for (final entry in _fieldControllers.entries) {
        final val = double.tryParse(entry.value.text.trim());
        updated = updated.copyWithField(entry.key, val);
      }

      await widget.onSubmit(updated, _saveAsProfile);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final fieldsToRender = _renderedFields;
    final isSelectiveGarmentMode =
        widget.requiredFields != null && widget.requiredFields!.isNotEmpty;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Unit Selector & Guide Button Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Unit toggle
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.border),
                  color: colors.surfaceVariant,
                ),
                child: Row(
                  children: [
                    _unitChoiceButton('INCHES', 'inches', colors),
                    _unitChoiceButton('CENTIMETRES', 'cm', colors),
                  ],
                ),
              ),
              // Guide quick link
              TextButton.icon(
                onPressed: () => MeasurementGuideModal.show(context),
                icon: Icon(Icons.help_outline, size: 16, color: colors.accentVariant),
                label: Text(
                  'ATELIER GUIDE',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: colors.accentVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Profile Name (if full profile mode)
          if (widget.showProfileNameField) ...[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'PROFILE NAME',
                labelStyle: TextStyle(fontSize: 11, letterSpacing: 1.5, color: colors.secondaryText),
                hintText: 'e.g. Gala Evening Fit, Wedding Bespoke',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.border),
                  borderRadius: BorderRadius.zero,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please name this measurement profile.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],

          if (isSelectiveGarmentMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: colors.accentVariant.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.straighten, size: 16, color: colors.accentVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This bespoke piece requires ${fieldsToRender.length} specific anatomical points.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Render Fields Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 540;
              final crossAxisCount = isWide ? 2 : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 88,
                ),
                itemCount: fieldsToRender.length,
                itemBuilder: (context, index) {
                  final field = fieldsToRender[index];
                  final isRequired = isSelectiveGarmentMode ||
                      (widget.requiredFields != null &&
                          widget.requiredFields!.contains(field.key));

                  return _buildFieldInput(field, isRequired, colors);
                },
              );
            },
          ),

          // Notes
          const SizedBox(height: 20),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'ATELIER FIT NOTES & POSTURE REMARKS (OPTIONAL)',
              labelStyle: TextStyle(fontSize: 11, letterSpacing: 1.5, color: colors.secondaryText),
              hintText: 'e.g. Higher right shoulder, prefer relaxed waist ease, 4-inch heel height planned.',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: colors.border),
                borderRadius: BorderRadius.zero,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          if (widget.showSaveProfileCheckbox) ...[
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Save this anatomical profile for future atelier orders',
                style: TextStyle(fontSize: 13, color: colors.primaryText),
              ),
              value: _saveAsProfile,
              activeColor: colors.primaryText,
              onChanged: (val) => setState(() => _saveAsProfile = val ?? false),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              color: colors.error.withValues(alpha: 0.1),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: colors.error, fontSize: 13),
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.onAccent),
                    )
                  : Text(
                      widget.submitButtonLabel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitChoiceButton(String label, String unitValue, AppColorTokens colors) {
    final isSelected = _unit == unitValue;
    return InkWell(
      onTap: () => _switchUnit(unitValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: isSelected ? colors.primaryText : Colors.transparent,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? colors.onAccent : colors.primaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildFieldInput(MeasurementField field, bool isRequired, AppColorTokens colors) {
    final controller = _fieldControllers[field.key]!;

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: '${field.label.toUpperCase()}${isRequired ? " *" : ""}',
        labelStyle: TextStyle(
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
          color: colors.primaryText,
        ),
        suffixText: _unit == 'inches' ? 'in' : 'cm',
        suffixIcon: IconButton(
          icon: Icon(Icons.info_outline, size: 16, color: colors.secondaryText),
          onPressed: () => MeasurementGuideModal.show(context, initialFieldKey: field.key),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: colors.border),
          borderRadius: BorderRadius.zero,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: (val) {
        if (isRequired) {
          if (val == null || val.trim().isEmpty) {
            return '${field.label} required';
          }
          final numVal = double.tryParse(val.trim());
          if (numVal == null || numVal <= 0) {
            return 'Enter valid value';
          }
        }
        return null;
      },
    );
  }
}
