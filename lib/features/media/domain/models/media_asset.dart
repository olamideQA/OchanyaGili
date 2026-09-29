import 'package:equatable/equatable.dart';

class MediaAsset extends Equatable {
  final String id;
  final String bucket;
  final String filePath;
  final String filename;
  final String url;
  final String altText;
  final String title;
  final String mimeType;
  final int sizeBytes;
  final int? width;
  final int? height;
  final int sortOrder;
  final Map<String, dynamic> responsiveUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MediaAsset({
    required this.id,
    required this.bucket,
    required this.filePath,
    required this.filename,
    required this.url,
    this.altText = '',
    this.title = '',
    this.mimeType = 'image/jpeg',
    this.sizeBytes = 0,
    this.width,
    this.height,
    this.sortOrder = 0,
    this.responsiveUrls = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: json['id'] as String,
      bucket: json['bucket'] as String? ?? 'products',
      filePath: json['file_path'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      url: json['url'] as String? ?? '',
      altText: json['alt_text'] as String? ?? '',
      title: json['title'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? 'image/jpeg',
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      responsiveUrls: json['responsive_urls'] is Map<String, dynamic>
          ? json['responsive_urls'] as Map<String, dynamic>
          : {},
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bucket': bucket,
      'file_path': filePath,
      'filename': filename,
      'url': url,
      'alt_text': altText,
      'title': title,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      'sort_order': sortOrder,
      'responsive_urls': responsiveUrls,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  MediaAsset copyWith({
    String? id,
    String? bucket,
    String? filePath,
    String? filename,
    String? url,
    String? altText,
    String? title,
    String? mimeType,
    int? sizeBytes,
    int? width,
    int? height,
    int? sortOrder,
    Map<String, dynamic>? responsiveUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MediaAsset(
      id: id ?? this.id,
      bucket: bucket ?? this.bucket,
      filePath: filePath ?? this.filePath,
      filename: filename ?? this.filename,
      url: url ?? this.url,
      altText: altText ?? this.altText,
      title: title ?? this.title,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      sortOrder: sortOrder ?? this.sortOrder,
      responsiveUrls: responsiveUrls ?? this.responsiveUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  List<Object?> get props => [
        id,
        bucket,
        filePath,
        filename,
        url,
        altText,
        title,
        mimeType,
        sizeBytes,
        width,
        height,
        sortOrder,
        responsiveUrls,
        createdAt,
        updatedAt,
      ];
}
