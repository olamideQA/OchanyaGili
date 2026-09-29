import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';
import 'package:ochanya_gili/features/cms/domain/models/custom_page.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/footer.dart';

final dynamicPageProvider = FutureProvider.family<CustomPage?, String>((ref, slug) {
  return ref.watch(cmsRepositoryProvider).getCustomPageBySlug(slug);
});

class DynamicPageScreen extends ConsumerWidget {
  final String slug;

  const DynamicPageScreen({
    super.key,
    required this.slug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final pageAsync = ref.watch(dynamicPageProvider(slug));
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return pageAsync.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(64.0),
          child: CircularProgressIndicator(color: colors.accentVariant),
        ),
      ),
      error: (err, _) => _buildNotFound(context, colors),
      data: (page) {
        if (page == null) {
          return _buildNotFound(context, colors);
        }

        final paragraphs = page.content
            .split(RegExp(r'\n\s*\n'))
            .where((p) => p.trim().isNotEmpty)
            .toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Editorial Hero Banner
              Container(
                color: colors.surfaceVariant,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24.0 : 64.0,
                  vertical: isMobile ? 48.0 : 72.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 2,
                          color: colors.accentVariant,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          page.title.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: isMobile ? 28 : 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: colors.text,
                          ),
                        ),
                        if (page.metaDescription != null && page.metaDescription!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            page.metaDescription!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.textMuted,
                              letterSpacing: 0.5,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Page Content
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24.0 : 48.0,
                  vertical: 48.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final p in paragraphs) ...[
                          Text(
                            p.trim(),
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.8,
                              color: colors.text,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        const SizedBox(height: 32),
                        Divider(color: colors.border),
                        const SizedBox(height: 32),

                        // Atelier Concierge Callout
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'THE BESPOKE ATELIER CONCIERGE',
                                style: TextStyle(
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: colors.accentVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Experience Sovereign African Modernism',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: colors.text,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Commission made-to-measure couture, reserve private salon appointments, or inquire regarding custom commissions.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.textMuted,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 16,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.primary,
                                      foregroundColor: colors.onPrimary,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    ),
                                    onPressed: () => context.go('/account/appointments/book'),
                                    child: const Text('BOOK PRIVATE FITTING'),
                                  ),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colors.text,
                                      side: BorderSide(color: colors.border),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    ),
                                    onPressed: () => context.go('/collections'),
                                    child: const Text('EXPLORE ARCHIVE'),
                                  ),
                                ],
                              ),
                            ],
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
        );
      },
    );
  }

  Widget _buildNotFound(BuildContext context, AppColorTokens colors) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    Icon(Icons.auto_stories_outlined, size: 48, color: colors.accentVariant),
                    const SizedBox(height: 20),
                    Text(
                      'PAGE NOT FOUND',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'The bespoke atelier story you are looking for has been archived or relocated.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: colors.textMuted, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      ),
                      onPressed: () => context.go('/collections'),
                      child: const Text('EXPLORE COLLECTIONS'),
                    ),
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
}
