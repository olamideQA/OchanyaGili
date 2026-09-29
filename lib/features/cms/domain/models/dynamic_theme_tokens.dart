import 'package:flutter/material.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';

class DynamicThemeTokens {
  final String accentHex;
  final String accentVariantHex;
  final String backgroundHex;
  final String surfaceHex;
  final String surfaceVariantHex;
  final String primaryTextHex;
  final String secondaryTextHex;
  final String borderHex;

  const DynamicThemeTokens({
    this.accentHex = '#1A1A1A',
    this.accentVariantHex = '#C9A96E',
    this.backgroundHex = '#FAFAFA',
    this.surfaceHex = '#FFFFFF',
    this.surfaceVariantHex = '#F5F5F5',
    this.primaryTextHex = '#1A1A1A',
    this.secondaryTextHex = '#757575',
    this.borderHex = '#E0E0E0',
  });

  static Color parseHex(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  Color get accent => parseHex(accentHex, const Color(0xFF1A1A1A));
  Color get accentVariant => parseHex(accentVariantHex, const Color(0xFFC9A96E));
  Color get background => parseHex(backgroundHex, const Color(0xFFFAFAFA));
  Color get surface => parseHex(surfaceHex, const Color(0xFFFFFFFF));
  Color get surfaceVariant => parseHex(surfaceVariantHex, const Color(0xFFF5F5F5));
  Color get primaryText => parseHex(primaryTextHex, const Color(0xFF1A1A1A));
  Color get secondaryText => parseHex(secondaryTextHex, const Color(0xFF757575));
  Color get border => parseHex(borderHex, const Color(0xFFE0E0E0));

  AppColorTokens toAppColorTokens() {
    final isDark = backgroundHex.toLowerCase() == '#121212' ||
        backgroundHex.toLowerCase() == '#1a1a1a' ||
        backgroundHex.toLowerCase() == '#000000';
    return AppColorTokens(
      background: background,
      surface: surface,
      surfaceVariant: surfaceVariant,
      primaryText: primaryText,
      secondaryText: secondaryText,
      accent: accent,
      accentVariant: accentVariant,
      border: border,
      success: const Color(0xFF2E7D32),
      warning: const Color(0xFFF57F17),
      error: const Color(0xFFC62828),
      onAccent: isDark ? const Color(0xFF121212) : Colors.white,
    );
  }

  factory DynamicThemeTokens.fromJson(Map<String, dynamic> json) {
    return DynamicThemeTokens(
      accentHex: json['accent'] as String? ?? '#1A1A1A',
      accentVariantHex: json['accent_variant'] as String? ?? '#C9A96E',
      backgroundHex: json['background'] as String? ?? '#FAFAFA',
      surfaceHex: json['surface'] as String? ?? '#FFFFFF',
      surfaceVariantHex: json['surface_variant'] as String? ?? '#F5F5F5',
      primaryTextHex: json['primary_text'] as String? ?? '#1A1A1A',
      secondaryTextHex: json['secondary_text'] as String? ?? '#757575',
      borderHex: json['border'] as String? ?? '#E0E0E0',
    );
  }

  Map<String, dynamic> toJson() => {
    'accent': accentHex,
    'accent_variant': accentVariantHex,
    'background': backgroundHex,
    'surface': surfaceHex,
    'surface_variant': surfaceVariantHex,
    'primary_text': primaryTextHex,
    'secondary_text': secondaryTextHex,
    'border': borderHex,
  };

  DynamicThemeTokens copyWith({
    String? accentHex,
    String? accentVariantHex,
    String? backgroundHex,
    String? surfaceHex,
    String? surfaceVariantHex,
    String? primaryTextHex,
    String? secondaryTextHex,
    String? borderHex,
  }) {
    return DynamicThemeTokens(
      accentHex: accentHex ?? this.accentHex,
      accentVariantHex: accentVariantHex ?? this.accentVariantHex,
      backgroundHex: backgroundHex ?? this.backgroundHex,
      surfaceHex: surfaceHex ?? this.surfaceHex,
      surfaceVariantHex: surfaceVariantHex ?? this.surfaceVariantHex,
      primaryTextHex: primaryTextHex ?? this.primaryTextHex,
      secondaryTextHex: secondaryTextHex ?? this.secondaryTextHex,
      borderHex: borderHex ?? this.borderHex,
    );
  }

  // Curated Luxury Color Palettes
  static const DynamicThemeTokens classicOchanya = DynamicThemeTokens(
    accentHex: '#1A1A1A',
    accentVariantHex: '#C9A96E',
    backgroundHex: '#FAFAFA',
    surfaceHex: '#FFFFFF',
    surfaceVariantHex: '#F5F5F5',
    primaryTextHex: '#1A1A1A',
    secondaryTextHex: '#757575',
    borderHex: '#E0E0E0',
  );

  static const DynamicThemeTokens royalEmerald = DynamicThemeTokens(
    accentHex: '#0E3B2F',
    accentVariantHex: '#C29B38',
    backgroundHex: '#F7FAF8',
    surfaceHex: '#FFFFFF',
    surfaceVariantHex: '#EEF4F0',
    primaryTextHex: '#08211A',
    secondaryTextHex: '#52665C',
    borderHex: '#D3DFD8',
  );

  static const DynamicThemeTokens midnightCouture = DynamicThemeTokens(
    accentHex: '#0F172A',
    accentVariantHex: '#E2C974',
    backgroundHex: '#F8FAFC',
    surfaceHex: '#FFFFFF',
    surfaceVariantHex: '#F1F5F9',
    primaryTextHex: '#0B1120',
    secondaryTextHex: '#64748B',
    borderHex: '#E2E8F0',
  );

  static const DynamicThemeTokens luxuryDarkMode = DynamicThemeTokens(
    accentHex: '#D4AF37',
    accentVariantHex: '#E5C158',
    backgroundHex: '#121212',
    surfaceHex: '#1E1E1E',
    surfaceVariantHex: '#2A2A2A',
    primaryTextHex: '#F5F5F5',
    secondaryTextHex: '#A3A3A3',
    borderHex: '#333333',
  );
}
