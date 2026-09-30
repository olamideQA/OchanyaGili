import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/core/seo/seo_metadata.dart';
import 'package:ochanya_gili/core/seo/seo_service.dart';
import 'package:ochanya_gili/features/analytics/data/analytics_service.dart';
import 'package:ochanya_gili/features/collections/data/collections_repository.dart';
import 'package:ochanya_gili/features/collections/domain/models/collection_item.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/footer.dart';

class CollectionDetailScreen extends ConsumerWidget {
  final String slug;

  const CollectionDetailScreen({
    super.key,
    required this.slug,
  });

  void _shareCollection(BuildContext context, CollectionItem collection) {
    final url = 'https://ochanyagili.com/collections/${collection.slug}';
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
    final repo = ref.watch(collectionsRepositoryProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 768;

    return Scaffold(
      body: FutureBuilder<CollectionItem?>(
        future: repo.getCollectionBySlug(slug),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colors.primaryText, strokeWidth: 1.5));
          }

          final collection = snapshot.data;
          if (collection == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Collection not found', style: TextStyle(color: colors.primaryText, fontSize: 20)),
                  const SizedBox(height: 16),
                  TextButton(onPressed: () => context.go('/collections'), child: const Text('Back to Collections')),
                ],
              ),
            );
          }

          // Apply dynamic SEO metadata for collection
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(seoServiceProvider).apply(
                  SeoMetadata.collection(
                    title: collection.name,
                    slug: collection.slug,
                    description: collection.description ?? 'Ochanya Gili Couture Collection',
                    season: collection.season,
                    imageUrl: collection.heroImageUrl ?? collection.coverImageUrl,
                  ),
                );
            ref.read(analyticsServiceProvider).trackCollectionView(
                  collectionId: collection.id,
                  name: collection.name,
                  slug: collection.slug,
                );
          });

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
                Stack(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: isMobile ? 280 : 380),
                      child: AspectRatio(
                        aspectRatio: isDesktop ? 21 / 9 : 16 / 10,
                        child: CachedNetworkImage(
                          imageUrl: collection.heroImageUrl ?? collection.coverImageUrl ?? '',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          placeholder: (context, url) => Container(color: colors.surfaceVariant),
                          errorWidget: (context, url, error) => Container(color: colors.surfaceVariant),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.2),
                              Colors.black.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: isMobile ? 24 : 48,
                      left: isMobile ? 24 : 64,
                      right: isMobile ? 24 : 64,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (collection.season != null || collection.year != null)
                            Text(
                              '${collection.season ?? ''} ${collection.year ?? ''}'.trim().toUpperCase(),
                              style: TextStyle(
                                color: colors.accentVariant,
                                fontSize: 13,
                                letterSpacing: 3.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            collection.name.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Playfair Display',
                              color: Colors.white,
                              fontSize: isMobile ? 28 : 48,
                              letterSpacing: 2.0,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Statement & Actions Bar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24.0 : 64.0,
                    vertical: 48.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Text(
                            collection.description ?? '',
                            style: TextStyle(color: colors.secondaryText, fontSize: 16, height: 1.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _shareCollection(context, collection),
                            icon: const Icon(Icons.share_outlined, size: 16),
                            label: const Text('SHARE', style: TextStyle(letterSpacing: 1.5, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.border),
                              foregroundColor: colors.primaryText,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/lookbook'),
                            icon: const Icon(Icons.menu_book_outlined, size: 16),
                            label: const Text('VIEW LOOKBOOK', style: TextStyle(letterSpacing: 1.5, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.primaryText, width: 1.2),
                              foregroundColor: colors.primaryText,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Divider(color: colors.border),

                // Pieces in this Collection Section
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24.0 : 64.0,
                    vertical: 48.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COLLECTION PIECES',
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 24,
                          letterSpacing: 2.0,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Curated couture and made-to-order garments from this release.',
                        style: TextStyle(color: colors.secondaryText, fontSize: 14),
                      ),
                      const SizedBox(height: 36),

                      // Placeholder pieces grid (will link to Shop in Loop 3)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(48.0),
                          color: colors.surface,
                          child: Column(
                            children: [
                              Icon(Icons.checkroom_outlined, size: 48, color: colors.secondaryText),
                              const SizedBox(height: 16),
                              Text(
                                'Full Catalogue Available in Shop',
                                style: TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 20,
                                  color: colors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Browse all pieces from this release with bespoke sizing and ready-to-wear delivery options.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: colors.secondaryText, fontSize: 14),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => context.go('/shop?collection=${collection.slug}'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.accent,
                                  foregroundColor: colors.onAccent,
                                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                                ),
                                child: const Text('VIEW ALL PIECES IN SHOP', style: TextStyle(letterSpacing: 1.5)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
