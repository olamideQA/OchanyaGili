import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/core/security/file_upload_validator.dart';
import 'package:ochanya_gili/features/custom_atelier/domain/models/custom_request.dart';

class UploadedImageDraft {
  final Uint8List bytes;
  final String fileName;

  UploadedImageDraft({required this.bytes, required this.fileName});
}

class CustomAtelierRepository {
  final SupabaseClient _client;

  CustomAtelierRepository(this._client);

  /// Submits a complete custom atelier request with uploaded reference images
  Future<CustomRequest> submitCustomRequest({
    required String profileId,
    required String occasion,
    required String direction,
    String? inspirationText,
    List<String> inspirationLinks = const [],
    required String fabric,
    required String colour,
    String? measurementProfileId,
    String? specialInstructions,
    List<XFile> imageFiles = const [],
  }) async {
    // 1. Insert base custom_request row
    final insertPayload = {
      'profile_id': profileId,
      'occasion': occasion,
      'direction': direction,
      'inspiration_text': inspirationText,
      'inspiration_links': inspirationLinks,
      'fabric': fabric,
      'colour': colour,
      'measurement_profile_id': measurementProfileId,
      'special_instructions': specialInstructions,
      'status': 'requested',
    };

    final requestRes = await _client
        .from('custom_requests')
        .insert(insertPayload)
        .select()
        .single();

    final requestId = requestRes['id'] as String;

    // 2. Upload reference images with client-side compressed bytes
    final uploadedImages = <CustomRequestImage>[];

    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      try {
        final bytes = await file.readAsBytes();
        final validation = FileUploadValidator.validateImage(
          fileName: file.name,
          byteLength: bytes.length,
          mimeType: file.mimeType ?? 'image/jpeg',
        );
        if (!validation.isValid) {
          continue; // skip invalid files
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storagePath = '$profileId/${requestId}_${timestamp}_$i.jpg';

        await _client.storage.from('custom_requests').uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        final publicUrl = _client.storage.from('custom_requests').getPublicUrl(storagePath);

        final imgRow = await _client.from('custom_request_images').insert({
          'custom_request_id': requestId,
          'image_url': publicUrl,
          'alt_text': 'Reference moodboard image ${i + 1}',
          'sort_order': i,
        }).select().single();

        uploadedImages.add(CustomRequestImage.fromJson(imgRow));
      } catch (e) {
        // Continue with remaining images if one upload errors
      }
    }

    // 3. Return full hydrated request
    return getRequestById(requestId).then((req) => req ?? CustomRequest.fromJson(requestRes));
  }

  /// Get all custom requests created by a customer
  Future<List<CustomRequest>> getUserRequests(String profileId) async {
    try {
      final res = await _client
          .from('custom_requests')
          .select('*, custom_request_images(*), measurement_profiles(*)')
          .eq('profile_id', profileId)
          .order('created_at', ascending: false);

      final list = res as List<dynamic>;
      return list.map((e) => CustomRequest.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get single custom request by UUID
  Future<CustomRequest?> getRequestById(String id) async {
    try {
      final res = await _client
          .from('custom_requests')
          .select('*, custom_request_images(*), measurement_profiles(*), profiles:profile_id(*)')
          .eq('id', id)
          .maybeSingle();

      if (res == null) return null;
      return CustomRequest.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// Get single custom request by Request Number (e.g. CR-20260929-1234)
  Future<CustomRequest?> getRequestByNumber(String requestNumber) async {
    try {
      final res = await _client
          .from('custom_requests')
          .select('*, custom_request_images(*), measurement_profiles(*), profiles:profile_id(*)')
          .eq('request_number', requestNumber)
          .maybeSingle();

      if (res == null) return null;
      return CustomRequest.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// Atelier manager / designer query for custom requests queue
  Future<List<CustomRequest>> getAllRequestsAdmin({
    CustomRequestStatus? statusFilter,
    String? searchQuery,
  }) async {
    try {
      var query = _client
          .from('custom_requests')
          .select('*, custom_request_images(*), measurement_profiles(*), profiles:profile_id(*)');

      if (statusFilter != null) {
        query = query.eq('status', statusFilter.toJson());
      }

      final res = await query.order('created_at', ascending: false);
      final list = res as List<dynamic>;
      var requests = list.map((e) => CustomRequest.fromJson(e as Map<String, dynamic>)).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        requests = requests.where((r) {
          final numberMatch = r.requestNumber.toLowerCase().contains(q);
          final nameMatch = r.customerName?.toLowerCase().contains(q) ?? false;
          final emailMatch = r.customerEmail?.toLowerCase().contains(q) ?? false;
          final occasionMatch = r.occasion.toLowerCase().contains(q);
          return numberMatch || nameMatch || emailMatch || occasionMatch;
        }).toList();
      }

      return requests;
    } catch (_) {
      return [];
    }
  }

  /// Transition custom request status
  Future<void> updateRequestStatus(
    String requestId,
    CustomRequestStatus newStatus, {
    String? designerNotes,
  }) async {
    final payload = <String, dynamic>{
      'status': newStatus.toJson(),
    };
    if (designerNotes != null) {
      payload['designer_notes'] = designerNotes;
    }

    await _client.from('custom_requests').update(payload).eq('id', requestId);
  }
}

final customAtelierRepositoryProvider = Provider<CustomAtelierRepository>((ref) {
  return CustomAtelierRepository(Supabase.instance.client);
});

final userCustomRequestsProvider =
    FutureProvider.family<List<CustomRequest>, String>((ref, userId) {
  return ref.watch(customAtelierRepositoryProvider).getUserRequests(userId);
});

final adminCustomRequestsProvider = FutureProvider.autoDispose
    .family<List<CustomRequest>, (CustomRequestStatus?, String?)>((ref, params) {
  final (status, search) = params;
  return ref.watch(customAtelierRepositoryProvider).getAllRequestsAdmin(
        statusFilter: status,
        searchQuery: search,
      );
});
