import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/collections/data/collections_repository.dart';
import 'package:ochanya_gili/features/collections/domain/models/collection_item.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/footer.dart';

class CollectionsListScreen extends ConsumerWidget {
  const CollectionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final collectionsAsync = ref.watch(publishedCollectionsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 768;

    return collectionsAsync.when(
      data: (collections) => SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24.0 : 64.0,
                vertical: isMobile ? 48.0 : 80.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SEASONAL RELEASES',
                    style: TextStyle(
                      color: colors.accentVariant,
                      fontSize: 12,
                      letterSpacing: 3.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The Collections',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: isMobile ? 36 : 48,
                      color: colors.primaryText,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Explore curated narratives in couture tailoring, traditional embroidery, and contemporary silhouettes.',
                    style: TextStyle(color: colors.secondaryText, fontSize: 16),
                  ),
                  const SizedBox(height: 56),

                  // Collections list (asymmetric editorial fashion cards)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: collections.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 72),
                    itemBuilder: (context, index) {
                      final collection = collections[index];
                      final isEven = index.isEven;
                      return _CollectionCard(
                        collection: collection,
                        colors: colors,
                        isDesktop: isDesktop,
                        isEven: isEven,
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
  error: (err, stack) => Center(child: Text('Failed to load collections', style: TextStyle(color: colors.error))),
);
  }
}

class _CollectionCard extends StatelessWidget {
  final CollectionItem collection;
  final AppColorTokens colors;
  final bool isDesktop;
  final bool isEven;

  const _CollectionCard({
    required this.collection,
    required this.colors,
    required this.isDesktop,
    required this.isEven,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: isDesktop ? 380 : 300),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: ClipRect(
          child: CachedNetworkImage(
            imageUrl: collection.coverImageUrl ?? '',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            placeholder: (context, url) => Container(color: colors.surfaceVariant),
            errorWidget: (context, url, error) => Container(color: colors.surfaceVariant),
          ),
        ),
      ),
    );

    final infoWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (collection.season != null || collection.year != null)
          Text(
            '${collection.season ?? ''} ${collection.year ?? ''}'.trim().toUpperCase(),
            style: TextStyle(
              color: colors.accentVariant,
              fontSize: 12,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 14),
        Text(
          collection.name,
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: isDesktop ? 32 : 24,
            color: colors.primaryText,
            height: 1.2,
          ),
        ),
        if (collection.description != null) ...[
          const SizedBox(height: 16),
          Text(
            collection.description!,
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ],
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () => context.go('/collections/${collection.slug}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: colors.onAccent,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: const Text('EXPLORE COLLECTION', style: TextStyle(letterSpacing: 2.0, fontSize: 12)),
        ),
      ],
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: isEven
            ? [
                Expanded(flex: 6, child: imageWidget),
                const SizedBox(width: 48),
                Expanded(flex: 5, child: infoWidget),
              ]
            : [
                Expanded(flex: 5, child: infoWidget),
                const SizedBox(width: 48),
                Expanded(flex: 6, child: imageWidget),
              ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        imageWidget,
        const SizedBox(height: 24),
        infoWidget,
      ],
    );
  }
}
