import 'package:equatable/equatable.dart';
import 'measurement_field.dart';

class MeasurementProfile extends Equatable {
  final String id;
  final String profileId;
  final String name;
  final double? shoulder;
  final double? bust;
  final double? underBust;
  final double? waist;
  final double? hip;
  final double? armhole;
  final double? sleeveLength;
  final double? bicep;
  final double? wrist;
  final double? backLength;
  final double? frontLength;
  final double? dressLength;
  final double? trouserWaist;
  final double? trouserHip;
  final double? trouserLength;
  final double? inseam;
  final double? thigh;
  final double? neck;
  final String unit; // 'inches' or 'cm'
  final bool isDefault;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MeasurementProfile({
    required this.id,
    required this.profileId,
    this.name = 'My Measurements',
    this.shoulder,
    this.bust,
    this.underBust,
    this.waist,
    this.hip,
    this.armhole,
    this.sleeveLength,
    this.bicep,
    this.wrist,
    this.backLength,
    this.frontLength,
    this.dressLength,
    this.trouserWaist,
    this.trouserHip,
    this.trouserLength,
    this.inseam,
    this.thigh,
    this.neck,
    this.unit = 'inches',
    this.isDefault = false,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  bool get isInches => unit == 'inches';
  bool get isCm => unit == 'cm';

  /// Dynamically access any of the 18 measurement fields by database key
  double? getValue(String key) {
    switch (key) {
      case MeasurementField.shoulder:
        return shoulder;
      case MeasurementField.bust:
        return bust;
      case MeasurementField.underBust:
        return underBust;
      case MeasurementField.waist:
        return waist;
      case MeasurementField.hip:
        return hip;
      case MeasurementField.armhole:
        return armhole;
      case MeasurementField.sleeveLength:
        return sleeveLength;
      case MeasurementField.bicep:
        return bicep;
      case MeasurementField.wrist:
        return wrist;
      case MeasurementField.backLength:
        return backLength;
      case MeasurementField.frontLength:
        return frontLength;
      case MeasurementField.dressLength:
        return dressLength;
      case MeasurementField.trouserWaist:
        return trouserWaist;
      case MeasurementField.trouserHip:
        return trouserHip;
      case MeasurementField.trouserLength:
        return trouserLength;
      case MeasurementField.inseam:
        return inseam;
      case MeasurementField.thigh:
        return thigh;
      case MeasurementField.neck:
        return neck;
      default:
        return null;
    }
  }

  /// Check if a field has a valid, positive measurement entered
  bool isFieldFilled(String key) {
    final val = getValue(key);
    return val != null && val > 0.0;
  }

  /// Validates whether this profile satisfies all required measurements for a garment
  bool hasAllRequiredFields(List<String> requiredKeys) {
    if (requiredKeys.isEmpty) return true;
    for (final key in requiredKeys) {
      if (!isFieldFilled(key)) return false;
    }
    return true;
  }

  /// Returns list of keys that are missing or <= 0
  List<String> getMissingFields(List<String> requiredKeys) {
    final missing = <String>[];
    for (final key in requiredKeys) {
      if (!isFieldFilled(key)) {
        missing.add(key);
      }
    }
    return missing;
  }

  /// Immutably set a specific field value by key
  MeasurementProfile copyWithField(String key, double? value) {
    switch (key) {
      case MeasurementField.shoulder:
        return copyWith(shoulder: value);
      case MeasurementField.bust:
        return copyWith(bust: value);
      case MeasurementField.underBust:
        return copyWith(underBust: value);
      case MeasurementField.waist:
        return copyWith(waist: value);
      case MeasurementField.hip:
        return copyWith(hip: value);
      case MeasurementField.armhole:
        return copyWith(armhole: value);
      case MeasurementField.sleeveLength:
        return copyWith(sleeveLength: value);
      case MeasurementField.bicep:
        return copyWith(bicep: value);
      case MeasurementField.wrist:
        return copyWith(wrist: value);
      case MeasurementField.backLength:
        return copyWith(backLength: value);
      case MeasurementField.frontLength:
        return copyWith(frontLength: value);
      case MeasurementField.dressLength:
        return copyWith(dressLength: value);
      case MeasurementField.trouserWaist:
        return copyWith(trouserWaist: value);
      case MeasurementField.trouserHip:
        return copyWith(trouserHip: value);
      case MeasurementField.trouserLength:
        return copyWith(trouserLength: value);
      case MeasurementField.inseam:
        return copyWith(inseam: value);
      case MeasurementField.thigh:
        return copyWith(thigh: value);
      case MeasurementField.neck:
        return copyWith(neck: value);
      default:
        return this;
    }
  }

  /// Converts measurements between inches and cm (rounded to 1 decimal place)
  MeasurementProfile convertUnit(String targetUnit) {
    if (targetUnit == unit) return this;
    if (targetUnit != 'inches' && targetUnit != 'cm') return this;

    double? convert(double? v) {
      if (v == null) return null;
      if (targetUnit == 'cm') {
        // inches -> cm (1 in = 2.54 cm)
        return double.parse((v * 2.54).toStringAsFixed(1));
      } else {
        // cm -> inches (1 cm = 0.3937 in)
        return double.parse((v / 2.54).toStringAsFixed(1));
      }
    }

    return MeasurementProfile(
      id: id,
      profileId: profileId,
      name: name,
      shoulder: convert(shoulder),
      bust: convert(bust),
      underBust: convert(underBust),
      waist: convert(waist),
      hip: convert(hip),
      armhole: convert(armhole),
      sleeveLength: convert(sleeveLength),
      bicep: convert(bicep),
      wrist: convert(wrist),
      backLength: convert(backLength),
      frontLength: convert(frontLength),
      dressLength: convert(dressLength),
      trouserWaist: convert(trouserWaist),
      trouserHip: convert(trouserHip),
      trouserLength: convert(trouserLength),
      inseam: convert(inseam),
      thigh: convert(thigh),
      neck: convert(neck),
      unit: targetUnit,
      isDefault: isDefault,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  MeasurementProfile copyWith({
    String? id,
    String? profileId,
    String? name,
    double? shoulder,
    double? bust,
    double? underBust,
    double? waist,
    double? hip,
    double? armhole,
    double? sleeveLength,
    double? bicep,
    double? wrist,
    double? backLength,
    double? frontLength,
    double? dressLength,
    double? trouserWaist,
    double? trouserHip,
    double? trouserLength,
    double? inseam,
    double? thigh,
    double? neck,
    String? unit,
    bool? isDefault,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeasurementProfile(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      shoulder: shoulder ?? this.shoulder,
      bust: bust ?? this.bust,
      underBust: underBust ?? this.underBust,
      waist: waist ?? this.waist,
      hip: hip ?? this.hip,
      armhole: armhole ?? this.armhole,
      sleeveLength: sleeveLength ?? this.sleeveLength,
      bicep: bicep ?? this.bicep,
      wrist: wrist ?? this.wrist,
      backLength: backLength ?? this.backLength,
      frontLength: frontLength ?? this.frontLength,
      dressLength: dressLength ?? this.dressLength,
      trouserWaist: trouserWaist ?? this.trouserWaist,
      trouserHip: trouserHip ?? this.trouserHip,
      trouserLength: trouserLength ?? this.trouserLength,
      inseam: inseam ?? this.inseam,
      thigh: thigh ?? this.thigh,
      neck: neck ?? this.neck,
      unit: unit ?? this.unit,
      isDefault: isDefault ?? this.isDefault,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MeasurementProfile.fromJson(Map<String, dynamic> json) {
    double? parseD(dynamic v) => (v as num?)?.toDouble();

    return MeasurementProfile(
      id: json['id'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      name: json['name'] as String? ?? 'My Measurements',
      shoulder: parseD(json['shoulder']),
      bust: parseD(json['bust']),
      underBust: parseD(json['under_bust']),
      waist: parseD(json['waist']),
      hip: parseD(json['hip']),
      armhole: parseD(json['armhole']),
      sleeveLength: parseD(json['sleeve_length']),
      bicep: parseD(json['bicep']),
      wrist: parseD(json['wrist']),
      backLength: parseD(json['back_length']),
      frontLength: parseD(json['front_length']),
      dressLength: parseD(json['dress_length']),
      trouserWaist: parseD(json['trouser_waist']),
      trouserHip: parseD(json['trouser_hip']),
      trouserLength: parseD(json['trouser_length']),
      inseam: parseD(json['inseam']),
      thigh: parseD(json['thigh']),
      neck: parseD(json['neck']),
      unit: json['unit'] as String? ?? 'inches',
      isDefault: json['is_default'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'profile_id': profileId,
      'name': name,
      'shoulder': shoulder,
      'bust': bust,
      'under_bust': underBust,
      'waist': waist,
      'hip': hip,
      'armhole': armhole,
      'sleeve_length': sleeveLength,
      'bicep': bicep,
      'wrist': wrist,
      'back_length': backLength,
      'front_length': frontLength,
      'dress_length': dressLength,
      'trouser_waist': trouserWaist,
      'trouser_hip': trouserHip,
      'trouser_length': trouserLength,
      'inseam': inseam,
      'thigh': thigh,
      'neck': neck,
      'unit': unit,
      'is_default': isDefault,
      'notes': notes,
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        name,
        shoulder,
        bust,
        underBust,
        waist,
        hip,
        armhole,
        sleeveLength,
        bicep,
        wrist,
        backLength,
        frontLength,
        dressLength,
        trouserWaist,
        trouserHip,
        trouserLength,
        inseam,
        thigh,
        neck,
        unit,
        isDefault,
        notes,
      ];
}
