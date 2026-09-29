import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ochanya_gili/features/custom_atelier/data/custom_atelier_repository.dart';
import 'package:ochanya_gili/features/custom_atelier/domain/models/custom_request.dart';
import 'package:ochanya_gili/features/measurements/data/measurements_repository.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_profile.dart';

class CustomAtelierWizardState extends Equatable {
  final int currentStep; // 0 to 6
  final String? occasion;
  final String? direction;
  final String inspirationText;
  final List<String> inspirationLinks;
  final List<XFile> selectedImages;
  final String? fabric;
  final String? colour;
  final String measurementOption; // 'saved' or 'new'
  final String? measurementProfileId;
  final String? measurementProfileName;
  final MeasurementProfile? newProfileData;
  final String specialInstructions;
  final bool isSubmitting;
  final String? errorMessage;
  final CustomRequest? submittedRequest;

  const CustomAtelierWizardState({
    this.currentStep = 0,
    this.occasion,
    this.direction,
    this.inspirationText = '',
    this.inspirationLinks = const [],
    this.selectedImages = const [],
    this.fabric,
    this.colour,
    this.measurementOption = 'saved',
    this.measurementProfileId,
    this.measurementProfileName,
    this.newProfileData,
    this.specialInstructions = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.submittedRequest,
  });

  bool canAdvanceFromStep(int step) {
    switch (step) {
      case 0:
        return occasion != null && occasion!.isNotEmpty;
      case 1:
        return direction != null && direction!.isNotEmpty;
      case 2:
        // Inspiration is satisfied if images, link, or text is provided
        return selectedImages.isNotEmpty ||
            inspirationLinks.isNotEmpty ||
            inspirationText.trim().isNotEmpty;
      case 3:
        return fabric != null && fabric!.isNotEmpty;
      case 4:
        return colour != null && colour!.isNotEmpty;
      case 5:
        if (measurementOption == 'saved') {
          return measurementProfileId != null && measurementProfileId!.isNotEmpty;
        } else {
          return newProfileData != null;
        }
      case 6:
        return true; // Review step
      default:
        return false;
    }
  }

  CustomAtelierWizardState copyWith({
    int? currentStep,
    String? occasion,
    String? direction,
    String? inspirationText,
    List<String>? inspirationLinks,
    List<XFile>? selectedImages,
    String? fabric,
    String? colour,
    String? measurementOption,
    String? measurementProfileId,
    String? measurementProfileName,
    MeasurementProfile? newProfileData,
    String? specialInstructions,
    bool? isSubmitting,
    String? errorMessage,
    CustomRequest? submittedRequest,
    bool clearError = false,
  }) {
    return CustomAtelierWizardState(
      currentStep: currentStep ?? this.currentStep,
      occasion: occasion ?? this.occasion,
      direction: direction ?? this.direction,
      inspirationText: inspirationText ?? this.inspirationText,
      inspirationLinks: inspirationLinks ?? this.inspirationLinks,
      selectedImages: selectedImages ?? this.selectedImages,
      fabric: fabric ?? this.fabric,
      colour: colour ?? this.colour,
      measurementOption: measurementOption ?? this.measurementOption,
      measurementProfileId: measurementProfileId ?? this.measurementProfileId,
      measurementProfileName: measurementProfileName ?? this.measurementProfileName,
      newProfileData: newProfileData ?? this.newProfileData,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      submittedRequest: submittedRequest ?? this.submittedRequest,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        occasion,
        direction,
        inspirationText,
        inspirationLinks,
        selectedImages,
        fabric,
        colour,
        measurementOption,
        measurementProfileId,
        measurementProfileName,
        newProfileData,
        specialInstructions,
        isSubmitting,
        errorMessage,
        submittedRequest,
      ];
}

class CustomAtelierWizardNotifier extends Notifier<CustomAtelierWizardState> {
  @override
  CustomAtelierWizardState build() {
    return const CustomAtelierWizardState();
  }

  void setStep(int step) {
    if (step >= 0 && step <= 6) {
      state = state.copyWith(currentStep: step, clearError: true);
    }
  }

  void nextStep() {
    if (state.currentStep < 6 && state.canAdvanceFromStep(state.currentStep)) {
      state = state.copyWith(currentStep: state.currentStep + 1, clearError: true);
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1, clearError: true);
    }
  }

  void setOccasion(String occasion) {
    state = state.copyWith(occasion: occasion);
  }

  void setDirection(String direction) {
    state = state.copyWith(direction: direction);
  }

  void setInspirationText(String text) {
    state = state.copyWith(inspirationText: text);
  }

  void addInspirationLink(String link) {
    if (link.trim().isEmpty) return;
    final updated = List<String>.from(state.inspirationLinks)..add(link.trim());
    state = state.copyWith(inspirationLinks: updated);
  }

  void removeInspirationLink(int index) {
    if (index >= 0 && index < state.inspirationLinks.length) {
      final updated = List<String>.from(state.inspirationLinks)..removeAt(index);
      state = state.copyWith(inspirationLinks: updated);
    }
  }

  void addImages(List<XFile> files) {
    final updated = List<XFile>.from(state.selectedImages)..addAll(files);
    state = state.copyWith(selectedImages: updated);
  }

  void removeImage(int index) {
    if (index >= 0 && index < state.selectedImages.length) {
      final updated = List<XFile>.from(state.selectedImages)..removeAt(index);
      state = state.copyWith(selectedImages: updated);
    }
  }

  void setFabric(String fabric) {
    state = state.copyWith(fabric: fabric);
  }

  void setColour(String colour) {
    state = state.copyWith(colour: colour);
  }

  void setMeasurementOption(String option) {
    state = state.copyWith(measurementOption: option);
  }

  void setSavedMeasurementProfile(String profileId, String profileName) {
    state = state.copyWith(
      measurementOption: 'saved',
      measurementProfileId: profileId,
      measurementProfileName: profileName,
    );
  }

  void setNewMeasurementProfile(MeasurementProfile profile) {
    state = state.copyWith(
      measurementOption: 'new',
      newProfileData: profile,
    );
  }

  void setSpecialInstructions(String text) {
    state = state.copyWith(specialInstructions: text);
  }

  Future<CustomRequest?> submit(String userId) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      String? finalProfileId = state.measurementProfileId;

      // If user entered a new profile, save it to DB first
      if (state.measurementOption == 'new' && state.newProfileData != null) {
        final profileToSave = state.newProfileData!.copyWith(profileId: userId);
        final savedProfile = await ref
            .read(measurementsRepositoryProvider)
            .saveProfile(profileToSave);
        finalProfileId = savedProfile.id;
      }

      final repo = ref.read(customAtelierRepositoryProvider);
      final created = await repo.submitCustomRequest(
        profileId: userId,
        occasion: state.occasion ?? 'Bespoke Couture',
        direction: state.direction ?? 'Custom Ensemble',
        inspirationText: state.inspirationText.trim().isNotEmpty ? state.inspirationText.trim() : null,
        inspirationLinks: state.inspirationLinks,
        fabric: state.fabric ?? 'Custom Sourced',
        colour: state.colour ?? '#C9A96E',
        measurementProfileId: finalProfileId,
        specialInstructions: state.specialInstructions.trim().isNotEmpty ? state.specialInstructions.trim() : null,
        imageFiles: state.selectedImages,
      );

      // Invalidate customer requests
      ref.invalidate(userCustomRequestsProvider(userId));

      state = state.copyWith(
        isSubmitting: false,
        submittedRequest: created,
      );

      return created;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  void reset() {
    state = const CustomAtelierWizardState();
  }
}

final customAtelierWizardProvider =
    NotifierProvider<CustomAtelierWizardNotifier, CustomAtelierWizardState>(() {
  return CustomAtelierWizardNotifier();
});
