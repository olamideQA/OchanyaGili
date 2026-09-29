import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/core/constants/app_breakpoints.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/footer.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final aboutAsync = ref.watch(aboutContentProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= AppBreakpoints.desktop;
    final isMobile = screenWidth < AppBreakpoints.tablet;

    return aboutAsync.when(
      data: (about) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24.0 : 64.0,
                  vertical: isMobile ? 64.0 : 96.0,
                ),
                color: colors.surface,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        Text(
                          'THE HOUSE',
                          style: TextStyle(
                            color: colors.accentVariant,
                            letterSpacing: 4.0,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          about.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: isMobile ? 32 : 46,
                            letterSpacing: 2.0,
                            color: colors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          about.philosophy,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: isMobile ? 15 : 18,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Image & Craftsmanship Section
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24.0 : 64.0,
                  vertical: 64.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: AspectRatio(
                                  aspectRatio: 16 / 11,
                                  child: CachedNetworkImage(
                                    imageUrl: about.heroImageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: colors.surfaceVariant),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 64),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ARTISANAL MASTERY',
                                      style: TextStyle(
                                        color: colors.accentVariant,
                                        letterSpacing: 3.0,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'The Anatomy of Craft',
                                      style: TextStyle(
                                        fontFamily: 'Playfair Display',
                                        fontSize: 32,
                                        color: colors.primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      about.craftsmanship,
                                      style: TextStyle(
                                        color: colors.secondaryText,
                                        fontSize: 16,
                                        height: 1.8,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    Text(
                                      about.designerBio,
                                      style: TextStyle(
                                        color: colors.secondaryText,
                                        fontSize: 16,
                                        height: 1.8,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 11,
                                child: CachedNetworkImage(
                                  imageUrl: about.heroImageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: colors.surfaceVariant),
                                ),
                              ),
                              const SizedBox(height: 36),
                              Text(
                                'The Anatomy of Craft',
                                style: TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 28,
                                  color: colors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                about.craftsmanship,
                                style: TextStyle(
                                  color: colors.secondaryText,
                                  fontSize: 15,
                                  height: 1.7,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                about.designerBio,
                                style: TextStyle(
                                  color: colors.secondaryText,
                                  fontSize: 15,
                                  height: 1.7,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const Footer(),
            ],
          ),
        ),
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.primaryText, strokeWidth: 1.5),
        ),
        error: (err, stack) => Center(
          child: Text('Failed to load about details', style: TextStyle(color: colors.error)),
        ),
    );
  }
}
