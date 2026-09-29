import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/measurements/data/measurements_repository.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_field.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_profile.dart';

class AdminCustomerMeasurementsScreen extends ConsumerWidget {
  final String customerId;

  const AdminCustomerMeasurementsScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final profilesAsync = ref.watch(userMeasurementProfilesProvider(customerId));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Customer Anatomical Profiles'),
        backgroundColor: colors.surface,
        foregroundColor: colors.primaryText,
        elevation: 0,
      ),
      body: profilesAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.primaryText),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.straighten, size: 48, color: colors.secondaryText),
                    const SizedBox(height: 16),
                    Text(
                      'No saved measurement profiles for this customer.',
                      style: TextStyle(color: colors.secondaryText, fontSize: 15),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return _buildProfileDossier(context, profile, colors);
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileDossier(
    BuildContext context,
    MeasurementProfile profile,
    AppColorTokens colors,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: profile.isDefault ? colors.accentVariant : colors.border,
          width: profile.isDefault ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: colors.surfaceVariant,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (profile.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: colors.accentVariant.withValues(alpha: 0.2),
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
                ),
                Text(
                  'Unit: ${profile.unit.toUpperCase()}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.secondaryText),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 20,
              runSpacing: 14,
              children: MeasurementField.allFields
                  .where((f) => profile.isFieldFilled(f.key))
                  .map((f) {
                final val = profile.getValue(f.key);
                return SizedBox(
                  width: 130,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: colors.secondaryText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$val ${profile.unit == "inches" ? "in" : "cm"}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.primaryText,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          if (profile.notes != null && profile.notes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: colors.surfaceVariant.withValues(alpha: 0.5),
              child: Text(
                'Client Notes: ${profile.notes}',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: colors.secondaryText),
              ),
            ),
        ],
      ),
    );
  }
}
