import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';

enum ImageContext {
  thumbnail,
  card,
  hero,
  detail,
  avatar,
}

class ResponsiveImageService {
  /// Converts an image URL into a responsive, CDN-optimized URL based on target context and viewport width.
  static String getOptimizedUrl(
    String rawUrl, {
    ImageContext context = ImageContext.card,
    double? customWidth,
    int quality = 80,
    String format = 'webp',
  }) {
    if (rawUrl.isEmpty) return '';

    // Target width determination
    int targetWidth;
    if (customWidth != null) {
      targetWidth = customWidth.round();
    } else {
      switch (context) {
        case ImageContext.thumbnail:
        case ImageContext.avatar:
          targetWidth = 240;
          break;
        case ImageContext.card:
          targetWidth = 640;
          break;
        case ImageContext.detail:
          targetWidth = 1080;
          break;
        case ImageContext.hero:
          targetWidth = 1920;
          break;
      }
    }

    // 1. Supabase Storage Transformation Handling
    if (rawUrl.contains('.supabase.co/storage/v1/object/public/')) {
      final transformUrl = rawUrl.replaceFirst(
        '/storage/v1/object/public/',
        '/storage/v1/render/image/public/',
      );
      final separator = transformUrl.contains('?') ? '&' : '?';
      return '$transformUrl${separator}width=$targetWidth&quality=$quality&format=$format&resize=cover';
    }

    // 2. Unsplash Image Parameters Handling
    if (rawUrl.contains('images.unsplash.com')) {
      final uri = Uri.parse(rawUrl);
      final query = Map<String, String>.from(uri.queryParameters);
      query['w'] = targetWidth.toString();
      query['q'] = quality.toString();
      query['auto'] = 'format';
      query['fit'] = 'crop';
      return uri.replace(queryParameters: query).toString();
    }

    return rawUrl;
  }
}

/// Accessible, lazy-loaded, CDN-optimized image widget.
class AdaptiveImage extends StatelessWidget {
  final String imageUrl;
  final String altText;
  final BoxFit fit;
  final double? width;
  final double? height;
  final ImageContext imageContext;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AdaptiveImage({
    super.key,
    required this.imageUrl,
    required this.altText,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.imageContext = ImageContext.card,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final optimizedUrl = ResponsiveImageService.getOptimizedUrl(
      imageUrl,
      context: imageContext,
      customWidth: width,
    );

    return Semantics(
      label: altText,
      image: true,
      child: CachedNetworkImage(
        imageUrl: optimizedUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: width != null ? (width! * 2).toInt() : 800,
        placeholder: (context, url) =>
            placeholder ??
            Container(
              width: width,
              height: height,
              color: colors.surfaceVariant,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: colors.secondaryText,
                  ),
                ),
              ),
            ),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: colors.surfaceVariant,
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: colors.secondaryText,
                  size: 28,
                ),
              ),
            ),
      ),
    );
  }
}
