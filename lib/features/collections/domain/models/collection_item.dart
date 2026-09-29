import 'package:equatable/equatable.dart';

class CollectionItem extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? coverImageUrl;
  final String? heroImageUrl;
  final String? season;
  final int? year;
  final bool isFeatured;
  final bool isPublished;
  final bool isArchived;
  final int sortOrder;
  final int productCount;
  final DateTime? createdAt;

  const CollectionItem({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.coverImageUrl,
    this.heroImageUrl,
    this.season,
    this.year,
    this.isFeatured = false,
    this.isPublished = false,
    this.isArchived = false,
    this.sortOrder = 0,
    this.productCount = 0,
    this.createdAt,
  });

  CollectionItem copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? coverImageUrl,
    String? heroImageUrl,
    String? season,
    int? year,
    bool? isFeatured,
    bool? isPublished,
    bool? isArchived,
    int? sortOrder,
    int? productCount,
    DateTime? createdAt,
  }) {
    return CollectionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      season: season ?? this.season,
      year: year ?? this.year,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublished: isPublished ?? this.isPublished,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      heroImageUrl: json['hero_image_url'] as String?,
      season: json['season'] as String?,
      year: (json['year'] as num?)?.toInt(),
      isFeatured: json['is_featured'] as bool? ?? false,
      isPublished: json['is_published'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'cover_image_url': coverImageUrl,
      'hero_image_url': heroImageUrl,
      'season': season,
      'year': year,
      'is_featured': isFeatured,
      'is_published': isPublished,
      'is_archived': isArchived,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        description,
        coverImageUrl,
        heroImageUrl,
        season,
        year,
        isFeatured,
        isPublished,
        isArchived,
        sortOrder,
        productCount,
        createdAt,
      ];
}
