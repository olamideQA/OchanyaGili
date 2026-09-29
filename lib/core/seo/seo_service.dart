import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/core/seo/seo_metadata.dart';
import 'package:ochanya_gili/core/seo/seo_service_stub.dart'
    if (dart.library.js) 'package:ochanya_gili/core/seo/seo_service_web.dart' as impl;

class SeoService {
  SeoMetadata? _currentMetadata;

  SeoMetadata? get currentMetadata => _currentMetadata;

  void apply(SeoMetadata metadata) {
    _currentMetadata = metadata;
    if (kIsWeb) {
      impl.applySeoMetadataWeb(metadata);
    }
  }

  void applyRoute(String path) {
    final clean = path.split('?').first;
    if (clean == '/') {
      apply(SeoMetadata.home());
    } else if (clean == '/shop') {
      apply(SeoMetadata.shop());
    } else if (clean == '/collections') {
      apply(SeoMetadata.collections());
    } else if (clean == '/lookbook') {
      apply(SeoMetadata.lookbook());
    } else if (clean == '/journal') {
      apply(SeoMetadata.journal());
    } else if (clean == '/about') {
      apply(SeoMetadata.about());
    } else if (clean == '/contact') {
      apply(SeoMetadata.contact());
    } else if (clean == '/create-your-look') {
      apply(SeoMetadata.customAtelier());
    }
  }
}

final seoServiceProvider = Provider<SeoService>((ref) {
  return SeoService();
});
