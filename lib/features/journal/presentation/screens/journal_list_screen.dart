import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/core/constants/app_breakpoints.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';
import 'package:ochanya_gili/features/journal/domain/models/journal_post.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/footer.dart';

class JournalListScreen extends ConsumerWidget {
  const JournalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final postsAsync = ref.watch(journalPostsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= AppBreakpoints.desktop;
    final isMobile = screenWidth < AppBreakpoints.tablet;

    return postsAsync.when(
      data: (posts) => SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24.0 : 64.0,
                vertical: isMobile ? 48.0 : 80.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EDITORIAL ARCHIVE',
                    style: TextStyle(
                      color: colors.accentVariant,
                      fontSize: 12,
                      letterSpacing: 3.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The Journal',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: isMobile ? 36 : 48,
                      color: colors.primaryText,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Stories of artisanal craftsmanship, runway documentation, and contemporary couture philosophy.',
                    style: TextStyle(color: colors.secondaryText, fontSize: 16),
                  ),
                  const SizedBox(height: 56),

                  // Posts Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = isDesktop ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 48,
                          mainAxisSpacing: 56,
                          childAspectRatio: isDesktop ? 1.05 : 0.85,
                        ),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return _JournalGridCard(post: post, colors: colors);
                        },
                      );
                    },
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
  loading: () => Center(child: CircularProgressIndicator(color: colors.primaryText, strokeWidth: 1.5)),
  error: (err, stack) => Center(child: Text('Failed to load journal posts', style: TextStyle(color: colors.error))),
);
  }
}

class _JournalGridCard extends StatelessWidget {
  final JournalPost post;
  final AppColorTokens colors;

  const _JournalGridCard({
    required this.post,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/journal/${post.slug}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRect(
              child: CachedNetworkImage(
                imageUrl: post.coverImageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: colors.surfaceVariant),
                errorWidget: (context, url, error) => Container(color: colors.surfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (post.tags.isNotEmpty)
            Text(
              post.tags.join('  •  ').toUpperCase(),
              style: TextStyle(
                color: colors.accentVariant,
                fontSize: 11,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            post.title,
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.primaryText,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            post.excerpt,
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 14,
              height: 1.6,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Text(
            'READ ESSAY →',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
