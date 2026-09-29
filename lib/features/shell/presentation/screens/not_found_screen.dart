import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/core/constants/app_breakpoints.dart';
import 'package:ochanya_gili/core/seo/seo_metadata.dart';
import 'package:ochanya_gili/core/seo/seo_service.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/footer.dart';

class NotFoundScreen extends ConsumerStatefulWidget {
  final String? uri;

  const NotFoundScreen({super.key, this.uri});

  @override
  ConsumerState<NotFoundScreen> createState() => _NotFoundScreenState();
}

class _NotFoundScreenState extends ConsumerState<NotFoundScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(seoServiceProvider).apply(SeoMetadata.notFound());
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppBreakpoints.tablet;

    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24.0 : 64.0,
                vertical: isMobile ? 80.0 : 120.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '404 — ATELIER ARCHIVE',
                        style: TextStyle(
                          color: colors.accentVariant,
                          fontSize: 13,
                          letterSpacing: 4.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'This Silhouette Does Not Exist',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          color: colors.primaryText,
                          fontSize: isMobile ? 32 : 46,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'The piece or page you are seeking has retired to our private archive or resides under an alternate designation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      if (widget.uri != null && widget.uri!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Requested Path: ${widget.uri}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 48),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          ElevatedButton(
                            onPressed: () => context.go('/'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primaryText,
                              foregroundColor: colors.onAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            child: const Text('RETURN TO ATELIER', style: TextStyle(letterSpacing: 2, fontSize: 12)),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go('/shop'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.primaryText),
                              foregroundColor: colors.primaryText,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            child: const Text('EXPLORE SHOP', style: TextStyle(letterSpacing: 2, fontSize: 12)),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go('/collections'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.primaryText),
                              foregroundColor: colors.primaryText,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            child: const Text('VIEW COLLECTIONS', style: TextStyle(letterSpacing: 2, fontSize: 12)),
                          ),
                        ],
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
    );
  }
}
