class CustomPage {
  final String id;
  final String title;
  final String slug;
  final String content;
  final String? metaDescription;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomPage({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    this.metaDescription,
    this.isPublished = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomPage.fromJson(Map<String, dynamic> json) {
    return CustomPage(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      content: json['content'] as String? ?? '',
      metaDescription: json['meta_description'] as String?,
      isPublished: json['is_published'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'title': title,
      'slug': slug,
      'content': content,
      'meta_description': metaDescription,
      'is_published': isPublished,
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  CustomPage copyWith({
    String? id,
    String? title,
    String? slug,
    String? content,
    String? metaDescription,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomPage(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      content: content ?? this.content,
      metaDescription: metaDescription ?? this.metaDescription,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
