import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_field.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_profile.dart';
import 'package:ochanya_gili/features/shop/domain/models/product.dart';

void main() {
  group('Loop 6: Measurement System Tests', () {
    test('MeasurementField contains all 18 anatomical fields across 4 categories', () {
      expect(MeasurementField.allFields.length, equals(18));

      final upper = MeasurementField.allFields
          .where((f) => f.category == MeasurementCategory.upperBody)
          .toList();
      final lower = MeasurementField.allFields
          .where((f) => f.category == MeasurementCategory.lowerBody)
          .toList();
      final lengths = MeasurementField.allFields
          .where((f) => f.category == MeasurementCategory.lengths)
          .toList();
      final arms = MeasurementField.allFields
          .where((f) => f.category == MeasurementCategory.arms)
          .toList();

      expect(upper.isNotEmpty, isTrue);
      expect(lower.isNotEmpty, isTrue);
      expect(lengths.isNotEmpty, isTrue);
      expect(arms.isNotEmpty, isTrue);

      expect(upper.length + lower.length + lengths.length + arms.length, equals(18));
    });

    test('MeasurementField.byKey correctly resolves fields and atelier tips', () {
      final bust = MeasurementField.byKey(MeasurementField.bust);
      expect(bust.label, equals('Bust Circumference'));
      expect(bust.atelierTip.isNotEmpty, isTrue);
      expect(bust.instruction.isNotEmpty, isTrue);

      final inseam = MeasurementField.byKey(MeasurementField.inseam);
      expect(inseam.label, equals('Inseam'));
      expect(inseam.category, equals(MeasurementCategory.lowerBody));
    });

    test('MeasurementProfile JSON round-trip serialization preserves all 18 fields', () {
      const profile = MeasurementProfile(
        id: 'prof_test_123',
        profileId: 'usr_test_456',
        name: 'Gala Evening Silhouette',
        shoulder: 16.0,
        bust: 36.5,
        underBust: 30.0,
        waist: 28.0,
        hip: 39.5,
        armhole: 17.0,
        sleeveLength: 24.5,
        bicep: 12.0,
        wrist: 6.5,
        backLength: 16.0,
        frontLength: 17.0,
        dressLength: 59.0,
        trouserWaist: 29.0,
        trouserHip: 40.0,
        trouserLength: 42.5,
        inseam: 31.0,
        thigh: 22.5,
        neck: 14.0,
        unit: 'inches',
        isDefault: true,
        notes: 'Wear with 4-inch Christian Louboutin heels.',
      );

      final json = profile.toJson();
      expect(json['name'], equals('Gala Evening Silhouette'));
      expect(json['bust'], equals(36.5));
      expect(json['dress_length'], equals(59.0));
      expect(json['trouser_length'], equals(42.5));
      expect(json['is_default'], isTrue);

      final restored = MeasurementProfile.fromJson(json);
      expect(restored.id, equals(profile.id));
      expect(restored.shoulder, equals(16.0));
      expect(restored.bust, equals(36.5));
      expect(restored.underBust, equals(30.0));
      expect(restored.waist, equals(28.0));
      expect(restored.hip, equals(39.5));
      expect(restored.armhole, equals(17.0));
      expect(restored.sleeveLength, equals(24.5));
      expect(restored.bicep, equals(12.0));
      expect(restored.wrist, equals(6.5));
      expect(restored.backLength, equals(16.0));
      expect(restored.frontLength, equals(17.0));
      expect(restored.dressLength, equals(59.0));
      expect(restored.trouserWaist, equals(29.0));
      expect(restored.trouserHip, equals(40.0));
      expect(restored.trouserLength, equals(42.5));
      expect(restored.inseam, equals(31.0));
      expect(restored.thigh, equals(22.5));
      expect(restored.neck, equals(14.0));
      expect(restored.unit, equals('inches'));
      expect(restored.isDefault, isTrue);
      expect(restored.notes, equals('Wear with 4-inch Christian Louboutin heels.'));
    });

    test('MeasurementProfile unit conversion converts between inches and cm accurately', () {
      const inProfile = MeasurementProfile(
        id: 'prof_1',
        profileId: 'usr_1',
        name: 'Inches Profile',
        waist: 28.0, // 28 * 2.54 = 71.12 -> 71.1
        dressLength: 60.0, // 60 * 2.54 = 152.4
        unit: 'inches',
      );

      final cmProfile = inProfile.convertUnit('cm');
      expect(cmProfile.unit, equals('cm'));
      expect(cmProfile.waist, equals(71.1));
      expect(cmProfile.dressLength, equals(152.4));

      // Re-convert to inches
      final backToInches = cmProfile.convertUnit('inches');
      expect(backToInches.unit, equals('inches'));
      expect(backToInches.waist, equals(28.0));
      expect(backToInches.dressLength, equals(60.0));
    });

    test('MeasurementProfile dynamic required fields validation', () {
      const partialProfile = MeasurementProfile(
        id: 'prof_gown',
        profileId: 'usr_1',
        name: 'Gown Fit',
        shoulder: 15.5,
        bust: 36.0,
        underBust: 30.0,
        waist: 28.0,
        hip: 39.0,
        frontLength: 16.5,
        dressLength: 58.0,
        unit: 'inches',
      );

      final gownRequirements = [
        MeasurementField.shoulder,
        MeasurementField.bust,
        MeasurementField.waist,
        MeasurementField.hip,
        MeasurementField.dressLength,
      ];

      // Gown requirements are fully satisfied
      expect(partialProfile.hasAllRequiredFields(gownRequirements), isTrue);
      expect(partialProfile.getMissingFields(gownRequirements), isEmpty);

      // Trouser requirements are NOT satisfied by gown profile
      final trouserRequirements = [
        MeasurementField.trouserWaist,
        MeasurementField.trouserHip,
        MeasurementField.trouserLength,
        MeasurementField.inseam,
        MeasurementField.thigh,
      ];

      expect(partialProfile.hasAllRequiredFields(trouserRequirements), isFalse);
      final missing = partialProfile.getMissingFields(trouserRequirements);
      expect(missing.length, equals(5));
      expect(missing, contains(MeasurementField.inseam));
      expect(missing, contains(MeasurementField.trouserLength));
    });

    test('Product dynamic effectiveRequiredMeasurements resolution and designer adaptation', () {
      // 1. Ready-to-wear has no required measurements
      const rtw = Product(
        id: 'p_rtw',
        name: 'RTW Blazer',
        slug: 'rtw-blazer',
        productType: ProductType.readyToWear,
        basePrice: 150000,
      );
      expect(rtw.effectiveRequiredMeasurements, isEmpty);

      // 2. Made-to-order without explicit config falls back to default gown requirements
      const mtoDefault = Product(
        id: 'p_mto',
        name: 'MTO Gown',
        slug: 'mto-gown',
        productType: ProductType.madeToOrder,
        basePrice: 350000,
      );
      expect(mtoDefault.effectiveRequiredMeasurements, contains('bust'));
      expect(mtoDefault.effectiveRequiredMeasurements, contains('dress_length'));

      // 3. Made-to-order with explicit designer configuration adapts immediately
      const mtoTrouser = Product(
        id: 'p_mto_trouser',
        name: 'Tailored Trousers',
        slug: 'tailored-trousers',
        productType: ProductType.madeToOrder,
        basePrice: 145000,
        requiredMeasurements: ['trouser_waist', 'trouser_hip', 'trouser_length', 'inseam', 'thigh'],
      );
      expect(mtoTrouser.effectiveRequiredMeasurements.length, equals(5));
      expect(mtoTrouser.effectiveRequiredMeasurements, contains('inseam'));
      expect(mtoTrouser.effectiveRequiredMeasurements, isNot(contains('bust')));

      // 4. Custom couture requires full anatomical profile
      const custom = Product(
        id: 'p_custom',
        name: 'Bespoke Ensamble',
        slug: 'bespoke-ensemble',
        productType: ProductType.custom,
        basePrice: 650000,
      );
      expect(custom.effectiveRequiredMeasurements.length, equals(18));
    });

    test('Customer can reuse saved profile across different garments and form adapts dynamically', () {
      // Step 1: Customer creates standard gala profile with 7 torso & length measurements
      var customerProfile = const MeasurementProfile(
        id: 'prof_customer_1',
        profileId: 'usr_customer_1',
        name: 'Primary Profile',
        shoulder: 15.5,
        bust: 36.0,
        underBust: 30.0,
        waist: 28.0,
        hip: 39.0,
        frontLength: 16.5,
        dressLength: 58.0,
        unit: 'inches',
      );

      final gownFields = ['shoulder', 'bust', 'waist', 'hip', 'dress_length'];
      expect(customerProfile.hasAllRequiredFields(gownFields), isTrue);

      // Step 2: Customer orders trousers which require 5 lower-body measurements
      final trouserFields = ['trouser_waist', 'trouser_hip', 'trouser_length', 'inseam', 'thigh'];
      expect(customerProfile.hasAllRequiredFields(trouserFields), isFalse);

      final missingForTrouser = customerProfile.getMissingFields(trouserFields);
      expect(missingForTrouser.length, equals(5));

      // Step 3: Customer fills only the missing trouser points without re-entering existing fields
      customerProfile = customerProfile
          .copyWithField('trouser_waist', 29.0)
          .copyWithField('trouser_hip', 40.0)
          .copyWithField('trouser_length', 42.0)
          .copyWithField('inseam', 31.0)
          .copyWithField('thigh', 22.0);

      // Step 4: Now the same profile satisfies BOTH the gown AND the trousers!
      expect(customerProfile.hasAllRequiredFields(gownFields), isTrue);
      expect(customerProfile.hasAllRequiredFields(trouserFields), isTrue);
    });
  });
}
