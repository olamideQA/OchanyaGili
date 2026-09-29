import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_profile.dart';

class MeasurementsRepository {
  final SupabaseClient _client;

  MeasurementsRepository(this._client);

  /// Fetch all saved anatomical measurement profiles for a customer
  Future<List<MeasurementProfile>> getUserProfiles(String profileId) async {
    try {
      final res = await _client
          .from('measurement_profiles')
          .select()
          .eq('profile_id', profileId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      final list = res as List<dynamic>;
      return list.map((e) => MeasurementProfile.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get single profile by UUID
  Future<MeasurementProfile?> getProfileById(String id) async {
    try {
      final res = await _client.from('measurement_profiles').select().eq('id', id).maybeSingle();
      if (res == null) return null;
      return MeasurementProfile.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// Get the active default profile for a user
  Future<MeasurementProfile?> getDefaultProfile(String profileId) async {
    try {
      final res = await _client
          .from('measurement_profiles')
          .select()
          .eq('profile_id', profileId)
          .eq('is_default', true)
          .maybeSingle();

      if (res != null) {
        return MeasurementProfile.fromJson(res);
      }

      // Fallback: pick the latest profile if none explicitly marked default
      final all = await getUserProfiles(profileId);
      return all.isNotEmpty ? all.first : null;
    } catch (_) {
      return null;
    }
  }

  /// Create or update a customer measurement profile
  Future<MeasurementProfile> saveProfile(MeasurementProfile profile) async {
    final payload = profile.toJson(includeId: false);

    if (profile.id.isNotEmpty) {
      final res = await _client
          .from('measurement_profiles')
          .update(payload)
          .eq('id', profile.id)
          .select()
          .single();
      return MeasurementProfile.fromJson(res);
    } else {
      final res = await _client
          .from('measurement_profiles')
          .insert(payload)
          .select()
          .single();
      return MeasurementProfile.fromJson(res);
    }
  }

  /// Delete a saved profile
  Future<void> deleteProfile(String id) async {
    await _client.from('measurement_profiles').delete().eq('id', id);
  }

  /// Designate a profile as default (database trigger will unset others)
  Future<void> setDefaultProfile(String profileId, String userId) async {
    await _client
        .from('measurement_profiles')
        .update({'is_default': true})
        .eq('id', profileId)
        .eq('profile_id', userId);
  }

  /// Designer configuration: update which measurements a garment requires
  Future<void> updateGarmentRequiredMeasurements(
    String productId,
    List<String> requiredFields,
  ) async {
    await _client
        .from('products')
        .update({'required_measurements': requiredFields})
        .eq('id', productId);
  }
}

final measurementsRepositoryProvider = Provider<MeasurementsRepository>((ref) {
  return MeasurementsRepository(Supabase.instance.client);
});

final userMeasurementProfilesProvider =
    FutureProvider.family<List<MeasurementProfile>, String>((ref, userId) {
  return ref.watch(measurementsRepositoryProvider).getUserProfiles(userId);
});

final defaultMeasurementProfileProvider =
    FutureProvider.family<MeasurementProfile?, String>((ref, userId) {
  return ref.watch(measurementsRepositoryProvider).getDefaultProfile(userId);
});
