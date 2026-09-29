import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ochanya_gili/features/custom_atelier/domain/models/custom_request.dart';
import 'package:ochanya_gili/features/custom_atelier/domain/models/custom_atelier_options.dart';
import 'package:ochanya_gili/features/custom_atelier/presentation/providers/custom_atelier_wizard_provider.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_profile.dart';

void main() {
  group('Loop 7: Custom Atelier ("Create Your Look") Tests', () {
    test('CustomRequestStatus parses all 11 lifecycle statuses correctly', () {
      expect(CustomRequestStatus.values.length, equals(11));

      expect(CustomRequestStatus.fromString('requested'), equals(CustomRequestStatus.requested));
      expect(CustomRequestStatus.fromString('under_review'), equals(CustomRequestStatus.underReview));
      expect(CustomRequestStatus.fromString('design_discussion'), equals(CustomRequestStatus.designDiscussion));
      expect(CustomRequestStatus.fromString('quote_sent'), equals(CustomRequestStatus.quoteSent));
      expect(CustomRequestStatus.fromString('customer_approved'), equals(CustomRequestStatus.customerApproved));
      expect(CustomRequestStatus.fromString('payment'), equals(CustomRequestStatus.payment));
      expect(CustomRequestStatus.fromString('production'), equals(CustomRequestStatus.production));
      expect(CustomRequestStatus.fromString('fitting'), equals(CustomRequestStatus.fitting));
      expect(CustomRequestStatus.fromString('alteration'), equals(CustomRequestStatus.alteration));
      expect(CustomRequestStatus.fromString('ready'), equals(CustomRequestStatus.ready));
      expect(CustomRequestStatus.fromString('delivered'), equals(CustomRequestStatus.delivered));

      for (final s in CustomRequestStatus.values) {
        expect(CustomRequestStatus.fromString(s.toJson()), equals(s));
      }
    });

    test('CustomRequest and CustomRequestImage serialization round-trip', () {
      final request = CustomRequest(
        id: 'cr_123',
        requestNumber: 'CR-20260929-7788',
        profileId: 'usr_456',
        customerName: 'Lady Ochanya Audu',
        customerEmail: 'ochanya@example.com',
        occasion: 'Red Carpet & Gala',
        direction: 'Architectural Gown',
        inspirationText: 'Structured boned peplum with cathedral organza train.',
        inspirationLinks: const ['https://pinterest.com/pin/12345'],
        fabric: 'French Beaded Lace',
        colour: 'Atelier Royal Gold',
        measurementProfileId: 'mp_789',
        specialInstructions: 'Fitting required in Abuja Salon 2 weeks before event.',
        status: CustomRequestStatus.underReview,
        designerNotes: 'Reviewed by head tailor. Silk organza under-structure recommended.',
        images: const [
          CustomRequestImage(
            id: 'img_1',
            customRequestId: 'cr_123',
            imageUrl: 'https://storage.supabase.co/custom_requests/img1.jpg',
            sortOrder: 0,
          ),
        ],
      );

      final json = request.toJson();
      expect(json['request_number'], equals('CR-20260929-7788'));
      expect(json['occasion'], equals('Red Carpet & Gala'));
      expect(json['fabric'], equals('French Beaded Lace'));
      expect(json['status'], equals('under_review'));

      // Simulate joined payload from PostgREST
      final joinedJson = Map<String, dynamic>.from(json);
      joinedJson['id'] = 'cr_123';
      joinedJson['profiles'] = {'full_name': 'Lady Ochanya Audu', 'email': 'ochanya@example.com'};
      joinedJson['custom_request_images'] = [
        {
          'id': 'img_1',
          'custom_request_id': 'cr_123',
          'image_url': 'https://storage.supabase.co/custom_requests/img1.jpg',
          'sort_order': 0,
        }
      ];

      final restored = CustomRequest.fromJson(joinedJson);
      expect(restored.id, equals('cr_123'));
      expect(restored.customerName, equals('Lady Ochanya Audu'));
      expect(restored.images.length, equals(1));
      expect(restored.images.first.imageUrl, equals('https://storage.supabase.co/custom_requests/img1.jpg'));
      expect(restored.inspirationLinks, contains('https://pinterest.com/pin/12345'));
    });

    test('CustomAtelierOptions provides complete presets matching specifications', () {
      expect(OccasionOption.all.length, equals(9));
      expect(OccasionOption.all.any((o) => o.id == 'wedding'), isTrue);
      expect(OccasionOption.all.any((o) => o.id == 'red_carpet'), isTrue);

      expect(DirectionOption.all.length, equals(8));
      expect(DirectionOption.all.any((d) => d.id == 'gown'), isTrue);
      expect(DirectionOption.all.any((d) => d.id == 'two_piece'), isTrue);
      expect(DirectionOption.all.any((d) => d.id == 'kaftan'), isTrue);

      expect(FabricOption.all.length, equals(7));
      expect(FabricOption.all.any((f) => f.id == 'lace'), isTrue);
      expect(FabricOption.all.any((f) => f.id == 'silk'), isTrue);
      expect(FabricOption.all.any((f) => f.id == 'ankara'), isTrue);
      expect(FabricOption.all.any((f) => f.id == 'velvet'), isTrue);

      expect(ColourOption.curatedPalette.length, greaterThanOrEqualTo(8));
    });

    test('CustomAtelierWizardNotifier preserves state during backward and forward step navigation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(customAtelierWizardProvider.notifier);

      // Step 0: Initial state
      var state = container.read(customAtelierWizardProvider);
      expect(state.currentStep, equals(0));
      expect(state.canAdvanceFromStep(0), isFalse);

      // Select Occasion
      notifier.setOccasion('Bridal & Wedding');
      state = container.read(customAtelierWizardProvider);
      expect(state.canAdvanceFromStep(0), isTrue);

      // Step 1: Direction
      notifier.nextStep();
      state = container.read(customAtelierWizardProvider);
      expect(state.currentStep, equals(1));
      expect(state.canAdvanceFromStep(1), isFalse);

      notifier.setDirection('Architectural Gown');
      state = container.read(customAtelierWizardProvider);
      expect(state.canAdvanceFromStep(1), isTrue);

      // Step 2: Inspiration
      notifier.nextStep();
      state = container.read(customAtelierWizardProvider);
      expect(state.currentStep, equals(2));
      notifier.setInspirationText('Cathedral length train with pure pearls.');
      notifier.addInspirationLink('https://instagram.com/p/atelier-preview');
      notifier.addImages([XFile('moodboard.jpg')]);

      state = container.read(customAtelierWizardProvider);
      expect(state.canAdvanceFromStep(2), isTrue);

      // Step 3: Fabric
      notifier.nextStep();
      state = container.read(customAtelierWizardProvider);
      expect(state.currentStep, equals(3));
      notifier.setFabric('Pure Mulberry Silk Crepe');

      // Step 4: Colour
      notifier.nextStep();
      state = container.read(customAtelierWizardProvider);
      expect(state.currentStep, equals(4));
      notifier.setColour('Atelier Royal Gold');

      // Step 5: Measurements
      notifier.nextStep();
      state = container.read(customAtelierWizardProvider);
      expect(state.currentStep, equals(5));
      notifier.setSavedMeasurementProfile('mp_saved_1', 'Lady Audu Gala Profile');

      // Step 6: Review
      notifier.nextStep();
      state = container.read(customAtelierWizardProvider);
      expect(state.currentStep, equals(6));

      // CRITICAL DEBUG SPEC TEST: Navigate all the way back to Step 0 and confirm NO data was lost!
      for (int i = 0; i < 6; i++) {
        notifier.prevStep();
      }

      state = container.read(customAtelierWizardProvider);
      expect(state.currentStep, equals(0));
      expect(state.occasion, equals('Bridal & Wedding'));
      expect(state.direction, equals('Architectural Gown'));
      expect(state.inspirationText, equals('Cathedral length train with pure pearls.'));
      expect(state.inspirationLinks, contains('https://instagram.com/p/atelier-preview'));
      expect(state.selectedImages.length, equals(1));
      expect(state.fabric, equals('Pure Mulberry Silk Crepe'));
      expect(state.colour, equals('Atelier Royal Gold'));
      expect(state.measurementProfileId, equals('mp_saved_1'));
      expect(state.measurementProfileName, equals('Lady Audu Gala Profile'));
    });

    test('CustomAtelierWizardNotifier supports entering new measurements in step 5', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(customAtelierWizardProvider.notifier);

      const newProfile = MeasurementProfile(
        id: '',
        profileId: 'usr_new',
        name: 'New Custom Measurements',
        bust: 37.0,
        waist: 28.5,
        hip: 40.0,
        dressLength: 60.0,
      );

      notifier.setNewMeasurementProfile(newProfile);

      final state = container.read(customAtelierWizardProvider);
      expect(state.measurementOption, equals('new'));
      expect(state.newProfileData, equals(newProfile));
      expect(state.canAdvanceFromStep(5), isTrue);
    });
  });
}
