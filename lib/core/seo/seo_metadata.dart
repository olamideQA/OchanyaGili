import 'dart:convert';
import 'package:equatable/equatable.dart';

/// SEO & Social Sharing metadata model for the Ochanya Gili Atelier platform.
class SeoMetadata extends Equatable {
  static const String baseUrl = 'https://ochanyagili.com';
  static const String siteName = 'Ochanya Gili';
  static const String defaultImage =
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?q=80&w=1200&auto=format&fit=crop';

  final String title;
  final String description;
  final String path;
  final String imageUrl;
  final String ogType;
  final String twitterCard;
  final List<String> keywords;
  final Map<String, dynamic>? structuredData;

  const SeoMetadata({
    required this.title,
    required this.description,
    required this.path,
    this.imageUrl = defaultImage,
    this.ogType = 'website',
    this.twitterCard = 'summary_large_image',
    this.keywords = const [
      'Ochanya Gili',
      'African Luxury',
      'Haute Couture',
      'Abuja Fashion',
      'Bespoke Tailoring',
    ],
    this.structuredData,
  });

  String get canonicalUrl {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }

  String get fullTitle => title.contains(siteName) ? title : '$title | $siteName';

  String? get jsonLdString =>
      structuredData != null ? const JsonEncoder.withIndent('  ').convert(structuredData) : null;

  @override
  List<Object?> get props => [
        title,
        description,
        path,
        imageUrl,
        ogType,
        twitterCard,
        keywords,
        structuredData,
      ];

  // =========================================================================
  // Factory Presets for All Public Pages
  // =========================================================================

  factory SeoMetadata.home() {
    return SeoMetadata(
      title: 'Sovereign African Luxury & Couture Atelier',
      description:
          'Discover Ochanya Gili — a premier Nigerian haute couture maison based in Maitama, Abuja. Handcrafted bespoke garments, architectural ready-to-wear, and ceremonial ensembles.',
      path: '/',
      keywords: const [
        'Ochanya Gili',
        'Nigerian Haute Couture',
        'Abuja Luxury Fashion',
        'Bespoke African Fashion',
        'Ceremonial Gowns',
      ],
      structuredData: {
        '@context': 'https://schema.org',
        '@type': 'ClothingStore',
        'name': siteName,
        'description': 'Sovereign African Luxury & Bespoke Couture Atelier in Maitama, Abuja',
        'url': baseUrl,
        'image': defaultImage,
        'priceRange': '₦₦₦₦',
        'address': {
          '@type': 'PostalAddress',
          'streetAddress': 'Maitama District',
          'addressLocality': 'Abuja',
          'addressRegion': 'FCT',
          'addressCountry': 'NG',
        },
      },
    );
  }

  factory SeoMetadata.shop() {
    return const SeoMetadata(
      title: 'Ready-to-Wear & Couture Archive',
      description:
          'Explore our curated catalogue of ready-to-wear pieces, made-to-order architectural silhouettes, and bespoke couture creations.',
      path: '/shop',
      ogType: 'website',
      keywords: ['Ready to Wear', 'African Couture', 'Luxury Blazers', 'Evening Gowns', 'Atelier Shop'],
    );
  }

  factory SeoMetadata.product({
    required String name,
    required String slug,
    required String description,
    required double price,
    String? imageUrl,
    String? category,
    bool inStock = true,
  }) {
    final img = imageUrl ?? defaultImage;
    return SeoMetadata(
      title: name,
      description: description,
      path: '/shop/$slug',
      imageUrl: img,
      ogType: 'product',
      keywords: [name, category ?? 'Luxury Fashion', 'Ochanya Gili Shop', 'Haute Couture'],
      structuredData: {
        '@context': 'https://schema.org',
        '@type': 'Product',
        'name': name,
        'description': description,
        'image': [img],
        'brand': {
          '@type': 'Brand',
          'name': siteName,
        },
        'offers': {
          '@type': 'Offer',
          'url': '$baseUrl/shop/$slug',
          'priceCurrency': 'NGN',
          'price': price,
          'availability':
              inStock ? 'https://schema.org/InStock' : 'https://schema.org/OutOfStock',
          'itemCondition': 'https://schema.org/NewCondition',
        },
      },
    );
  }

  factory SeoMetadata.collections() {
    return const SeoMetadata(
      title: 'Couture Collections & Seasonal Anthologies',
      description:
          'Explore the artistic anthologies of Ochanya Gili. Each collection explores sovereign heritage, hand-woven textiles, and sculptural tailoring.',
      path: '/collections',
      keywords: ['Couture Collections', 'African Anthologies', 'Benue Regalia', 'Sahara Solstice'],
    );
  }

  factory SeoMetadata.collection({
    required String title,
    required String slug,
    required String description,
    String? season,
    String? imageUrl,
  }) {
    final img = imageUrl ?? defaultImage;
    return SeoMetadata(
      title: '$title — $season',
      description: description,
      path: '/collections/$slug',
      imageUrl: img,
      keywords: [title, season ?? 'Couture Collection', 'Ochanya Gili', 'Fashion Anthology'],
      structuredData: {
        '@context': 'https://schema.org',
        '@type': 'CollectionPage',
        'name': title,
        'description': description,
        'url': '$baseUrl/collections/$slug',
        'image': img,
      },
    );
  }

  factory SeoMetadata.lookbook({String? initialSlug}) {
    final path = initialSlug != null ? '/lookbook/$initialSlug' : '/lookbook';
    return SeoMetadata(
      title: 'Editorial Lookbook & Campaign Archive',
      description:
          'Immerse yourself in visual poetry. High-definition editorial captures and behind-the-seams campaign imagery from Ochanya Gili.',
      path: path,
      keywords: ['Lookbook', 'High Fashion Editorial', 'African Fashion Photography', 'Campaign Archive'],
    );
  }

  factory SeoMetadata.journal() {
    return const SeoMetadata(
      title: 'The Journal — Heritage, Architecture & Silk',
      description:
          'Dispatches from the Abuja salon. Essays on indigenous textile preservation, architectural tailoring philosophy, and contemporary African art.',
      path: '/journal',
      keywords: ['Fashion Journal', 'African Textiles', 'Couture Essays', 'Ochanya Gili Journal'],
    );
  }

  factory SeoMetadata.journalPost({
    required String title,
    required String slug,
    required String excerpt,
    String? publishedDate,
    String? author,
    String? imageUrl,
  }) {
    final img = imageUrl ?? defaultImage;
    return SeoMetadata(
      title: title,
      description: excerpt,
      path: '/journal/$slug',
      imageUrl: img,
      ogType: 'article',
      keywords: [title, 'Journal', 'Fashion Philosophy', 'Artisanal Heritage'],
      structuredData: {
        '@context': 'https://schema.org',
        '@type': 'BlogPosting',
        'headline': title,
        'description': excerpt,
        'image': [img],
        'datePublished': publishedDate ?? DateTime.now().toIso8601String(),
        'author': {
          '@type': 'Person',
          'name': author ?? siteName,
        },
        'publisher': {
          '@type': 'Organization',
          'name': siteName,
          'logo': {
            '@type': 'ImageObject',
            'url': '$baseUrl/icons/Icon-512.png',
          },
        },
        'mainEntityOfPage': {
          '@type': 'WebPage',
          '@id': '$baseUrl/journal/$slug',
        },
      },
    );
  }

  factory SeoMetadata.about() {
    return const SeoMetadata(
      title: 'The Atelier Philosophy & Craftsmanship',
      description:
          'Learn about the heritage, craftsmanship, and master artisans behind Ochanya Gili in Maitama, Abuja. Sovereign elegance engineered through intentional architecture.',
      path: '/about',
      keywords: ['About Ochanya Gili', 'Atelier Philosophy', 'Maitama Abuja Fashion', 'African Artisans'],
    );
  }

  factory SeoMetadata.contact() {
    return const SeoMetadata(
      title: 'Private Concierge & Private Appointments',
      description:
          'Connect with the Ochanya Gili salon in Maitama, Abuja. Arrange private couture appointments, style consultations, and bespoke inquiries.',
      path: '/contact',
      keywords: ['Atelier Concierge', 'Book Appointment', 'Abuja Private Salon', 'Contact Ochanya Gili'],
    );
  }

  factory SeoMetadata.customAtelier() {
    return const SeoMetadata(
      title: 'Bespoke Atelier Commission — Create Your Look',
      description:
          'Commission a one-of-a-kind bespoke masterpiece with Ochanya Gili. Interactive silhouette designer, luxury fabric selection, and personalized atelier fitting.',
      path: '/create-your-look',
      keywords: ['Bespoke Couture', 'Custom Atelier', 'Personalized Fashion', 'Bridal Commission'],
    );
  }

  factory SeoMetadata.notFound() {
    return const SeoMetadata(
      title: 'Page Not Found',
      description:
          'The requested atelier resource cannot be found. Return to our curated archive or explore our latest collections.',
      path: '/404',
    );
  }
}
