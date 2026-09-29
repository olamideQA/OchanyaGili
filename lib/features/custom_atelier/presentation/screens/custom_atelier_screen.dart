import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/analytics/data/analytics_service.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';
import 'package:ochanya_gili/features/custom_atelier/domain/models/custom_atelier_options.dart';
import 'package:ochanya_gili/features/custom_atelier/presentation/providers/custom_atelier_wizard_provider.dart';
import 'package:ochanya_gili/features/custom_atelier/presentation/utils/image_compression_helper.dart';
import 'package:ochanya_gili/features/measurements/data/measurements_repository.dart';
import 'package:ochanya_gili/features/measurements/presentation/widgets/dynamic_measurement_form.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/footer.dart';

class CustomAtelierScreen extends ConsumerStatefulWidget {
  const CustomAtelierScreen({super.key});

  @override
  ConsumerState<CustomAtelierScreen> createState() => _CustomAtelierScreenState();
}

class _CustomAtelierScreenState extends ConsumerState<CustomAtelierScreen> {
  final _linkController = TextEditingController();
  final _textController = TextEditingController();
  final _instructionsController = TextEditingController();

  final List<String> _stepTitles = [
    'Occasion',
    'Direction',
    'Inspiration & Moodboard',
    'Fabrication & Textile',
    'Colour & Palette',
    'Bespoke Measurements',
    'Review & Commission',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).trackCustomRequestStarted();
    });
  }

  @override
  void dispose() {
    _linkController.dispose();
    _textController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final wizard = ref.watch(customAtelierWizardProvider);
    final notifier = ref.read(customAtelierWizardProvider.notifier);
    final user = ref.watch(currentUserProvider).value;

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Editorial Header
                _buildEditorialHeader(colors),

                const SizedBox(height: 32),

                // Step Progression Indicator
                _buildProgressIndicator(wizard.currentStep, colors),

                const SizedBox(height: 36),

                // Step Body
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.border),
                  ),
                  child: _buildCurrentStepView(wizard, notifier, user?.id, colors),
                ),

                const SizedBox(height: 24),

                // Navigation Controls Bar
                _buildNavigationControls(wizard, notifier, user?.id, colors),
                  ],
                ),
              ),
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }

  Widget _buildEditorialHeader(AppColorTokens colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HAUTE COUTURE ATELIER',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 3.0,
            fontWeight: FontWeight.bold,
            color: colors.accentVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Create Your Look',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: colors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '“Your vision. Our craftsmanship.”',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 18,
            fontStyle: FontStyle.italic,
            color: colors.accentVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(int currentStep, AppColorTokens colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STEP ${currentStep + 1} OF 7: ${_stepTitles[currentStep].toUpperCase()}',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
                color: colors.primaryText,
              ),
            ),
            Text(
              '${((currentStep + 1) / 7 * 100).toInt()}% COMPLETED',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                color: colors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          child: LinearProgressIndicator(
            value: (currentStep + 1) / 7,
            backgroundColor: colors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(colors.accentVariant),
            minHeight: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepView(
    CustomAtelierWizardState wizard,
    CustomAtelierWizardNotifier notifier,
    String? userId,
    AppColorTokens colors,
  ) {
    switch (wizard.currentStep) {
      case 0:
        return _buildStepOccasion(wizard, notifier, colors);
      case 1:
        return _buildStepDirection(wizard, notifier, colors);
      case 2:
        return _buildStepInspiration(wizard, notifier, colors);
      case 3:
        return _buildStepFabric(wizard, notifier, colors);
      case 4:
        return _buildStepColour(wizard, notifier, colors);
      case 5:
        return _buildStepMeasurements(wizard, notifier, userId, colors);
      case 6:
        return _buildStepReview(wizard, notifier, userId, colors);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- STEP 1: OCCASION ---
  Widget _buildStepOccasion(
    CustomAtelierWizardState wizard,
    CustomAtelierWizardNotifier notifier,
    AppColorTokens colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select the Occasion for this Commission',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Our designers align garment proportions, weight, and movement with the ceremonial atmosphere of your event.',
          style: TextStyle(fontSize: 13, color: colors.secondaryText),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 280,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 130,
          ),
          itemCount: OccasionOption.all.length,
          itemBuilder: (context, index) {
            final option = OccasionOption.all[index];
            final isSelected = wizard.occasion == option.title;

            return InkWell(
              onTap: () => notifier.setOccasion(option.title),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? colors.surfaceVariant : colors.surface,
                  border: Border.all(
                    color: isSelected ? colors.accentVariant : colors.border,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(option.icon, size: 20, color: isSelected ? colors.accentVariant : colors.primaryText),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            option.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: colors.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: colors.secondaryText, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- STEP 2: DIRECTION ---
  Widget _buildStepDirection(
    CustomAtelierWizardState wizard,
    CustomAtelierWizardNotifier notifier,
    AppColorTokens colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Silhouette & Structural Direction',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select the foundational silhouette archetype. You will refine unique cut details in the next step.',
          style: TextStyle(fontSize: 13, color: colors.secondaryText),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 280,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 130,
          ),
          itemCount: DirectionOption.all.length,
          itemBuilder: (context, index) {
            final option = DirectionOption.all[index];
            final isSelected = wizard.direction == option.title;

            return InkWell(
              onTap: () => notifier.setDirection(option.title),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? colors.surfaceVariant : colors.surface,
                  border: Border.all(
                    color: isSelected ? colors.accentVariant : colors.border,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(option.icon, size: 20, color: isSelected ? colors.accentVariant : colors.primaryText),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            option.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: colors.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: colors.secondaryText, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- STEP 3: INSPIRATION ---
  Widget _buildStepInspiration(
    CustomAtelierWizardState wizard,
    CustomAtelierWizardNotifier notifier,
    AppColorTokens colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visual Inspiration & Moodboard',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Upload moodboard photographs, reference links, or describe the specific aesthetic details you envision.',
          style: TextStyle(fontSize: 13, color: colors.secondaryText),
        ),
        const SizedBox(height: 24),

        // Multi-image upload button
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final compressedFiles = await ImageCompressionHelper.pickAndCompressImages();
                if (compressedFiles.isNotEmpty) {
                  notifier.addImages(compressedFiles);
                }
              },
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('UPLOAD REFERENCE IMAGES'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryText,
                foregroundColor: colors.onAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${wizard.selectedImages.length} images added (client-side optimized)',
              style: TextStyle(fontSize: 12, color: colors.secondaryText),
            ),
          ],
        ),

        // Thumbnail Preview Gallery
        if (wizard.selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: wizard.selectedImages.length,
              itemBuilder: (context, index) {
                final file = wizard.selectedImages[index];
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.border),
                        color: colors.surfaceVariant,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 28, color: colors.accentVariant),
                            const SizedBox(height: 4),
                            Text(
                              file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 16,
                      child: InkWell(
                        onTap: () => notifier.removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          color: Colors.black.withValues(alpha: 0.7),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        // Pinterest / Instagram reference link
        Text(
          'PINTEREST / INSTAGRAM REFERENCE URL',
          style: TextStyle(fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: colors.primaryText),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _linkController,
                decoration: InputDecoration(
                  hintText: 'https://pinterest.com/pin/... or https://instagram.com/p/...',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.border),
                    borderRadius: BorderRadius.zero,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () {
                if (_linkController.text.trim().isNotEmpty) {
                  notifier.addInspirationLink(_linkController.text.trim());
                  _linkController.clear();
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryText,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('ADD LINK'),
            ),
          ],
        ),

        if (wizard.inspirationLinks.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: wizard.inspirationLinks.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value, maxLines: 1, overflow: TextOverflow.ellipsis),
                onDeleted: () => notifier.removeInspirationLink(entry.key),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 24),

        // Free-text vision & inspiration
        Text(
          'DESCRIBE YOUR VISION IN DETAIL',
          style: TextStyle(fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: colors.primaryText),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: wizard.inspirationText,
          maxLines: 4,
          onChanged: (val) => notifier.setInspirationText(val),
          decoration: InputDecoration(
            hintText: 'Mention neckline preference, train length, corsetry, boning, draping, or sleeve style...',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: colors.border),
              borderRadius: BorderRadius.zero,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  // --- STEP 4: FABRIC ---
  Widget _buildStepFabric(
    CustomAtelierWizardState wizard,
    CustomAtelierWizardNotifier notifier,
    AppColorTokens colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Atelier Fabric & Textile',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'All textiles are sourced from master European and African mills, chosen for structural memory and hand-feel.',
          style: TextStyle(fontSize: 13, color: colors.secondaryText),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 380,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 130,
          ),
          itemCount: FabricOption.all.length,
          itemBuilder: (context, index) {
            final option = FabricOption.all[index];
            final isSelected = wizard.fabric == option.name;

            return InkWell(
              onTap: () => notifier.setFabric(option.name),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? colors.surfaceVariant : colors.surface,
                  border: Border.all(
                    color: isSelected ? colors.accentVariant : colors.border,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      option.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.composition,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: colors.secondaryText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.feel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: colors.accentVariant),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- STEP 5: COLOUR ---
  Widget _buildStepColour(
    CustomAtelierWizardState wizard,
    CustomAtelierWizardNotifier notifier,
    AppColorTokens colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Primary Shade & Colour Palette',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose from our signature atelier palette, or designate a bespoke Pantone/shade during design consultation.',
          style: TextStyle(fontSize: 13, color: colors.secondaryText),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 90,
          ),
          itemCount: ColourOption.curatedPalette.length,
          itemBuilder: (context, index) {
            final option = ColourOption.curatedPalette[index];
            final isSelected = wizard.colour == option.name;

            return InkWell(
              onTap: () => notifier.setColour(option.name),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? colors.surfaceVariant : colors.surface,
                  border: Border.all(
                    color: isSelected ? colors.accentVariant : colors.border,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: option.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            option.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: colors.primaryText,
                            ),
                          ),
                          Text(
                            option.hex,
                            style: TextStyle(fontSize: 10, color: colors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- STEP 6: MEASUREMENTS ---
  Widget _buildStepMeasurements(
    CustomAtelierWizardState wizard,
    CustomAtelierWizardNotifier notifier,
    String? userId,
    AppColorTokens colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anatomical Measurements',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Custom haute couture garments are crafted to your exact anatomical proportions. You can use your saved profile or record new measurements.',
          style: TextStyle(fontSize: 13, color: colors.secondaryText),
        ),
        const SizedBox(height: 24),

        // Radio Selector: Saved vs New
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => notifier.setMeasurementOption('saved'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: wizard.measurementOption == 'saved' ? colors.surfaceVariant : colors.surface,
                    border: Border.all(
                      color: wizard.measurementOption == 'saved' ? colors.accentVariant : colors.border,
                      width: wizard.measurementOption == 'saved' ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        wizard.measurementOption == 'saved' ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: colors.accentVariant,
                      ),
                      const SizedBox(width: 10),
                      Text('USE SAVED PROFILE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.primaryText)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => notifier.setMeasurementOption('new'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: wizard.measurementOption == 'new' ? colors.surfaceVariant : colors.surface,
                    border: Border.all(
                      color: wizard.measurementOption == 'new' ? colors.accentVariant : colors.border,
                      width: wizard.measurementOption == 'new' ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        wizard.measurementOption == 'new' ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: colors.accentVariant,
                      ),
                      const SizedBox(width: 10),
                      Text('ENTER NEW MEASUREMENTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.primaryText)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        if (wizard.measurementOption == 'saved') ...[
          if (userId != null && userId.isNotEmpty)
            Consumer(
              builder: (context, ref, _) {
                final profilesAsync = ref.watch(userMeasurementProfilesProvider(userId));
                return profilesAsync.when(
                  loading: () => Center(child: CircularProgressIndicator(color: colors.primaryText)),
                  error: (e, _) => Text('Error loading profiles: $e'),
                  data: (profiles) {
                    if (profiles.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        color: colors.surfaceVariant,
                        child: Text('No saved profiles found. Please switch to "Enter New Measurements".', style: TextStyle(color: colors.secondaryText)),
                      );
                    }

                    return Column(
                      children: profiles.map((p) {
                        final isSelected = wizard.measurementProfileId == p.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: isSelected ? colors.primaryText : colors.border),
                            color: isSelected ? colors.surfaceVariant : colors.surface,
                          ),
                          child: ListTile(
                            onTap: () => notifier.setSavedMeasurementProfile(p.id, p.name),
                            leading: Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: colors.accentVariant),
                            title: Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, color: colors.primaryText)),
                            subtitle: Text('Unit: ${p.unit.toUpperCase()}  •  Bust: ${p.bust ?? "-"}  Waist: ${p.waist ?? "-"}  Hip: ${p.hip ?? "-"}', style: TextStyle(fontSize: 12, color: colors.secondaryText)),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            )
          else
            Text('Please sign in to select saved profiles, or enter new measurements below.', style: TextStyle(color: colors.secondaryText)),
        ] else ...[
          DynamicMeasurementForm(
            showProfileNameField: true,
            submitButtonLabel: 'CONFIRM BESPOKE MEASUREMENTS',
            onSubmit: (profile, _) async {
              notifier.setNewMeasurementProfile(profile);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Measurements recorded for this commission.')),
              );
            },
          ),
          if (wizard.newProfileData != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              color: colors.success.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.check, size: 16, color: colors.success),
                  const SizedBox(width: 8),
                  Text('New measurements saved for this commission: ${wizard.newProfileData!.name}', style: TextStyle(color: colors.success, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],

        const SizedBox(height: 24),
        Text(
          'SPECIAL ATELIER INSTRUCTIONS (OPTIONAL)',
          style: TextStyle(fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: colors.primaryText),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: wizard.specialInstructions,
          maxLines: 3,
          onChanged: (val) => notifier.setSpecialInstructions(val),
          decoration: InputDecoration(
            hintText: 'E.g. Target fitting date, travel dates, preferred closure type (corset lacing vs hidden zip)...',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: colors.border),
              borderRadius: BorderRadius.zero,
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  // --- STEP 7: REVIEW ---
  Widget _buildStepReview(
    CustomAtelierWizardState wizard,
    CustomAtelierWizardNotifier notifier,
    String? userId,
    AppColorTokens colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Your Atelier Commission Dossier',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Please verify all commission details below before submitting your design request to our master tailor.',
          style: TextStyle(fontSize: 13, color: colors.secondaryText),
        ),
        const SizedBox(height: 24),

        _buildReviewRow('OCCASION', wizard.occasion ?? 'Not specified', colors),
        _buildReviewRow('SILHOUETTE DIRECTION', wizard.direction ?? 'Not specified', colors),
        _buildReviewRow('SELECTED TEXTILE', wizard.fabric ?? 'Not specified', colors),
        _buildReviewRow('COLOUR PALETTE', wizard.colour ?? 'Not specified', colors),
        _buildReviewRow(
          'MEASUREMENTS SOURCE',
          wizard.measurementOption == 'saved'
              ? 'Saved Profile (${wizard.measurementProfileName ?? "Selected"})'
              : 'New Custom Profile (${wizard.newProfileData?.name ?? "Recorded"})',
          colors,
        ),
        _buildReviewRow('REFERENCE IMAGES', '${wizard.selectedImages.length} photographs uploaded', colors),
        if (wizard.inspirationLinks.isNotEmpty)
          _buildReviewRow('INSPIRATION LINKS', wizard.inspirationLinks.join(', '), colors),
        if (wizard.inspirationText.trim().isNotEmpty)
          _buildReviewRow('VISION & NOTES', wizard.inspirationText, colors),
        if (wizard.specialInstructions.trim().isNotEmpty)
          _buildReviewRow('SPECIAL INSTRUCTIONS', wizard.specialInstructions, colors),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          color: colors.accentVariant.withValues(alpha: 0.1),
          child: Row(
            children: [
              Icon(Icons.workspace_premium, size: 24, color: colors.accentVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Submitting this request alerts our head designer and creates an entry in your customer dossier. You will receive private sketch options and a formal quote within 48 hours.',
                  style: TextStyle(fontSize: 12, height: 1.5, color: colors.primaryText),
                ),
              ),
            ],
          ),
        ),

        if (wizard.errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            color: colors.error.withValues(alpha: 0.1),
            child: Text(wizard.errorMessage!, style: TextStyle(color: colors.error, fontSize: 13)),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, AppColorTokens colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                color: colors.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls(
    CustomAtelierWizardState wizard,
    CustomAtelierWizardNotifier notifier,
    String? userId,
    AppColorTokens colors,
  ) {
    final canAdvance = wizard.canAdvanceFromStep(wizard.currentStep);
    final isLastStep = wizard.currentStep == 6;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (wizard.currentStep > 0)
          OutlinedButton(
            onPressed: () => notifier.prevStep(),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primaryText,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('PREVIOUS STEP'),
          )
        else
          const SizedBox.shrink(),

        if (!isLastStep)
          ElevatedButton(
            onPressed: canAdvance ? () => notifier.nextStep() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('NEXT STEP'),
          )
        else
          ElevatedButton(
            onPressed: wizard.isSubmitting
                ? null
                : () async {
                    if (userId == null) {
                      context.go('/login');
                      return;
                    }
                    final res = await notifier.submit(userId);
                    if (res != null && mounted) {
                      ref.read(analyticsServiceProvider).trackCustomRequestCompleted(
                            requestId: res.id,
                            garmentType: wizard.direction ?? 'Bespoke',
                          );
                      _showSubmissionSuccessDialog(context, res.requestNumber, colors);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: wizard.isSubmitting
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.onAccent),
                  )
                : const Text(
                    'SUBMIT DESIGN REQUEST',
                    style: TextStyle(letterSpacing: 2.0, fontWeight: FontWeight.bold),
                  ),
          ),
      ],
    );
  }

  void _showSubmissionSuccessDialog(
    BuildContext context,
    String requestNumber,
    AppColorTokens colors,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Commission Request Received',
          style: TextStyle(fontFamily: 'Playfair Display', color: colors.primaryText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your bespoke request has entered the atelier queue under reference:',
              style: TextStyle(fontSize: 13, color: colors.secondaryText),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: colors.accentVariant.withValues(alpha: 0.15),
              child: Text(
                requestNumber,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: colors.accentVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Our head designer is reviewing your moodboard and proportions. You will be contacted shortly for your private sketch consultation.',
              style: TextStyle(fontSize: 13, height: 1.5, color: colors.primaryText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/account/custom-requests');
            },
            child: const Text('VIEW MY REQUESTS'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
            ),
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('RETURN HOME'),
          ),
        ],
      ),
    );
  }
}
