import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/features/measurements/data/measurements_repository.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_profile.dart';

class MeasurementsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<MeasurementProfile?> saveProfile(MeasurementProfile profile) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(measurementsRepositoryProvider);
      final saved = await repo.saveProfile(profile);
      ref.invalidate(userMeasurementProfilesProvider(profile.profileId));
      ref.invalidate(defaultMeasurementProfileProvider(profile.profileId));
      state = const AsyncValue.data(null);
      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteProfile(String profileId, String userId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(measurementsRepositoryProvider);
      await repo.deleteProfile(profileId);
      ref.invalidate(userMeasurementProfilesProvider(userId));
      ref.invalidate(defaultMeasurementProfileProvider(userId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> setDefault(String profileId, String userId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(measurementsRepositoryProvider);
      await repo.setDefaultProfile(profileId, userId);
      ref.invalidate(userMeasurementProfilesProvider(userId));
      ref.invalidate(defaultMeasurementProfileProvider(userId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateGarmentRequirements({
    required String productId,
    required List<String> requiredFields,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(measurementsRepositoryProvider);
      await repo.updateGarmentRequiredMeasurements(productId, requiredFields);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final measurementsControllerProvider =
    AsyncNotifierProvider<MeasurementsController, void>(() {
  return MeasurementsController();
});
