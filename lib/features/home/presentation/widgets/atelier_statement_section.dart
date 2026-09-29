import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/core/constants/app_breakpoints.dart';

class AtelierStatementSection extends StatelessWidget {
  const AtelierStatementSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppBreakpoints.tablet;

    return Container(
      color: colors.surface,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 64.0,
        vertical: isMobile ? 64.0 : 80.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'THE ATELIER MANIFESTO',
                style: TextStyle(
                  color: colors.accentVariant,
                  fontSize: 12,
                  letterSpacing: 4.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '“We do not merely dress the silhouette; we elevate the presence. Every seam is an intentional architecture of dignity, culture, and sovereign elegance.”',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  color: colors.primaryText,
                  fontSize: isMobile ? 22 : 32,
                  fontStyle: FontStyle.italic,
                  height: 1.45,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'OCHANYA GILI — MAITAMA, ABUJA',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 11,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () => context.go('/about'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.primaryText, width: 1.2),
                  foregroundColor: colors.primaryText,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: const Text(
                  'READ OUR STORY',
                  style: TextStyle(letterSpacing: 2.0, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
