class BrandHeader {
  final String brandName;
  final String logoUrl;
  final String tagline;
  final String announcementText;
  final bool showAnnouncement;

  const BrandHeader({
    this.brandName = 'OCHANYA GILI',
    this.logoUrl = '',
    this.tagline = 'HAUTE COUTURE & READY-TO-WEAR',
    this.announcementText = 'COMPLIMENTARY DELIVERY IN ABUJA — WORLDWIDE SHIPPING AVAILABLE',
    this.showAnnouncement = true,
  });

  factory BrandHeader.fromJson(Map<String, dynamic> json) {
    return BrandHeader(
      brandName: json['brand_name'] as String? ?? 'OCHANYA GILI',
      logoUrl: json['logo_url'] as String? ?? '',
      tagline: json['tagline'] as String? ?? 'HAUTE COUTURE & READY-TO-WEAR',
      announcementText: json['announcement_text'] as String? ?? 'COMPLIMENTARY DELIVERY IN ABUJA — WORLDWIDE SHIPPING AVAILABLE',
      showAnnouncement: json['show_announcement'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand_name': brandName,
      'logo_url': logoUrl,
      'tagline': tagline,
      'announcement_text': announcementText,
      'show_announcement': showAnnouncement,
    };
  }

  BrandHeader copyWith({
    String? brandName,
    String? logoUrl,
    String? tagline,
    String? announcementText,
    bool? showAnnouncement,
  }) {
    return BrandHeader(
      brandName: brandName ?? this.brandName,
      logoUrl: logoUrl ?? this.logoUrl,
      tagline: tagline ?? this.tagline,
      announcementText: announcementText ?? this.announcementText,
      showAnnouncement: showAnnouncement ?? this.showAnnouncement,
    );
  }
}

