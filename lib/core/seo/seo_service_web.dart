import 'dart:convert';
import 'package:web/web.dart' as web;
import 'package:ochanya_gili/core/seo/seo_metadata.dart';

void applySeoMetadataWeb(SeoMetadata metadata) {
  try {
    // 1. Update Document Title
    web.document.title = metadata.fullTitle;

    // Helper: update or create <meta> tag by name or property
    void setMeta(String attribute, String key, String content) {
      final selector = 'meta[$attribute="$key"]';
      var element = web.document.querySelector(selector) as web.HTMLMetaElement?;
      if (element == null) {
        element = web.document.createElement('meta') as web.HTMLMetaElement;
        element.setAttribute(attribute, key);
        web.document.head?.appendChild(element);
      }
      element.setAttribute('content', content);
    }

    // 2. Primary Meta Tags
    setMeta('name', 'title', metadata.fullTitle);
    setMeta('name', 'description', metadata.description);
    if (metadata.keywords.isNotEmpty) {
      setMeta('name', 'keywords', metadata.keywords.join(', '));
    }

    // 3. Canonical Link
    var canonical = web.document.querySelector('link[rel="canonical"]') as web.HTMLLinkElement?;
    if (canonical == null) {
      canonical = web.document.createElement('link') as web.HTMLLinkElement;
      canonical.setAttribute('rel', 'canonical');
      web.document.head?.appendChild(canonical);
    }
    canonical.setAttribute('href', metadata.canonicalUrl);

    // 4. OpenGraph Metadata
    setMeta('property', 'og:title', metadata.fullTitle);
    setMeta('property', 'og:description', metadata.description);
    setMeta('property', 'og:url', metadata.canonicalUrl);
    setMeta('property', 'og:image', metadata.imageUrl);
    setMeta('property', 'og:type', metadata.ogType);
    setMeta('property', 'og:site_name', SeoMetadata.siteName);

    // 5. Twitter / X Card
    setMeta('name', 'twitter:card', metadata.twitterCard);
    setMeta('name', 'twitter:title', metadata.fullTitle);
    setMeta('name', 'twitter:description', metadata.description);
    setMeta('name', 'twitter:image', metadata.imageUrl);
    setMeta('name', 'twitter:url', metadata.canonicalUrl);

    // 6. Schema.org JSON-LD Structured Data
    if (metadata.structuredData != null) {
      var script = web.document.getElementById('schema-jsonld') as web.HTMLScriptElement?;
      if (script == null) {
        script = web.document.createElement('script') as web.HTMLScriptElement;
        script.id = 'schema-jsonld';
        script.setAttribute('type', 'application/ld+json');
        web.document.head?.appendChild(script);
      }
      script.text = jsonEncode(metadata.structuredData);
    }
  } catch (_) {
    // Graceful fallback if DOM is not ready or restricted
  }
}
