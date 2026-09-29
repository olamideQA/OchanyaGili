import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:ochanya_gili/core/security/file_upload_validator.dart';
import 'package:ochanya_gili/features/media/domain/models/media_asset.dart';

class MediaService {
  final SupabaseClient _client;

  MediaService(this._client);

  /// Fetch all media assets optionally filtered by bucket or search query
  Future<List<MediaAsset>> getAssets({String? bucket, String? searchQuery}) async {
    try {
      var query = _client.from('media_assets').select();
      if (bucket != null && bucket.isNotEmpty && bucket != 'all') {
        query = query.eq('bucket', bucket);
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        query = query.or('filename.ilike.%$q%,title.ilike.%$q%,alt_text.ilike.%$q%');
      }

      final res = await query.order('sort_order', ascending: true).order('created_at', ascending: false);
      final list = (res as List<dynamic>).map((e) => MediaAsset.fromJson(e as Map<String, dynamic>)).toList();

      if (list.isNotEmpty) return list;
    } catch (_) {}

    // Fallback: list direct storage bucket files if media_assets has no records yet
    return _fetchDirectFromStorage(bucket: bucket);
  }

  /// Direct storage fallback
  Future<List<MediaAsset>> _fetchDirectFromStorage({String? bucket}) async {
    final targetBuckets = (bucket != null && bucket.isNotEmpty && bucket != 'all')
        ? [bucket]
        : ['products', 'collections', 'lookbook', 'journal'];

    final List<MediaAsset> assets = [];

    for (final b in targetBuckets) {
      try {
        final files = await _client.storage.from(b).list();
        for (final f in files) {
          final url = _client.storage.from(b).getPublicUrl(f.name);
          assets.add(
            MediaAsset(
              id: f.id ?? const Uuid().v4(),
              bucket: b,
              filePath: f.name,
              filename: f.name,
              url: url,
              altText: f.name.replaceAll(RegExp(r'[-_]'), ' ').split('.').first,
              title: f.name.replaceAll(RegExp(r'[-_]'), ' ').split('.').first,
              sizeBytes: f.metadata?['size'] as int? ?? 0,
              createdAt: f.createdAt != null ? DateTime.tryParse(f.createdAt!) : null,
              responsiveUrls: {
                'desktop': url,
                'tablet': url,
                'thumbnail': url,
              },
            ),
          );
        }
      } catch (_) {}
    }

    return assets;
  }

  /// Upload a media file with optimization, responsive sizing metadata, and alt text
  Future<MediaAsset> uploadAsset({
    required Uint8List bytes,
    required String filename,
    required String bucket,
    String altText = '',
    String title = '',
    String mimeType = 'image/jpeg',
  }) async {
    final validation = FileUploadValidator.validateImage(
      fileName: filename,
      byteLength: bytes.length,
      mimeType: mimeType,
    );
    if (!validation.isValid) {
      throw Exception(validation.errorMessage ?? 'Invalid image file.');
    }

    final extension = filename.split('.').last.toLowerCase();
    final sanitizedBase = filename.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final uniquePath = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedBase.$extension';

    // 1. Upload to Supabase Storage Bucket
    await _client.storage.from(bucket).uploadBinary(
          uniquePath,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: true,
          ),
        );

    final publicUrl = _client.storage.from(bucket).getPublicUrl(uniquePath);

    // 2. Generate responsive variant representations
    // In CDN environments with Supabase storage transformation, responsive params can be appended
    final responsiveUrls = {
      'original': publicUrl,
      'desktop': '$publicUrl?width=1920&quality=85',
      'tablet': '$publicUrl?width=1080&quality=80',
      'thumbnail': '$publicUrl?width=400&quality=75',
    };

    // 3. Record in public.media_assets table
    final record = {
      'bucket': bucket,
      'file_path': uniquePath,
      'filename': filename,
      'url': publicUrl,
      'alt_text': altText.isNotEmpty ? altText : filename.split('.').first,
      'title': title.isNotEmpty ? title : filename.split('.').first,
      'mime_type': mimeType,
      'size_bytes': bytes.length,
      'sort_order': 0,
      'responsive_urls': responsiveUrls,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      final res = await _client.from('media_assets').insert(record).select().single();
      return MediaAsset.fromJson(res);
    } catch (_) {
      // If table insert fails, return domain representation
      return MediaAsset(
        id: const Uuid().v4(),
        bucket: bucket,
        filePath: uniquePath,
        filename: filename,
        url: publicUrl,
        altText: altText,
        title: title,
        mimeType: mimeType,
        sizeBytes: bytes.length,
        responsiveUrls: responsiveUrls,
        createdAt: DateTime.now(),
      );
    }
  }

  /// Multi-image upload helper
  Future<List<MediaAsset>> uploadMultipleAssets({
    required List<Map<String, dynamic>> filesToUpload,
    required String bucket,
  }) async {
    final List<MediaAsset> uploaded = [];
    for (final item in filesToUpload) {
      final bytes = item['bytes'] as Uint8List;
      final filename = item['filename'] as String;
      final altText = item['alt_text'] as String? ?? '';
      final title = item['title'] as String? ?? '';
      final mimeType = item['mime_type'] as String? ?? 'image/jpeg';

      final asset = await uploadAsset(
        bytes: bytes,
        filename: filename,
        bucket: bucket,
        altText: altText,
        title: title,
        mimeType: mimeType,
      );
      uploaded.add(asset);
    }
    return uploaded;
  }

  /// Update asset metadata (alt text, title, sort order)
  Future<void> updateAssetMetadata({
    required String id,
    String? altText,
    String? title,
    int? sortOrder,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (altText != null) updates['alt_text'] = altText;
    if (title != null) updates['title'] = title;
    if (sortOrder != null) updates['sort_order'] = sortOrder;

    await _client.from('media_assets').update(updates).eq('id', id);
  }

  /// Reorder assets by updating their sort orders sequentially
  Future<void> reorderAssets(List<String> assetIdsInOrder) async {
    for (int i = 0; i < assetIdsInOrder.length; i++) {
      final id = assetIdsInOrder[i];
      try {
        await _client.from('media_assets').update({
          'sort_order': i,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', id);
      } catch (_) {}
    }
  }

  /// Delete asset from database and Supabase storage
  Future<void> deleteAsset(MediaAsset asset) async {
    // 1. Delete from database
    try {
      await _client.from('media_assets').delete().eq('id', asset.id);
    } catch (_) {}

    // 2. Delete from storage bucket
    try {
      await _client.storage.from(asset.bucket).remove([asset.filePath]);
    } catch (_) {}
  }
}

final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService(Supabase.instance.client);
});

final mediaAssetsProvider = FutureProvider.family<List<MediaAsset>, String?>((ref, bucket) async {
  final service = ref.watch(mediaServiceProvider);
  return service.getAssets(bucket: bucket);
});
