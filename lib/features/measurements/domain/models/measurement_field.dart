import 'package:equatable/equatable.dart';

enum MeasurementCategory {
  upperBody('Upper Body & Torso'),
  lowerBody('Trousers & Lower Body'),
  lengths('Vertical Proportions & Lengths'),
  arms('Arms & Sleeves');

  final String title;
  const MeasurementCategory(this.title);
}

class MeasurementField extends Equatable {
  final String key;
  final String label;
  final MeasurementCategory category;
  final String instruction;
  final String atelierTip;
  final double sampleInches;
  final double sampleCm;

  const MeasurementField({
    required this.key,
    required this.label,
    required this.category,
    required this.instruction,
    required this.atelierTip,
    required this.sampleInches,
    required this.sampleCm,
  });

  // Keys as constant identifiers
  static const String shoulder = 'shoulder';
  static const String bust = 'bust';
  static const String underBust = 'under_bust';
  static const String waist = 'waist';
  static const String hip = 'hip';
  static const String armhole = 'armhole';
  static const String sleeveLength = 'sleeve_length';
  static const String bicep = 'bicep';
  static const String wrist = 'wrist';
  static const String backLength = 'back_length';
  static const String frontLength = 'front_length';
  static const String dressLength = 'dress_length';
  static const String trouserWaist = 'trouser_waist';
  static const String trouserHip = 'trouser_hip';
  static const String trouserLength = 'trouser_length';
  static const String inseam = 'inseam';
  static const String thigh = 'thigh';
  static const String neck = 'neck';

  /// Complete list of all 18 anatomical measurement fields required by the Ochanya Gili Atelier
  static const List<MeasurementField> allFields = [
    // Upper Body
    MeasurementField(
      key: shoulder,
      label: 'Shoulder Width',
      category: MeasurementCategory.upperBody,
      instruction: 'Measure across the back from the edge of the left shoulder bone to the right shoulder bone.',
      atelierTip: 'Keep posture natural. Do not hunch or roll shoulders backward.',
      sampleInches: 15.5,
      sampleCm: 39.5,
    ),
    MeasurementField(
      key: bust,
      label: 'Bust Circumference',
      category: MeasurementCategory.upperBody,
      instruction: 'Measure around the fullest part of the bust, keeping the tape parallel to the floor.',
      atelierTip: 'Wear the specific bra or foundation garment you intend to wear with the completed piece.',
      sampleInches: 36.0,
      sampleCm: 91.5,
    ),
    MeasurementField(
      key: underBust,
      label: 'Underbust Circumference',
      category: MeasurementCategory.upperBody,
      instruction: 'Wrap the tape directly beneath the bust rib cage where the bra band sits.',
      atelierTip: 'Breathe normally; ensure the tape is comfortably snug and horizontal.',
      sampleInches: 30.0,
      sampleCm: 76.2,
    ),
    MeasurementField(
      key: waist,
      label: 'Natural Waist',
      category: MeasurementCategory.upperBody,
      instruction: 'Measure around the narrowest point of your torso, typically 1 to 2 inches above the navel.',
      atelierTip: 'Bend slightly to the side to locate your natural crease.',
      sampleInches: 28.0,
      sampleCm: 71.1,
    ),
    MeasurementField(
      key: hip,
      label: 'Full Hip',
      category: MeasurementCategory.upperBody,
      instruction: 'Measure around the fullest part of your hips and buttocks, keeping feet together.',
      atelierTip: 'Stand upright and do not pull the tape tight; it should skim the contours.',
      sampleInches: 39.0,
      sampleCm: 99.0,
    ),
    MeasurementField(
      key: neck,
      label: 'Neck Circumference',
      category: MeasurementCategory.upperBody,
      instruction: 'Measure around the base of the neck, resting just above the collarbone.',
      atelierTip: 'Place one finger between tape and skin to ensure ease.',
      sampleInches: 14.0,
      sampleCm: 35.5,
    ),

    // Arms & Sleeves
    MeasurementField(
      key: armhole,
      label: 'Armhole Circumference',
      category: MeasurementCategory.arms,
      instruction: 'Loop tape under the armpit and over the top of the shoulder joint.',
      atelierTip: 'Keep arm relaxed by your side to ensure mobility in tailored sleeves.',
      sampleInches: 17.0,
      sampleCm: 43.2,
    ),
    MeasurementField(
      key: sleeveLength,
      label: 'Sleeve Length',
      category: MeasurementCategory.arms,
      instruction: 'From the shoulder tip bone down over the elbow to the wrist bone.',
      atelierTip: 'Keep your arm slightly bent at a 90-degree angle for accurate sleeve ease.',
      sampleInches: 24.0,
      sampleCm: 61.0,
    ),
    MeasurementField(
      key: bicep,
      label: 'Bicep Circumference',
      category: MeasurementCategory.arms,
      instruction: 'Wrap tape around the fullest part of the upper arm, muscle relaxed.',
      atelierTip: 'Ensure the arm is resting naturally down, not flexed.',
      sampleInches: 11.5,
      sampleCm: 29.2,
    ),
    MeasurementField(
      key: wrist,
      label: 'Wrist Circumference',
      category: MeasurementCategory.arms,
      instruction: 'Measure around the wrist bone where a tailored cuff rests.',
      atelierTip: 'For French cuff or buttoned designs, allow 0.5 inch ease.',
      sampleInches: 6.5,
      sampleCm: 16.5,
    ),

    // Vertical Proportions & Lengths
    MeasurementField(
      key: frontLength,
      label: 'Front Length (Shoulder to Waist)',
      category: MeasurementCategory.lengths,
      instruction: 'From the highest point of shoulder beside the neck, over the apex of the bust to the natural waistline.',
      atelierTip: 'Critical for corset, peplum, and fitted bodice construction.',
      sampleInches: 16.5,
      sampleCm: 42.0,
    ),
    MeasurementField(
      key: backLength,
      label: 'Back Length (Nape to Waist)',
      category: MeasurementCategory.lengths,
      instruction: 'From the prominent neck vertebra at the nape straight down along the spine to the natural waist.',
      atelierTip: 'Stand straight; head level.',
      sampleInches: 15.5,
      sampleCm: 39.4,
    ),
    MeasurementField(
      key: dressLength,
      label: 'Full Dress Length',
      category: MeasurementCategory.lengths,
      instruction: 'From the highest point of shoulder at neck down to the desired hemline (floor, midi, or knee).',
      atelierTip: 'Wear the heel height you intend to pair with this gown.',
      sampleInches: 58.0,
      sampleCm: 147.3,
    ),

    // Trousers & Lower Body
    MeasurementField(
      key: trouserWaist,
      label: 'Trouser Waistband',
      category: MeasurementCategory.lowerBody,
      instruction: 'Measure where you prefer your trouser waistband to sit (high-rise, mid-rise, or low).',
      atelierTip: 'For high-waisted cigarette pants, align with the natural waist.',
      sampleInches: 29.0,
      sampleCm: 73.7,
    ),
    MeasurementField(
      key: trouserHip,
      label: 'Trouser Hip Circumference',
      category: MeasurementCategory.lowerBody,
      instruction: 'Measure around the fullest part of seat with pockets relaxed.',
      atelierTip: 'Empty all pockets and stand with feet slightly apart.',
      sampleInches: 40.0,
      sampleCm: 101.6,
    ),
    MeasurementField(
      key: trouserLength,
      label: 'Outseam (Trouser Length)',
      category: MeasurementCategory.lowerBody,
      instruction: 'From the top of the trouser waistband down the side of the leg to the floor or ankle hem.',
      atelierTip: 'Must include heel height allowance if trousers will be worn with stilettos.',
      sampleInches: 42.0,
      sampleCm: 106.7,
    ),
    MeasurementField(
      key: inseam,
      label: 'Inseam',
      category: MeasurementCategory.lowerBody,
      instruction: 'From the lowest crotch seam down the inner leg to the bottom hem.',
      atelierTip: 'Best measured along an existing pair of perfectly fitting tailored trousers.',
      sampleInches: 31.0,
      sampleCm: 78.7,
    ),
    MeasurementField(
      key: thigh,
      label: 'Thigh Circumference',
      category: MeasurementCategory.lowerBody,
      instruction: 'Measure around the fullest part of the upper thigh, roughly 1 inch below the crotch.',
      atelierTip: 'Ensure measuring tape is parallel to floor and not pinching skin.',
      sampleInches: 22.0,
      sampleCm: 55.9,
    ),
  ];

  static MeasurementField byKey(String key) {
    return allFields.firstWhere(
      (f) => f.key == key,
      orElse: () => MeasurementField(
        key: key,
        label: key.replaceAll('_', ' ').toUpperCase(),
        category: MeasurementCategory.upperBody,
        instruction: 'Measure precision circumference or length for $key.',
        atelierTip: 'Keep tape snug and level.',
        sampleInches: 0.0,
        sampleCm: 0.0,
      ),
    );
  }

  static List<MeasurementField> forKeys(List<String> keys) {
    return keys.map((k) => byKey(k)).toList();
  }

  @override
  List<Object?> get props => [key, label, category, instruction, atelierTip, sampleInches, sampleCm];
}
