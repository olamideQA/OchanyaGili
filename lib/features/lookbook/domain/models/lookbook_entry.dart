import 'package:equatable/equatable.dart';

class LookbookEntry extends Equatable {
  final String id;
  final String title;
  final String slug;
  final String? description;
  final String coverImageUrl;
  final String fullImageUrl;
  final String? designerNotes;
  final String? collectionId;
  final String? collectionName;
  final String? modelName;
  final String? photographer;
  final bool isPublished;
  final int sortOrder;
  final List<String> linkedProductIds;
  final DateTime? createdAt;

  const LookbookEntry({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    required this.coverImageUrl,
    required this.fullImageUrl,
    this.designerNotes,
    this.collectionId,
    this.collectionName,
    this.modelName,
    this.photographer,
    this.isPublished = false,
    this.sortOrder = 0,
    this.linkedProductIds = const [],
    this.createdAt,
  });

  LookbookEntry copyWith({
    String? id,
    String? title,
    String? slug,
    String? description,
    String? coverImageUrl,
    String? fullImageUrl,
    String? designerNotes,
    String? collectionId,
    String? collectionName,
    String? modelName,
    String? photographer,
    bool? isPublished,
    int? sortOrder,
    List<String>? linkedProductIds,
    DateTime? createdAt,
  }) {
    return LookbookEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      fullImageUrl: fullImageUrl ?? this.fullImageUrl,
      designerNotes: designerNotes ?? this.designerNotes,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      modelName: modelName ?? this.modelName,
      photographer: photographer ?? this.photographer,
      isPublished: isPublished ?? this.isPublished,
      sortOrder: sortOrder ?? this.sortOrder,
      linkedProductIds: linkedProductIds ?? this.linkedProductIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory LookbookEntry.fromJson(Map<String, dynamic> json) {
    return LookbookEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String? ?? '',
      fullImageUrl: json['full_image_url'] as String? ?? json['cover_image_url'] as String? ?? '',
      designerNotes: json['designer_notes'] as String?,
      collectionId: json['collection_id'] as String?,
      collectionName: json['collection_name'] as String?,
      modelName: json['model_name'] as String?,
      photographer: json['photographer'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      linkedProductIds: (json['linked_product_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'cover_image_url': coverImageUrl,
      'full_image_url': fullImageUrl,
      'designer_notes': designerNotes,
      'collection_id': collectionId,
      'model_name': modelName,
      'photographer': photographer,
      'is_published': isPublished,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        slug,
        description,
        coverImageUrl,
        fullImageUrl,
        designerNotes,
        collectionId,
        collectionName,
        modelName,
        photographer,
        isPublished,
        sortOrder,
        linkedProductIds,
        createdAt,
      ];
}
