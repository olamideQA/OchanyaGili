import 'package:equatable/equatable.dart';

class DeliveryAddress extends Equatable {
  final String? id;
  final String? profileId;
  final String label;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String? postalCode;
  final String country;
  final bool isDefault;

  const DeliveryAddress({
    this.id,
    this.profileId,
    this.label = 'Default Address',
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    this.postalCode,
    this.country = 'Nigeria',
    this.isDefault = false,
  });

  String get formattedAddress {
    final buffer = StringBuffer(addressLine1);
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      buffer.write(', $addressLine2');
    }
    buffer.write(', $city, $state');
    if (postalCode != null && postalCode!.isNotEmpty) {
      buffer.write(' $postalCode');
    }
    buffer.write(', $country');
    return buffer.toString();
  }

  DeliveryAddress copyWith({
    String? id,
    String? profileId,
    String? label,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    bool? isDefault,
  }) {
    return DeliveryAddress(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      label: label ?? this.label,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      'label': label,
      'full_name': fullName,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault,
    };
  }

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['id'] as String?,
      profileId: json['profile_id'] as String?,
      label: json['label'] as String? ?? 'Default Address',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      addressLine1: json['address_line1'] as String? ?? '',
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String? ?? 'Nigeria',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        label,
        fullName,
        phone,
        addressLine1,
        addressLine2,
        city,
        state,
        postalCode,
        country,
        isDefault,
      ];
}
