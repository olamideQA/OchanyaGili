import 'package:equatable/equatable.dart';
import 'package:ochanya_gili/features/measurements/domain/models/measurement_profile.dart';

enum CustomRequestStatus {
  requested('Requested'),
  underReview('Under Review'),
  designDiscussion('Design Consultation'),
  quoteSent('Quote Sent'),
  customerApproved('Customer Approved'),
  payment('Payment Settled'),
  production('Atelier Production'),
  fitting('Salon Fitting'),
  alteration('Precision Alteration'),
  ready('Ready for Dispatch'),
  delivered('Delivered / Collected');

  final String displayName;
  const CustomRequestStatus(this.displayName);

  static CustomRequestStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'under_review':
        return CustomRequestStatus.underReview;
      case 'design_discussion':
        return CustomRequestStatus.designDiscussion;
      case 'quote_sent':
        return CustomRequestStatus.quoteSent;
      case 'customer_approved':
        return CustomRequestStatus.customerApproved;
      case 'payment':
        return CustomRequestStatus.payment;
      case 'production':
        return CustomRequestStatus.production;
      case 'fitting':
        return CustomRequestStatus.fitting;
      case 'alteration':
        return CustomRequestStatus.alteration;
      case 'ready':
        return CustomRequestStatus.ready;
      case 'delivered':
        return CustomRequestStatus.delivered;
      case 'requested':
      default:
        return CustomRequestStatus.requested;
    }
  }

  String toJson() {
    switch (this) {
      case CustomRequestStatus.underReview:
        return 'under_review';
      case CustomRequestStatus.designDiscussion:
        return 'design_discussion';
      case CustomRequestStatus.quoteSent:
        return 'quote_sent';
      case CustomRequestStatus.customerApproved:
        return 'customer_approved';
      case CustomRequestStatus.payment:
        return 'payment';
      case CustomRequestStatus.production:
        return 'production';
      case CustomRequestStatus.fitting:
        return 'fitting';
      case CustomRequestStatus.alteration:
        return 'alteration';
      case CustomRequestStatus.ready:
        return 'ready';
      case CustomRequestStatus.delivered:
        return 'delivered';
      case CustomRequestStatus.requested:
        return 'requested';
    }
  }
}

class CustomRequestImage extends Equatable {
  final String id;
  final String customRequestId;
  final String imageUrl;
  final String? altText;
  final int sortOrder;

  const CustomRequestImage({
    required this.id,
    required this.customRequestId,
    required this.imageUrl,
    this.altText,
    this.sortOrder = 0,
  });

  factory CustomRequestImage.fromJson(Map<String, dynamic> json) {
    return CustomRequestImage(
      id: json['id'] as String? ?? '',
      customRequestId: json['custom_request_id'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      altText: json['alt_text'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'custom_request_id': customRequestId,
      'image_url': imageUrl,
      'alt_text': altText,
      'sort_order': sortOrder,
    };
  }

  @override
  List<Object?> get props => [id, customRequestId, imageUrl, altText, sortOrder];
}

class CustomRequest extends Equatable {
  final String id;
  final String requestNumber;
  final String profileId;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String occasion;
  final String direction;
  final String? inspirationText;
  final List<String> inspirationLinks;
  final String fabric;
  final String colour;
  final String? measurementProfileId;
  final String? measurementProfileName;
  final MeasurementProfile? measurementProfile;
  final String? specialInstructions;
  final CustomRequestStatus status;
  final String? assignedTo;
  final String? designerNotes;
  final List<CustomRequestImage> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomRequest({
    required this.id,
    required this.requestNumber,
    required this.profileId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.occasion,
    required this.direction,
    this.inspirationText,
    this.inspirationLinks = const [],
    required this.fabric,
    required this.colour,
    this.measurementProfileId,
    this.measurementProfileName,
    this.measurementProfile,
    this.specialInstructions,
    this.status = CustomRequestStatus.requested,
    this.assignedTo,
    this.designerNotes,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory CustomRequest.fromJson(Map<String, dynamic> json) {
    final rawImages = json['custom_request_images'] as List<dynamic>? ?? [];
    final images = rawImages
        .map((e) => CustomRequestImage.fromJson(e as Map<String, dynamic>))
        .toList();

    final profileData = json['measurement_profiles'] as Map<String, dynamic>?;
    final customerData = json['profiles'] as Map<String, dynamic>?;

    final rawLinks = json['inspiration_links'] as List<dynamic>? ?? [];

    return CustomRequest(
      id: json['id'] as String? ?? '',
      requestNumber: json['request_number'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      customerName: customerData?['full_name'] as String?,
      customerEmail: customerData?['email'] as String?,
      customerPhone: customerData?['phone'] as String?,
      occasion: json['occasion'] as String? ?? '',
      direction: json['direction'] as String? ?? '',
      inspirationText: json['inspiration_text'] as String?,
      inspirationLinks: rawLinks.map((e) => e.toString()).toList(),
      fabric: json['fabric'] as String? ?? '',
      colour: json['colour'] as String? ?? '',
      measurementProfileId: json['measurement_profile_id'] as String?,
      measurementProfileName: profileData?['name'] as String?,
      measurementProfile: profileData != null ? MeasurementProfile.fromJson(profileData) : null,
      specialInstructions: json['special_instructions'] as String?,
      status: CustomRequestStatus.fromString(json['status'] as String? ?? 'requested'),
      assignedTo: json['assigned_to'] as String?,
      designerNotes: json['designer_notes'] as String?,
      images: images,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_number': requestNumber,
      'profile_id': profileId,
      'occasion': occasion,
      'direction': direction,
      'inspiration_text': inspirationText,
      'inspiration_links': inspirationLinks,
      'fabric': fabric,
      'colour': colour,
      'measurement_profile_id': measurementProfileId,
      'special_instructions': specialInstructions,
      'status': status.toJson(),
      'assigned_to': assignedTo,
      'designer_notes': designerNotes,
    };
  }

  @override
  List<Object?> get props => [
        id,
        requestNumber,
        profileId,
        occasion,
        direction,
        inspirationText,
        inspirationLinks,
        fabric,
        colour,
        measurementProfileId,
        specialInstructions,
        status,
        assignedTo,
        images,
      ];
}
