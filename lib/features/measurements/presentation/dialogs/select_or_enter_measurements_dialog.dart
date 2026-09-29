import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/measurements/data/measurements_repository.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_field.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_profile.dart';
import 'package:ochanya_gili/features/measurements/presentation/providers/measurements_controller.dart';
import 'package:ochanya_gili/features/measurements/presentation/widgets/dynamic_measurement_form.dart';
import 'package:ochanya_gili/features/shop/domain/models/product.dart';

class SelectOrEnterMeasurementsDialog extends ConsumerStatefulWidget {
  final Product product;
  final String? userId;

  const SelectOrEnterMeasurementsDialog({
    super.key,
    required this.product,
    this.userId,
  });

  static Future<(String profileId, String profileName)?> show(
    BuildContext context, {
    required Product product,
    String? userId,
  }) {
    return showDialog<(String, String)?>(
      context: context,
      barrierDismissible: true,
      builder: (context) => SelectOrEnterMeasurementsDialog(
        product: product,
        userId: userId,
      ),
    );
  }

  @override
  ConsumerState<SelectOrEnterMeasurementsDialog> createState() =>
      _SelectOrEnterMeasurementsDialogState();
}

class _SelectOrEnterMeasurementsDialogState
    extends ConsumerState<SelectOrEnterMeasurementsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MeasurementProfile? _selectedSavedProfile;
  final Map<String, TextEditingController> _missingControllers = {};
  bool _isSavingMissing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _missingControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initMissingControllers(List<String> missing) {
    for (final key in missing) {
      if (!_missingControllers.containsKey(key)) {
        _missingControllers[key] = TextEditingController();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final userId = widget.userId;
    final requiredKeys = widget.product.effectiveRequiredMeasurements;

    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
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
                          'MADE-TO-ORDER ATELIER FIT',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2.5,
                            color: colors.accentVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.name,
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 20,
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

            // Tab Bar
            TabBar(
              controller: _tabController,
              indicatorColor: colors.primaryText,
              labelColor: colors.primaryText,
              unselectedLabelColor: colors.secondaryText,
              tabs: const [
                Tab(text: 'USE SAVED PROFILE'),
                Tab(text: 'RECORD NEW MEASUREMENTS'),
              ],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Saved Profiles
                  _buildSavedProfilesTab(colors, userId, requiredKeys),

                  // Tab 2: New Measurements Form
                  _buildNewMeasurementsTab(colors, userId, requiredKeys),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedProfilesTab(
    AppColorTokens colors,
    String? userId,
    List<String> requiredKeys,
  ) {
    if (userId == null || userId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: colors.secondaryText),
              const SizedBox(height: 16),
              Text(
                'SIGN IN TO ACCESS SAVED MEASUREMENTS',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: colors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Log in to use your saved anatomical profiles, or enter measurements manually using the second tab.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.secondaryText),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.onAccent,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: const Text('SIGN IN'),
              ),
            ],
          ),
        ),
      );
    }

    final profilesAsync = ref.watch(userMeasurementProfilesProvider(userId));

    return profilesAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: colors.primaryText),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (profiles) {
        if (profiles.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.straighten, size: 48, color: colors.secondaryText),
                  const SizedBox(height: 16),
                  Text(
                    'NO SAVED PROFILES FOUND',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You do not have any saved measurement profiles yet. Enter your measurements on the next tab to save your first profile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: colors.secondaryText),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => _tabController.animateTo(1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primaryText,
                      side: BorderSide(color: colors.primaryText),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: const Text('ENTER MEASUREMENTS'),
                  ),
                ],
              ),
            ),
          );
        }

        // Auto-select first or default if not selected
        _selectedSavedProfile ??= profiles.firstWhere(
          (p) => p.isDefault,
          orElse: () => profiles.first,
        );

        final selected = _selectedSavedProfile!;
        final missingKeys = selected.getMissingFields(requiredKeys);
        _initMissingControllers(missingKeys);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECT ANATOMICAL PROFILE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                  color: colors.secondaryText,
                ),
              ),
              const SizedBox(height: 12),

              // Profile Selector Dropdown / Cards
              ...profiles.map((profile) {
                final isSelected = profile.id == selected.id;
                final isComplete = profile.hasAllRequiredFields(requiredKeys);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? colors.primaryText : colors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    color: isSelected ? colors.surfaceVariant : colors.surface,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () => setState(() => _selectedSavedProfile = profile),
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? colors.accentVariant : colors.secondaryText,
                    ),
                    title: Row(
                      children: [
                        Text(
                          profile.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colors.primaryText,
                          ),
                        ),
                        if (profile.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: colors.accentVariant.withValues(alpha: 0.15),
                            child: Text(
                              'DEFAULT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: colors.accentVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Unit: ${profile.unit.toUpperCase()}',
                        style: TextStyle(fontSize: 12, color: colors.secondaryText),
                      ),
                    ),
                    trailing: isComplete
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 16, color: colors.success),
                              const SizedBox(width: 4),
                              Text(
                                'READY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colors.success,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber, size: 16, color: colors.warning),
                              const SizedBox(width: 4),
                              Text(
                                '${profile.getMissingFields(requiredKeys).length} REQUIRED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colors.warning,
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Missing measurements dynamic completion section
              if (missingKeys.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.warning.withValues(alpha: 0.08),
                    border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.straighten, size: 16, color: colors.warning),
                          const SizedBox(width: 8),
                          Text(
                            'COMPLETE REQUIRED POINTS FOR THIS PIECE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: colors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This garment requires ${missingKeys.length} additional anatomical measurements not yet saved in "${selected.name}":',
                        style: TextStyle(fontSize: 13, color: colors.primaryText),
                      ),
                      const SizedBox(height: 16),
                      ...missingKeys.map((key) {
                        final field = MeasurementField.byKey(key);
                        final controller = _missingControllers[key]!;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: '${field.label.toUpperCase()} *',
                              suffixText: selected.unit == 'inches' ? 'in' : 'cm',
                              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Confirmation button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSavingMissing
                      ? null
                      : () async {
                          if (missingKeys.isNotEmpty) {
                            // Validate missing inputs
                            for (final k in missingKeys) {
                              final text = _missingControllers[k]?.text.trim();
                              final val = double.tryParse(text ?? '');
                              if (val == null || val <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please enter ${MeasurementField.byKey(k).label}'),
                                  ),
                                );
                                return;
                              }
                            }

                            // Save missing fields to profile
                            setState(() => _isSavingMissing = true);
                            try {
                              var updated = selected;
                              for (final k in missingKeys) {
                                final val = double.parse(_missingControllers[k]!.text.trim());
                                updated = updated.copyWithField(k, val);
                              }
                              await ref
                                  .read(measurementsControllerProvider.notifier)
                                  .saveProfile(updated);
                              if (mounted) {
                                Navigator.of(context).pop((updated.id, updated.name));
                              }
                            } finally {
                              if (mounted) setState(() => _isSavingMissing = false);
                            }
                          } else {
                            Navigator.of(context).pop((selected.id, selected.name));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: _isSavingMissing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: colors.onAccent),
                        )
                      : Text(
                          missingKeys.isEmpty
                              ? 'CONFIRM MEASUREMENTS & ADD TO BAG'
                              : 'UPDATE PROFILE & ADD TO BAG',
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
      },
    );
  }

  Widget _buildNewMeasurementsTab(
    AppColorTokens colors,
    String? userId,
    List<String> requiredKeys,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: DynamicMeasurementForm(
        requiredFields: requiredKeys,
        showProfileNameField: userId != null && userId.isNotEmpty,
        showSaveProfileCheckbox: userId != null && userId.isNotEmpty,
        submitButtonLabel: 'CONFIRM MEASUREMENTS & ADD TO BAG',
        onSubmit: (profile, saveAsProfile) async {
          if (userId != null && userId.isNotEmpty) {
            final profileToSave = profile.copyWith(profileId: userId);
            final saved = await ref
                .read(measurementsControllerProvider.notifier)
                .saveProfile(profileToSave);
            if (mounted) {
              Navigator.of(context).pop((saved?.id ?? '', saved?.name ?? 'Custom Profile'));
            }
          } else {
            // Unauthenticated guest order
            if (mounted) {
              Navigator.of(context).pop(('guest_${DateTime.now().millisecondsSinceEpoch}', 'Custom Order Measurements'));
            }
          }
        },
      ),
    );
  }
}
