import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/core/constants/app_breakpoints.dart';
import 'package:ochanya_gili/core/seo/seo_metadata.dart';
import 'package:ochanya_gili/core/seo/seo_service.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';
import 'package:ochanya_gili/features/journal/domain/models/journal_post.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/footer.dart';

class JournalDetailScreen extends ConsumerWidget {
  final String slug;

  const JournalDetailScreen({
    super.key,
    required this.slug,
  });

  void _sharePost(BuildContext context, JournalPost post) {
    final url = 'https://ochanyagili.com/journal/${post.slug}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharable link copied to clipboard: $url'),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final repo = ref.watch(cmsRepositoryProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppBreakpoints.tablet;

    return Scaffold(
      body: FutureBuilder<JournalPost?>(
        future: repo.getJournalPostBySlug(slug),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colors.primaryText, strokeWidth: 1.5));
          }

          final post = snapshot.data;
          if (post == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Essay not found', style: TextStyle(color: colors.primaryText, fontSize: 20)),
                  const SizedBox(height: 16),
                  TextButton(onPressed: () => context.go('/journal'), child: const Text('Back to Journal')),
                ],
              ),
            );
          }

          // Apply dynamic SEO metadata for journal post
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(seoServiceProvider).apply(
                  SeoMetadata.journalPost(
                    title: post.title,
                    slug: post.slug,
                    excerpt: post.excerpt,
                    publishedDate: post.publishedAt?.toIso8601String(),
                    author: 'Ochanya Gili',
                    imageUrl: post.coverImageUrl,
                  ),
                );
          });

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top navigation link & Share Action
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24.0 : 64.0,
                    vertical: 24.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => context.go('/journal'),
                        icon: Icon(Icons.arrow_back_sharp, size: 16, color: colors.primaryText),
                        label: Text(
                          'BACK TO JOURNAL',
                          style: TextStyle(color: colors.primaryText, letterSpacing: 1.5, fontSize: 12),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _sharePost(context, post),
                        icon: const Icon(Icons.share_outlined, size: 14),
                        label: const Text('SHARE', style: TextStyle(letterSpacing: 1.5, fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.border),
                          foregroundColor: colors.primaryText,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                      ),
                    ],
                  ),
                ),

                // Article Header
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24.0 : 40.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (post.tags.isNotEmpty)
                            Text(
                              post.tags.join('  •  ').toUpperCase(),
                              style: TextStyle(
                                color: colors.accentVariant,
                                fontSize: 12,
                                letterSpacing: 3.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            post.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: isMobile ? 32 : 46,
                              color: colors.primaryText,
                              letterSpacing: 1.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (post.publishedAt != null)
                            Text(
                              'PUBLISHED ${post.publishedAt!.day} / ${post.publishedAt!.month} / ${post.publishedAt!.year}',
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 12,
                                letterSpacing: 2.0,
                              ),
                            ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),

                // Featured Cover Image
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 460),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24.0 : 40.0),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRect(
                          child: CachedNetworkImage(
                            imageUrl: post.coverImageUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            placeholder: (context, url) => Container(color: colors.surfaceVariant),
                            errorWidget: (context, url, error) => Container(color: colors.surfaceVariant),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Body Content
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24.0 : 40.0,
                        vertical: 64.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.excerpt,
                            style: TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: isMobile ? 18 : 22,
                              color: colors.primaryText,
                              fontStyle: FontStyle.italic,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 36),
                          Divider(color: colors.border),
                          const SizedBox(height: 36),
                          Text(
                            post.content,
                            style: TextStyle(
                              color: colors.secondaryText,
                              fontSize: isMobile ? 16 : 18,
                              height: 1.9,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 80),
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
      ),
    );
  }
}
