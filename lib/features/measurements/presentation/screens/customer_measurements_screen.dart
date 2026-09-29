import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';
import 'package:ochanya_gili/features/measurements/data/measurements_repository.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_field.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_profile.dart';
import 'package:ochanya_gili/features/measurements/presentation/providers/measurements_controller.dart';
import 'package:ochanya_gili/features/measurements/presentation/widgets/dynamic_measurement_form.dart';
import 'package:ochanya_gili/features/measurements/presentation/widgets/measurement_guide_modal.dart';

class CustomerMeasurementsScreen extends ConsumerStatefulWidget {
  const CustomerMeasurementsScreen({super.key});

  @override
  ConsumerState<CustomerMeasurementsScreen> createState() =>
      _CustomerMeasurementsScreenState();
}

class _CustomerMeasurementsScreenState
    extends ConsumerState<CustomerMeasurementsScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: userAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.primaryText),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                'Please sign in to manage your anatomical profiles.',
                style: TextStyle(color: colors.primaryText),
              ),
            );
          }

          final profilesAsync =
              ref.watch(userMeasurementProfilesProvider(user.id));

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ATELIER DOSSIER',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 2.5,
                                color: colors.accentVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Bespoke Measurements',
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your individual anatomical profiles used across Made-to-Order and Custom Couture commissions.',
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => MeasurementGuideModal.show(context),
                              icon: Icon(Icons.menu_book, size: 16, color: colors.primaryText),
                              label: const Text('MEASUREMENT GUIDE'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.primaryText,
                                side: BorderSide(color: colors.border),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => _openProfileEditor(context, user.id, null),
                              icon: Icon(Icons.add, size: 16, color: colors.onAccent),
                              label: const Text('NEW PROFILE'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.accent,
                                foregroundColor: colors.onAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // Profiles List
                    profilesAsync.when(
                      loading: () => Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Center(
                          child: CircularProgressIndicator(color: colors.primaryText),
                        ),
                      ),
                      error: (e, _) => Center(child: Text('Error loading profiles: $e')),
                      data: (profiles) {
                        if (profiles.isEmpty) {
                          return _buildEmptyState(context, user.id, colors);
                        }

                        return Column(
                          children: profiles
                              .map((p) => _buildProfileCard(context, p, user.id, colors))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String userId, AppColorTokens colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.straighten_outlined, size: 56, color: colors.accentVariant),
          const SizedBox(height: 16),
          Text(
            'NO ANATOMICAL PROFILES RECORDED',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              'Save your proportions once to experience effortless made-to-order commissions. Our master tailors preserve your pattern for perfect fitting across all silhouettes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.6, color: colors.secondaryText),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _openProfileEditor(context, userId, null),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('RECORD MY FIRST MEASUREMENT PROFILE'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    MeasurementProfile profile,
    String userId,
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
          // Profile Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      color: colors.primaryText,
                      child: Text(
                        profile.unit.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colors.onAccent,
                        ),
                      ),
                    ),
                    if (profile.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        color: colors.accentVariant.withValues(alpha: 0.2),
                        child: Text(
                          'DEFAULT PROFILE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.bold,
                            color: colors.accentVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: colors.primaryText),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openProfileEditor(context, userId, profile);
                    } else if (val == 'default') {
                      ref
                          .read(measurementsControllerProvider.notifier)
                          .setDefault(profile.id, userId);
                    } else if (val == 'delete') {
                      _confirmDelete(context, profile.id, userId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
                    if (!profile.isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Text('Set as Default'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Profile', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Profile Body: Key Anatomical Metrics Grid
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: MeasurementField.allFields
                      .where((f) => profile.isFieldFilled(f.key))
                      .map((f) {
                    final val = profile.getValue(f.key);
                    return Container(
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant.withValues(alpha: 0.4),
                        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.2,
                              color: colors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$val ${profile.unit == "inches" ? "in" : "cm"}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                if (profile.notes != null && profile.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: colors.surfaceVariant,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, size: 16, color: colors.secondaryText),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            profile.notes!,
                            style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: colors.secondaryText),
                          ),
                        ),
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

  void _openProfileEditor(
    BuildContext context,
    String userId,
    MeasurementProfile? existing,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final colors = Theme.of(context).extension<AppColorTokens>()!;
        return Dialog(
          backgroundColor: colors.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820, maxHeight: 820),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing != null ? 'EDIT ANATOMICAL PROFILE' : 'RECORD NEW PROFILE',
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.primaryText,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: DynamicMeasurementForm(
                      initialProfile: existing,
                      profileNameHint: 'e.g. Self - Gala Silhouette',
                      showProfileNameField: true,
                      submitButtonLabel:
                          existing != null ? 'UPDATE PROFILE' : 'SAVE ATELIER PROFILE',
                      onSubmit: (profile, _) async {
                        final toSave = profile.copyWith(
                          profileId: userId,
                          id: existing?.id ?? '',
                        );
                        await ref
                            .read(measurementsControllerProvider.notifier)
                            .saveProfile(toSave);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                existing != null
                                    ? 'Profile updated successfully.'
                                    : 'New measurement profile preserved.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String profileId, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: const Text(
          'Are you sure you wish to delete this saved anatomical profile? Future orders will require re-entering these measurements.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref
                  .read(measurementsControllerProvider.notifier)
                  .deleteProfile(profileId, userId);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
