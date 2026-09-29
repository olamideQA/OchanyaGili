import 'package:ochanya_gili/features/orders/domain/models/order.dart';
import 'package:ochanya_gili/features/custom_atelier/domain/models/custom_request.dart';
import 'package:ochanya_gili/features/appointments/domain/models/appointment.dart';
import 'package:ochanya_gili/features/shop/domain/models/product.dart';

/// Customer saved delivery address
class CustomerAddress {
  final String id;
  final String profileId;
  final String label; // e.g. "Home", "Office", "Atelier Delivery"
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String country;
  final String? postalCode;
  final String? instructions;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerAddress({
    this.id = '',
    required this.profileId,
    this.label = 'Home',
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    this.country = 'Nigeria',
    this.postalCode,
    this.instructions,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  String get formattedAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2!,
      city,
      state,
      country,
    ];
    return parts.join(', ');
  }

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      label: json['label'] as String? ?? 'Home',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      addressLine1: json['address_line1'] as String? ?? '',
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? 'Nigeria',
      postalCode: json['postal_code'] as String?,
      instructions: json['instructions'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) => {
        if (includeId && id.isNotEmpty) 'id': id,
        'profile_id': profileId,
        'label': label,
        'full_name': fullName,
        'phone': phone,
        'address_line1': addressLine1,
        if (addressLine2 != null) 'address_line2': addressLine2,
        'city': city,
        'state': state,
        'country': country,
        if (postalCode != null) 'postal_code': postalCode,
        if (instructions != null) 'instructions': instructions,
        'is_default': isDefault,
      };
}

/// Customer in-app notification
class CustomerNotification {
  final String id;
  final String profileId;
  final String title;
  final String body;
  final String type; // 'order', 'custom_request', 'appointment', 'payment', 'system'
  final String? referenceType;
  final String? referenceId;
  final bool isRead;
  final String channel;
  final DateTime createdAt;

  const CustomerNotification({
    this.id = '',
    required this.profileId,
    required this.title,
    required this.body,
    this.type = 'system',
    this.referenceType,
    this.referenceId,
    this.isRead = false,
    this.channel = 'in_app',
    required this.createdAt,
  });

  factory CustomerNotification.fromJson(Map<String, dynamic> json) {
    return CustomerNotification(
      id: json['id'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      channel: json['channel'] as String? ?? 'in_app',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Wishlist saved look item
class WishlistItem {
  final String id;
  final String profileId;
  final String productId;
  final DateTime createdAt;
  final Product? product;

  const WishlistItem({
    this.id = '',
    required this.profileId,
    required this.productId,
    required this.createdAt,
    this.product,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      product: json['products'] != null
          ? Product.fromJson(json['products'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Aggregated Customer Dashboard Overview data
class CustomerDashboardOverview {
  final int totalOrders;
  final int activeOrdersCount;
  final AppOrder? latestOrder;

  final int customRequestsCount;
  final CustomRequest? latestCustomRequest;

  final int upcomingAppointmentsCount;
  final Appointment? nextAppointment;

  final int savedLooksCount;
  final int savedMeasurementsCount;
  final int unreadNotificationsCount;

  const CustomerDashboardOverview({
    this.totalOrders = 0,
    this.activeOrdersCount = 0,
    this.latestOrder,
    this.customRequestsCount = 0,
    this.latestCustomRequest,
    this.upcomingAppointmentsCount = 0,
    this.nextAppointment,
    this.savedLooksCount = 0,
    this.savedMeasurementsCount = 0,
    this.unreadNotificationsCount = 0,
  });
}
