import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/core/constants/app_breakpoints.dart';
import 'package:ochanya_gili/features/cms/domain/models/cms_content.dart';

class EditorialHero extends StatefulWidget {
  final List<HeroSlide> slides;

  const EditorialHero({
    super.key,
    required this.slides,
  });

  @override
  State<EditorialHero> createState() => _EditorialHeroState();
}

class _EditorialHeroState extends State<EditorialHero> {
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTimer();
  }

  void _startTimer() {
    if (widget.slides.length <= 1) return;
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted) return;
      final nextIndex = (_currentIndex + 1) % widget.slides.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth >= AppBreakpoints.desktop;
    final isMobile = screenWidth < AppBreakpoints.tablet;

    if (widget.slides.isEmpty) {
      return SizedBox(
        height: (screenHeight * 0.68).clamp(420.0, 600.0),
        child: Center(
          child: Text('OCHANYA GILI', style: TextStyle(color: colors.primaryText, fontSize: 32, letterSpacing: 4)),
        ),
      );
    }

    return SizedBox(
      // Industry-standard banner (~68% viewport, max 600) with pre-cropped
      // 16:9 art so cover barely crops instead of microscope-zooming.
      height: (screenHeight * 0.68).clamp(420.0, 600.0),
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Slides
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: widget.slides.length,
            itemBuilder: (context, index) {
              final slide = widget.slides[index];
              final imageUrl = isDesktop ? slide.desktopImageUrl : slide.mobileImageUrl;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Background Artwork
                  if (imageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: colors.surfaceVariant),
                      errorWidget: (context, url, error) => Container(
                        color: colors.surfaceVariant,
                        child: Center(
                          child: Icon(Icons.broken_image_outlined, color: colors.secondaryText, size: 48),
                        ),
                      ),
                    )
                  else
                    Container(color: colors.surfaceVariant),

                  // Dark subtle editorial scrim for luxury legibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),

                  // Editorial Typography & CTA
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24.0 : 64.0,
                        vertical: 48.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide.title.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Playfair Display',
                              color: Colors.white,
                              fontSize: isMobile ? 34 : (isDesktop ? 58 : 46),
                              fontWeight: FontWeight.w400,
                              letterSpacing: isMobile ? 3.0 : 6.0,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Text(
                              slide.subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: isMobile ? 15 : 19,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w300,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          OutlinedButton(
                            onPressed: () {
                              context.go(slide.ctaLink);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white, width: 1.2),
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 28 : 44,
                                vertical: isMobile ? 16 : 22,
                              ),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            child: Text(
                              slide.ctaText.toUpperCase(),
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13,
                                letterSpacing: 2.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Slide indicator bars
          if (widget.slides.length > 1)
            Positioned(
              bottom: 28,
              right: isMobile ? 24 : 64,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.slides.length, (i) {
                  final isSelected = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 2,
                    width: isSelected ? 48 : 20,
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.35),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
