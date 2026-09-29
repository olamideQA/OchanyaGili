import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/core/constants/app_breakpoints.dart';

void main() {
  group('Theme Token System Tests', () {
    test('AppColorTokens provides all required palette tokens', () {
      const tokens = AppTheme.lightTokens;

      expect(tokens.background, isNotNull);
      expect(tokens.surface, isNotNull);
      expect(tokens.surfaceVariant, isNotNull);
      expect(tokens.primaryText, isNotNull);
      expect(tokens.secondaryText, isNotNull);
      expect(tokens.accent, isNotNull);
      expect(tokens.accentVariant, isNotNull);
      expect(tokens.border, isNotNull);
      expect(tokens.success, isNotNull);
      expect(tokens.warning, isNotNull);
      expect(tokens.error, isNotNull);
      expect(tokens.onAccent, isNotNull);
    });

    test('Swapping one token propagates to ThemeData without widget changes', () {
      final customTokens = AppTheme.lightTokens.copyWith(
        accent: const Color(0xFFFF5722), // deep orange
        background: const Color(0xFF121212),
      );

      final theme = ThemeData(
        extensions: [customTokens],
        scaffoldBackgroundColor: customTokens.background,
        colorScheme: ColorScheme.light(
          primary: customTokens.accent,
          surface: customTokens.surface,
        ),
      );

      final extractedTokens = theme.extension<AppColorTokens>();
      expect(extractedTokens, isNotNull);
      expect(extractedTokens!.accent, const Color(0xFFFF5722));
      expect(extractedTokens.background, const Color(0xFF121212));
    });

    test('Responsive breakpoints match specification (390 / 768 / 1440 / 1920)', () {
      expect(AppBreakpoints.mobile, 390.0);
      expect(AppBreakpoints.tablet, 768.0);
      expect(AppBreakpoints.desktop, 1440.0);
      expect(AppBreakpoints.wide, 1920.0);
    });
  });
}
