import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/core/constants/app_breakpoints.dart';
import 'package:ochanya_gili/features/journal/domain/models/journal_post.dart';

class HomeJournalPreview extends StatelessWidget {
  final List<JournalPost> posts;

  const HomeJournalPreview({
    super.key,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= AppBreakpoints.desktop;
    final isMobile = screenWidth < AppBreakpoints.tablet;

    if (posts.isEmpty) return const SizedBox.shrink();

    final displayedPosts = posts.take(2).toList();

    return Container(
      color: colors.surfaceVariant,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 64.0,
        vertical: isMobile ? 48.0 : 72.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EDITORIAL DISPATCHES',
                    style: TextStyle(
                      color: colors.accentVariant,
                      fontSize: 12,
                      letterSpacing: 3.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'THE JOURNAL',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      color: colors.primaryText,
                      fontSize: isMobile ? 26 : 36,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.go('/journal'),
                child: Row(
                  children: [
                    Text(
                      'READ ALL POSTS',
                      style: TextStyle(color: colors.primaryText, letterSpacing: 1.5, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_sharp, size: 14, color: colors.primaryText),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: displayedPosts.map((post) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _JournalCard(post: post, colors: colors),
                  ),
                );
              }).toList(),
            )
          else
            Column(
              children: displayedPosts.map((post) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: _JournalCard(post: post, colors: colors),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final JournalPost post;
  final AppColorTokens colors;

  const _JournalCard({
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
          AspectRatio(
            aspectRatio: 16 / 10,
            child: CachedNetworkImage(
              imageUrl: post.coverImageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: colors.surface),
              errorWidget: (context, url, error) => Container(color: colors.surface),
            ),
          ),
          const SizedBox(height: 18),
          if (post.tags.isNotEmpty)
            Text(
              post.tags.first.toUpperCase(),
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
              color: colors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          Text(
            'CONTINUE READING →',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
