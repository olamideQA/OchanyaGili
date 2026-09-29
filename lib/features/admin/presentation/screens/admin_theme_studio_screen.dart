import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';
import 'package:ochanya_gili/features/cms/domain/models/dynamic_theme_tokens.dart';

class AdminThemeStudioScreen extends ConsumerStatefulWidget {
  const AdminThemeStudioScreen({super.key});

  @override
  ConsumerState<AdminThemeStudioScreen> createState() => _AdminThemeStudioScreenState();
}

class _AdminThemeStudioScreenState extends ConsumerState<AdminThemeStudioScreen> {
  final _accentCtrl = TextEditingController();
  final _accentVariantCtrl = TextEditingController();
  final _bgCtrl = TextEditingController();
  final _surfaceCtrl = TextEditingController();
  final _surfaceVariantCtrl = TextEditingController();
  final _primaryTextCtrl = TextEditingController();
  final _secondaryTextCtrl = TextEditingController();
  final _borderCtrl = TextEditingController();

  bool _isSaving = false;
  bool _tokensLoaded = false;

  @override
  void dispose() {
    _accentCtrl.dispose();
    _accentVariantCtrl.dispose();
    _bgCtrl.dispose();
    _surfaceCtrl.dispose();
    _surfaceVariantCtrl.dispose();
    _primaryTextCtrl.dispose();
    _secondaryTextCtrl.dispose();
    _borderCtrl.dispose();
    super.dispose();
  }

  void _initFromTokens(DynamicThemeTokens tokens) {
    if (!_tokensLoaded) {
      _applyTokens(tokens);
      _tokensLoaded = true;
    }
  }

  void _applyTokens(DynamicThemeTokens tokens) {
    _accentCtrl.text = tokens.accentHex;
    _accentVariantCtrl.text = tokens.accentVariantHex;
    _bgCtrl.text = tokens.backgroundHex;
    _surfaceCtrl.text = tokens.surfaceHex;
    _surfaceVariantCtrl.text = tokens.surfaceVariantHex;
    _primaryTextCtrl.text = tokens.primaryTextHex;
    _secondaryTextCtrl.text = tokens.secondaryTextHex;
    _borderCtrl.text = tokens.borderHex;
    setState(() {});
  }

  DynamicThemeTokens _getCurrentDraft() {
    return DynamicThemeTokens(
      accentHex: _accentCtrl.text.trim().isEmpty ? '#1A1A1A' : _accentCtrl.text.trim(),
      accentVariantHex: _accentVariantCtrl.text.trim().isEmpty ? '#C9A96E' : _accentVariantCtrl.text.trim(),
      backgroundHex: _bgCtrl.text.trim().isEmpty ? '#FAFAFA' : _bgCtrl.text.trim(),
      surfaceHex: _surfaceCtrl.text.trim().isEmpty ? '#FFFFFF' : _surfaceCtrl.text.trim(),
      surfaceVariantHex: _surfaceVariantCtrl.text.trim().isEmpty ? '#F5F5F5' : _surfaceVariantCtrl.text.trim(),
      primaryTextHex: _primaryTextCtrl.text.trim().isEmpty ? '#1A1A1A' : _primaryTextCtrl.text.trim(),
      secondaryTextHex: _secondaryTextCtrl.text.trim().isEmpty ? '#757575' : _secondaryTextCtrl.text.trim(),
      borderHex: _borderCtrl.text.trim().isEmpty ? '#E0E0E0' : _borderCtrl.text.trim(),
    );
  }

  Future<void> _publishTheme() async {
    setState(() => _isSaving = true);
    try {
      final draft = _getCurrentDraft();
      await ref.read(cmsRepositoryProvider).saveThemeTokens(draft);
      ref.invalidate(dynamicThemeTokensProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Theme published! Storefront colors updated live.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish theme: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final themeAsync = ref.watch(dynamicThemeTokensProvider);
    themeAsync.whenData((t) => _initFromTokens(t));

    final draft = _getCurrentDraft();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          'STOREFRONT THEME & COLOR STUDIO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Preset Luxury Palettes
                Card(
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: colors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.palette_outlined, color: colors.accentVariant),
                            const SizedBox(width: 12),
                            Text(
                              'CURATED LUXURY COLOR PALETTES',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1.0,
                                color: colors.text,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select a bespoke haute couture color palette or fine-tune individual hex tokens below.',
                          style: TextStyle(color: colors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _PresetButton(
                              title: 'Classic Noir & Gold',
                              description: 'Signature Atelier Palette',
                              tokens: DynamicThemeTokens.classicOchanya,
                              onSelect: () => _applyTokens(DynamicThemeTokens.classicOchanya),
                              currentTokens: draft,
                            ),
                            _PresetButton(
                              title: 'Royal Emerald & Brass',
                              description: 'Heritage Forest & Gold',
                              tokens: DynamicThemeTokens.royalEmerald,
                              onSelect: () => _applyTokens(DynamicThemeTokens.royalEmerald),
                              currentTokens: draft,
                            ),
                            _PresetButton(
                              title: 'Midnight Velvet & Silk',
                              description: 'Deep Nautical Couture',
                              tokens: DynamicThemeTokens.midnightCouture,
                              onSelect: () => _applyTokens(DynamicThemeTokens.midnightCouture),
                              currentTokens: draft,
                            ),
                            _PresetButton(
                              title: 'Luxury Dark Mode',
                              description: 'Obsidian & Gilded Brass',
                              tokens: DynamicThemeTokens.luxuryDarkMode,
                              onSelect: () => _applyTokens(DynamicThemeTokens.luxuryDarkMode),
                              currentTokens: draft,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Side by side: Color Controls & Live Preview
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 850;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left / Top: Color inputs
                        Expanded(
                          flex: isWide ? 6 : 0,
                          child: Card(
                            color: colors.surface,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: colors.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CUSTOM COLOR TOKENS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 1.0,
                                      color: colors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Enter hex color values (e.g. #1A1A1A) to customize any shade.',
                                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                                  ),
                                  const SizedBox(height: 20),
                                  _ColorInputField(
                                    label: 'Primary Accent (Buttons & Headings)',
                                    controller: _accentCtrl,
                                    color: draft.accent,
                                    onChanged: () => setState(() {}),
                                  ),
                                  _ColorInputField(
                                    label: 'Metallic / Secondary Accent (Gold)',
                                    controller: _accentVariantCtrl,
                                    color: draft.accentVariant,
                                    onChanged: () => setState(() {}),
                                  ),
                                  _ColorInputField(
                                    label: 'Background Canvas',
                                    controller: _bgCtrl,
                                    color: draft.background,
                                    onChanged: () => setState(() {}),
                                  ),
                                  _ColorInputField(
                                    label: 'Card & Surface Background',
                                    controller: _surfaceCtrl,
                                    color: draft.surface,
                                    onChanged: () => setState(() {}),
                                  ),
                                  _ColorInputField(
                                    label: 'Surface Variant (Inputs / Chips)',
                                    controller: _surfaceVariantCtrl,
                                    color: draft.surfaceVariant,
                                    onChanged: () => setState(() {}),
                                  ),
                                  _ColorInputField(
                                    label: 'Primary Text',
                                    controller: _primaryTextCtrl,
                                    color: draft.primaryText,
                                    onChanged: () => setState(() {}),
                                  ),
                                  _ColorInputField(
                                    label: 'Secondary / Muted Text',
                                    controller: _secondaryTextCtrl,
                                    color: draft.secondaryText,
                                    onChanged: () => setState(() {}),
                                  ),
                                  _ColorInputField(
                                    label: 'Border & Divider Lines',
                                    controller: _borderCtrl,
                                    color: draft.border,
                                    onChanged: () => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        if (isWide) const SizedBox(width: 24) else const SizedBox(height: 24),

                        // Right / Bottom: Real-Time Preview
                        Expanded(
                          flex: isWide ? 5 : 0,
                          child: Card(
                            color: colors.surface,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: colors.border),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.remove_red_eye_outlined, size: 18, color: colors.accentVariant),
                                      const SizedBox(width: 8),
                                      Text(
                                        'LIVE STOREFRONT PREVIEW',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 1.0,
                                          color: colors.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Real-time simulation of how your luxury store renders.',
                                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                                  ),
                                  const SizedBox(height: 20),

                                  // Simulated Storefront Card
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: draft.background,
                                      border: Border.all(color: draft.border),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Header
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: draft.surface,
                                            border: Border(bottom: BorderSide(color: draft.border)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'OCHANYA GILI',
                                                style: TextStyle(
                                                  fontFamily: 'Playfair Display',
                                                  fontWeight: FontWeight.bold,
                                                  color: draft.primaryText,
                                                  letterSpacing: 1.5,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    'SHOP',
                                                    style: TextStyle(
                                                      color: draft.primaryText,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Icon(Icons.shopping_bag_outlined, size: 16, color: draft.primaryText),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Product Card Simulation
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: draft.surface,
                                            border: Border.all(color: draft.border),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: 100,
                                                color: draft.surfaceVariant,
                                                child: Center(
                                                  child: Icon(Icons.checkroom_outlined, size: 36, color: draft.secondaryText),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'BENUE SILK REGALIA',
                                                    style: TextStyle(
                                                      fontFamily: 'Playfair Display',
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                      color: draft.primaryText,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: draft.accentVariant.withValues(alpha: 0.15),
                                                      border: Border.all(color: draft.accentVariant),
                                                    ),
                                                    child: Text(
                                                      'COUTURE',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: draft.primaryText,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '₦ 450,000 / \$ 320',
                                                style: TextStyle(
                                                  color: draft.accentVariant,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Hand-woven raw silk peplum dress with architectural structure.',
                                                style: TextStyle(color: draft.secondaryText, fontSize: 10, height: 1.4),
                                              ),
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: draft.accent,
                                                    foregroundColor: draft.backgroundHex == '#121212' ? const Color(0xFF121212) : Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    shape: const RoundedRectangleBorder(),
                                                  ),
                                                  onPressed: () {},
                                                  child: const Text('PURCHASE COUTURE', style: TextStyle(fontSize: 10, letterSpacing: 1.0)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.primary,
                                        foregroundColor: colors.onPrimary,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      onPressed: _isSaving ? null : _publishTheme,
                                      icon: _isSaving
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.palette, size: 18),
                                      label: const Text(
                                        'APPLY & PUBLISH TO LIVE STORE',
                                        style: TextStyle(letterSpacing: 1.0, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String title;
  final String description;
  final DynamicThemeTokens tokens;
  final VoidCallback onSelect;
  final DynamicThemeTokens currentTokens;

  const _PresetButton({
    required this.title,
    required this.description,
    required this.tokens,
    required this.onSelect,
    required this.currentTokens,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final isSelected = currentTokens.accentHex.toLowerCase() == tokens.accentHex.toLowerCase() &&
        currentTokens.accentVariantHex.toLowerCase() == tokens.accentVariantHex.toLowerCase();

    return InkWell(
      onTap: onSelect,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          border: Border.all(
            color: isSelected ? colors.accentVariant : colors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ColorSwatch(tokens.accent),
                const SizedBox(width: 4),
                _ColorSwatch(tokens.accentVariant),
                const SizedBox(width: 4),
                _ColorSwatch(tokens.background),
                const SizedBox(width: 4),
                _ColorSwatch(tokens.surface),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  const _ColorSwatch(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black26),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ColorInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color color;
  final VoidCallback onChanged;

  const _ColorInputField({
    required this.label,
    required this.controller,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}
