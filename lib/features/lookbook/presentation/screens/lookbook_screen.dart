import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/lookbook/data/lookbook_repository.dart';
import 'package:ochanya_gili/features/lookbook/domain/models/lookbook_entry.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/footer.dart';

import 'package:ochanya_gili/features/analytics/data/analytics_service.dart';

class LookbookScreen extends ConsumerStatefulWidget {
  final String? initialSlug;

  const LookbookScreen({
    super.key,
    this.initialSlug,
  });

  @override
  ConsumerState<LookbookScreen> createState() => _LookbookScreenState();
}

class _LookbookScreenState extends ConsumerState<LookbookScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(analyticsServiceProvider).trackLookbookView(
              widget.initialSlug ?? 'editorial-anthology',
            );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final looksAsync = ref.watch(publishedLookbooksProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 768;

    return looksAsync.when(
        data: (looks) {
          if (looks.isEmpty) {
            return Center(
              child: Text('No lookbook entries available', style: TextStyle(color: colors.primaryText)),
            );
          }

          final currentLook = looks[_currentIndex];

          return Stack(
            children: [
              // Main Editorial Carousel
              PageView.builder(
                controller: _pageController,
                itemCount: looks.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  ref
                      .read(analyticsServiceProvider)
                      .trackLookbookView(looks[index].slug);
                },
                itemBuilder: (context, index) {
                  final look = looks[index];
                  return _LookbookSlide(
                    look: look,
                    colors: colors,
                    isDesktop: isDesktop,
                    isMobile: isMobile,
                  );
                },
              ),

              // Left / Right Navigation Controls
              if (looks.length > 1) ...[
                Positioned(
                  left: isMobile ? 12 : 32,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_sharp, color: colors.primaryText, size: isMobile ? 20 : 28),
                      onPressed: _currentIndex > 0
                          ? () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic,
                              )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  right: isMobile ? 12 : 32,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: Icon(Icons.arrow_forward_ios_sharp, color: colors.primaryText, size: isMobile ? 20 : 28),
                      onPressed: _currentIndex < looks.length - 1
                          ? () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic,
                              )
                          : null,
                    ),
                  ),
                ),
              ],

              // Top Counter & Collection Label
              Positioned(
                top: 24,
                left: isMobile ? 24 : 64,
                child: Row(
                  children: [
                    Text(
                      'LOOK ${_currentIndex + 1} OF ${looks.length}',
                      style: TextStyle(
                        color: colors.accentVariant,
                        fontSize: 12,
                        letterSpacing: 3.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (currentLook.collectionName != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        '|   ${currentLook.collectionName!.toUpperCase()}',
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 12,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colors.primaryText, strokeWidth: 1.5)),
        error: (err, stack) => Center(child: Text('Failed to load lookbook', style: TextStyle(color: colors.error))),
    );
  }
}

class _LookbookSlide extends StatelessWidget {
  final LookbookEntry look;
  final AppColorTokens colors;
  final bool isDesktop;
  final bool isMobile;

  const _LookbookSlide({
    required this.look,
    required this.colors,
    required this.isDesktop,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    // "Shop this look" URL with linked products pre-filtered
    final shopThisLookUrl = look.linkedProductIds.isNotEmpty
        ? '/shop?look=${look.slug}&products=${look.linkedProductIds.join(",")}'
        : '/shop?look=${look.slug}';

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 96.0, vertical: 64.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Full-Scale Editorial Image Left
            Expanded(
              flex: 6,
              child: Center(
                child: ClipRect(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 520),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: CachedNetworkImage(
                        imageUrl: look.fullImageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        placeholder: (context, url) => Container(color: colors.surfaceVariant),
                        errorWidget: (context, url, error) => Container(color: colors.surfaceVariant),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 80),
            // Editorial Details & Credits Right
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    look.title.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 36,
                      color: colors.primaryText,
                      letterSpacing: 2.0,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (look.description != null)
                    Text(
                      look.description!,
                      style: TextStyle(color: colors.secondaryText, fontSize: 16, height: 1.6),
                    ),
                  if (look.designerNotes != null) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.only(left: 20),
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: colors.accentVariant, width: 2)),
                      ),
                      child: Text(
                        look.designerNotes!,
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontStyle: FontStyle.italic,
                          fontSize: 16,
                          color: colors.primaryText,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 36),
                  // Credits
                  _buildCredits(colors),
                  const SizedBox(height: 48),
                  // "Shop This Look" Deep Link
                  ElevatedButton.icon(
                    onPressed: () => context.go(shopThisLookUrl),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                    label: const Text('SHOP THIS LOOK', style: TextStyle(letterSpacing: 2.0, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 22),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Tablet layout
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 48.0,
        vertical: 64.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: CachedNetworkImage(
                imageUrl: look.fullImageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                placeholder: (context, url) => Container(color: colors.surfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            look.title.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 26,
              color: colors.primaryText,
              letterSpacing: 1.5,
            ),
          ),
          if (look.description != null) ...[
            const SizedBox(height: 12),
            Text(
              look.description!,
              style: TextStyle(color: colors.secondaryText, fontSize: 14, height: 1.6),
            ),
          ],
          if (look.designerNotes != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: colors.accentVariant, width: 2)),
              ),
              child: Text(
                look.designerNotes!,
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
                  color: colors.primaryText,
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          _buildCredits(colors),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go(shopThisLookUrl),
              icon: const Icon(Icons.shopping_bag_outlined, size: 16),
              label: const Text('SHOP THIS LOOK', style: TextStyle(letterSpacing: 2.0)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
            ),
          ),
          const SizedBox(height: 64),
          const Footer(),
        ],
      ),
    );
  }

  Widget _buildCredits(AppColorTokens colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (look.modelName != null)
          _CreditLine(label: 'MODEL', value: look.modelName!, colors: colors),
        if (look.photographer != null)
          _CreditLine(label: 'PHOTOGRAPHY', value: look.photographer!, colors: colors),
      ],
    );
  }
}

class _CreditLine extends StatelessWidget {
  final String label;
  final String value;
  final AppColorTokens colors;

  const _CreditLine({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: colors.secondaryText, fontSize: 11, letterSpacing: 2.0, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(color: colors.primaryText, fontSize: 13, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
