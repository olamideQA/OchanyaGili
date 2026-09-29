import 'package:equatable/equatable.dart';

class JournalPost extends Equatable {
  final String id;
  final String title;
  final String slug;
  final String excerpt;
  final String content;
  final String coverImageUrl;
  final bool isPublished;
  final DateTime? publishedAt;
  final List<String> tags;

  const JournalPost({
    required this.id,
    required this.title,
    required this.slug,
    required this.excerpt,
    required this.content,
    required this.coverImageUrl,
    this.isPublished = false,
    this.publishedAt,
    this.tags = const [],
  });

  factory JournalPost.fromJson(Map<String, dynamic> json) {
    return JournalPost(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      content: json['content'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String? ?? '',
      isPublished: json['is_published'] as bool? ?? false,
      publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'].toString()) : null,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'excerpt': excerpt,
      'content': content,
      'cover_image_url': coverImageUrl,
      'is_published': isPublished,
      'published_at': publishedAt?.toIso8601String(),
      'tags': tags,
    };
  }

  @override
  List<Object?> get props => [id, title, slug, excerpt, content, coverImageUrl, isPublished, publishedAt, tags];
}
