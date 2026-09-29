import 'package:equatable/equatable.dart';

class HeroSlide extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String ctaText;
  final String ctaLink;
  final String desktopImageUrl;
  final String mobileImageUrl;
  final int sortOrder;

  const HeroSlide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.ctaLink,
    required this.desktopImageUrl,
    required this.mobileImageUrl,
    this.sortOrder = 0,
  });

  factory HeroSlide.fromJson(Map<String, dynamic> json) {
    return HeroSlide(
      id: json['id'] as String? ?? 'slide-1',
      title: json['title'] as String? ?? 'OCHANYA GILI',
      subtitle: json['subtitle'] as String? ?? 'Your Vision. Our Craftsmanship.',
      ctaText: json['cta_text'] as String? ?? 'EXPLORE THE COLLECTION',
      ctaLink: json['cta_link'] as String? ?? '/collections',
      desktopImageUrl: json['desktop_image_url'] as String? ?? '',
      mobileImageUrl: json['mobile_image_url'] as String? ?? json['desktop_image_url'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'cta_text': ctaText,
      'cta_link': ctaLink,
      'desktop_image_url': desktopImageUrl,
      'mobile_image_url': mobileImageUrl,
      'sort_order': sortOrder,
    };
  }

  @override
  List<Object?> get props => [id, title, subtitle, ctaText, ctaLink, desktopImageUrl, mobileImageUrl, sortOrder];
}

class EditorialBlock extends Equatable {
  final String headline;
  final String subheadline;
  final String body;
  final String imageUrl;
  final String ctaText;
  final String ctaLink;

  const EditorialBlock({
    required this.headline,
    required this.subheadline,
    required this.body,
    required this.imageUrl,
    required this.ctaText,
    required this.ctaLink,
  });

  factory EditorialBlock.fromJson(Map<String, dynamic> json) {
    return EditorialBlock(
      headline: json['headline'] as String? ?? 'THE RESORT COLLECTION',
      subheadline: json['subheadline'] as String? ?? 'AUTUMN / WINTER 2026',
      body: json['body'] as String? ??
          'Handcrafted couture silhouettes merging West African artisanal heritage with modern atelier precision.',
      imageUrl: json['image_url'] as String? ?? '',
      ctaText: json['cta_text'] as String? ?? 'DISCOVER THE CAMPAIGN',
      ctaLink: json['cta_link'] as String? ?? '/collections',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headline': headline,
      'subheadline': subheadline,
      'body': body,
      'image_url': imageUrl,
      'cta_text': ctaText,
      'cta_link': ctaLink,
    };
  }

  @override
  List<Object?> get props => [headline, subheadline, body, imageUrl, ctaText, ctaLink];
}

class AboutContent extends Equatable {
  final String title;
  final String philosophy;
  final String craftsmanship;
  final String designerBio;
  final String studioAddress;
  final String heroImageUrl;

  const AboutContent({
    required this.title,
    required this.philosophy,
    required this.craftsmanship,
    required this.designerBio,
    required this.studioAddress,
    required this.heroImageUrl,
  });

  factory AboutContent.fromJson(Map<String, dynamic> json) {
    return AboutContent(
      title: json['title'] as String? ?? 'THE ATELIER',
      philosophy: json['philosophy'] as String? ??
          'Ochanya Gili was founded on an uncompromising pursuit of sartorial excellence. Every piece is an architectural dialogue between rich tactile textiles and bespoke human proportions.',
      craftsmanship: json['craftsmanship'] as String? ??
          'From initial sketch and personalized toile fitting to final hand-finished embroidery, our master artisans dedicate scores of hours to every garment.',
      designerBio: json['designer_bio'] as String? ??
          'Conceived in Abuja and celebrated globally, the house embodies timeless luxury with contemporary African sovereignty.',
      studioAddress: json['studio_address'] as String? ?? 'Maitama, Abuja, Nigeria',
      heroImageUrl: json['hero_image_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'philosophy': philosophy,
      'craftsmanship': craftsmanship,
      'designer_bio': designerBio,
      'studio_address': studioAddress,
      'hero_image_url': heroImageUrl,
    };
  }

  @override
  List<Object?> get props => [title, philosophy, craftsmanship, designerBio, studioAddress, heroImageUrl];
}

class ContactDetails extends Equatable {
  final String conciergeEmail;
  final String studioPhone;
  final String address;
  final String openingHours;
  final String instagram;

  const ContactDetails({
    required this.conciergeEmail,
    required this.studioPhone,
    required this.address,
    required this.openingHours,
    required this.instagram,
  });

  factory ContactDetails.fromJson(Map<String, dynamic> json) {
    return ContactDetails(
      conciergeEmail: json['concierge_email'] as String? ?? 'concierge@ochanyagili.com',
      studioPhone: json['studio_phone'] as String? ?? '+234 (0) 90 000 0000',
      address: json['address'] as String? ?? 'Plot 104, Maitama Luxury District, Abuja, Nigeria',
      openingHours: json['opening_hours'] as String? ?? 'Monday – Saturday: 10:00 – 18:00 (By Appointment)',
      instagram: json['instagram'] as String? ?? '@ochanyagiliofficial',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'concierge_email': conciergeEmail,
      'studio_phone': studioPhone,
      'address': address,
      'opening_hours': openingHours,
      'instagram': instagram,
    };
  }

  @override
  List<Object?> get props => [conciergeEmail, studioPhone, address, openingHours, instagram];
}
