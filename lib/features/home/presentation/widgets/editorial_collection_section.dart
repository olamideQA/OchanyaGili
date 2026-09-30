import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ochanya_gili/core/config/demo_config.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/core/constants/app_breakpoints.dart';
import 'package:ochanya_gili/features/cms/domain/models/cms_content.dart';

class EditorialCollectionSection extends StatelessWidget {
  final EditorialBlock block;

  const EditorialCollectionSection({
    super.key,
    required this.block,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= AppBreakpoints.desktop;
    final isMobile = screenWidth < AppBreakpoints.tablet;

    // DEMO-SEED START: pitch campaign gallery. Set DemoConfig.enabled=false
    // to hide for clean template (section auto-hides when empty).
    final galleryItems = DemoConfig.enabled
        ? [
      {
        'title': 'Look 01 — Ivory Peplum Gown',
        'subtitle': 'Raw Silk & Hand-finished Organza',
        'image': 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?q=80&w=600&h=800&auto=format&fit=crop',
      },
      {
        'title': 'Look 04 — Sovereign Kaftan',
        'subtitle': 'Gold Thread Filigree & Wool Crepe',
        'image': 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=600&h=800&auto=format&fit=crop',
      },
      {
        'title': 'Look 08 — Tailored Tuxedo Gown',
        'subtitle': 'Structured Velvet & Satin Lapel',
        'image': 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=600&h=800&auto=format&fit=crop',
      },
      {
        'title': 'Look 12 — Architectural Corset Dress',
        'subtitle': 'Sculpted Peplum & Artisanal Crepe',
        'image': 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?q=80&w=600&h=800&auto=format&fit=crop',
      },
    ]
        : const <Map<String, String>>[];

    return Container(
      color: colors.background,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 48.0 : 72.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Editorial Block
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24.0 : 64.0),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Refined Campaign Image Left
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 460),
                            child: AspectRatio(
                              aspectRatio: 4 / 5,
                              child: CachedNetworkImage(
                                imageUrl: block.imageUrl,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                placeholder: (context, url) => Container(color: colors.surfaceVariant),
                                errorWidget: (context, url, error) => Container(
                                  color: colors.surfaceVariant,
                                  child: Icon(Icons.image, color: colors.secondaryText, size: 48),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                      // Editorial Headline + Copy Right
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              block.subheadline.toUpperCase(),
                              style: TextStyle(
                                color: colors.accentVariant,
                                letterSpacing: 3.0,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              block.headline,
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                color: colors.primaryText,
                                fontSize: 44,
                                height: 1.15,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              block.body,
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 16,
                                height: 1.7,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 40),
                            ElevatedButton(
                              onPressed: () => context.go(block.ctaLink),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.accent,
                                foregroundColor: colors.onAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              ),
                              child: Text(
                                block.ctaText.toUpperCase(),
                                style: const TextStyle(letterSpacing: 2.0, fontSize: 13),
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
                      Text(
                        block.subheadline.toUpperCase(),
                        style: TextStyle(
                          color: colors.accentVariant,
                          letterSpacing: 2.5,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        block.headline,
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          color: colors.primaryText,
                          fontSize: 32,
                          height: 1.2,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 360),
                        child: AspectRatio(
                          aspectRatio: 4 / 5,
                          child: CachedNetworkImage(
                            imageUrl: block.imageUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            placeholder: (context, url) => Container(color: colors.surfaceVariant),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        block.body,
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => context.go(block.ctaLink),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: colors.onAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        child: Text(
                          block.ctaText.toUpperCase(),
                          style: const TextStyle(letterSpacing: 2.0, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 48),

          // DEMO-SEED gallery block — auto-hidden when DemoConfig.enabled=false.
          if (galleryItems.isNotEmpty) ...[
          // Horizontally Scrollable Gallery
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24.0 : 64.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CAMPAIGN SELECTS',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 20,
                    letterSpacing: 2.0,
                    color: colors.primaryText,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/collections'),
                  child: Row(
                    children: [
                      Text(
                        'VIEW ALL LOOKS',
                        style: TextStyle(color: colors.accentVariant, letterSpacing: 1.5, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_sharp, size: 14, color: colors.accentVariant),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 290,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 20.0 : 60.0),
              itemCount: galleryItems.length,
              itemBuilder: (context, index) {
                final item = galleryItems[index];
                return Container(
                  width: 220,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: InkWell(
                    onTap: () => context.go('/lookbook'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRect(
                            child: CachedNetworkImage(
                              imageUrl: item['image']!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: colors.surfaceVariant),
                              errorWidget: (context, url, error) => Container(color: colors.surfaceVariant),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item['title']!,
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: colors.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['subtitle']!,
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ],
        ],
      ),
    );
  }
}
