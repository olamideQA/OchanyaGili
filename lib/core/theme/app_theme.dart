import 'package:flutter/material.dart';
import 'package:ochanya_gili/core/theme/app_typography.dart';

class AppColorTokens extends ThemeExtension<AppColorTokens> {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color accentVariant;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;
  final Color onAccent;

  const AppColorTokens({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.accentVariant,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.onAccent,
  });

  // Convenience aliases for flexible usage across widgets
  Color get text => primaryText;
  Color get textMuted => secondaryText;
  Color get primary => accent;
  Color get onPrimary => onAccent;

  @override
  AppColorTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? primaryText,
    Color? secondaryText,
    Color? accent,
    Color? accentVariant,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
    Color? onAccent,
  }) {
    return AppColorTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      accent: accent ?? this.accent,
      accentVariant: accentVariant ?? this.accentVariant,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) {
      return this;
    }
    return AppColorTokens(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentVariant: Color.lerp(accentVariant, other.accentVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

class AppTheme {
  static const lightTokens = AppColorTokens(
    background: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF5F5F5),
    primaryText: Color(0xFF1A1A1A),
    secondaryText: Color(0xFF757575),
    accent: Color(0xFF1A1A1A),
    accentVariant: Color(0xFFC9A96E),
    border: Color(0xFFE0E0E0),
    success: Color(0xFF2E7D32),
    warning: Color(0xFFF57F17),
    error: Color(0xFFC62828),
    onAccent: Color(0xFFFFFFFF),
  );

  static ThemeData get lightTheme => buildTheme();

  static ThemeData buildTheme([AppColorTokens? customTokens]) {
    final tokens = customTokens ?? lightTokens;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: tokens.background,
      colorScheme: ColorScheme.light(
        primary: tokens.accent,
        onPrimary: tokens.onAccent,
        secondary: tokens.accentVariant,
        onSecondary: tokens.primaryText,
        error: tokens.error,
        onError: tokens.surface,
        surface: tokens.surface,
        onSurface: tokens.primaryText,
      ),
      textTheme: AppTypography.buildTextTheme(tokens),
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        foregroundColor: tokens.primaryText,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}

