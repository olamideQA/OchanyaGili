class FooterLink {
  final String title;
  final String url;
  final bool isExternal;

  const FooterLink({
    required this.title,
    required this.url,
    this.isExternal = false,
  });

  factory FooterLink.fromJson(Map<String, dynamic> json) {
    return FooterLink(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '/',
      isExternal: json['is_external'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'is_external': isExternal,
  };
}

class FooterColumn {
  final String title;
  final List<FooterLink> links;

  const FooterColumn({
    required this.title,
    required this.links,
  });

  factory FooterColumn.fromJson(Map<String, dynamic> json) {
    final rawLinks = json['links'] as List<dynamic>? ?? [];
    return FooterColumn(
      title: json['title'] as String? ?? '',
      links: rawLinks.map((e) => FooterLink.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'links': links.map((e) => e.toJson()).toList(),
  };
}

class SocialLinks {
  final String instagram;
  final String whatsapp;
  final String twitter;
  final String facebook;

  const SocialLinks({
    this.instagram = '',
    this.whatsapp = '',
    this.twitter = '',
    this.facebook = '',
  });

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      instagram: json['instagram'] as String? ?? '',
      whatsapp: json['whatsapp'] as String? ?? '',
      twitter: json['twitter'] as String? ?? '',
      facebook: json['facebook'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'instagram': instagram,
    'whatsapp': whatsapp,
    'twitter': twitter,
    'facebook': facebook,
  };
}

class FooterConfig {
  final String tagline;
  final String address;
  final String copyright;
  final SocialLinks socialLinks;
  final List<FooterColumn> columns;

  const FooterConfig({
    required this.tagline,
    required this.address,
    required this.copyright,
    required this.socialLinks,
    required this.columns,
  });

  factory FooterConfig.fromJson(Map<String, dynamic> json) {
    final rawCols = json['columns'] as List<dynamic>? ?? [];
    return FooterConfig(
      tagline: json['tagline'] as String? ?? 'Sartorial Sovereignty. Contemporary African Couture.',
      address: json['address'] as String? ?? 'Victoria Island, Lagos, Nigeria',
      copyright: json['copyright'] as String? ?? '© 2026 Ochanya Gili Atelier. All rights reserved.',
      socialLinks: json['social_links'] != null && json['social_links'] is Map
          ? SocialLinks.fromJson(json['social_links'] as Map<String, dynamic>)
          : const SocialLinks(),
      columns: rawCols.map((e) => FooterColumn.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'tagline': tagline,
    'address': address,
    'copyright': copyright,
    'social_links': socialLinks.toJson(),
    'columns': columns.map((e) => e.toJson()).toList(),
  };
}
