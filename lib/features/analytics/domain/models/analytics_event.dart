import 'package:equatable/equatable.dart';

enum AnalyticsEventType {
  pageView('page_view'),
  productView('product_view'),
  collectionView('collection_view'),
  lookbookView('lookbook_view'),
  addToCart('add_to_cart'),
  checkoutStarted('checkout_started'),
  purchaseCompleted('purchase_completed'),
  customRequestStarted('custom_request_started'),
  customRequestCompleted('custom_request_completed'),
  appointmentStarted('appointment_started'),
  appointmentCompleted('appointment_completed'),
  wishlistAdded('wishlist_added'),
  searchQuery('search_query');

  final String eventName;
  const AnalyticsEventType(this.eventName);

  String get value => eventName;

  static AnalyticsEventType fromString(String name) {
    for (final type in AnalyticsEventType.values) {
      if (type.eventName == name) return type;
    }
    return AnalyticsEventType.pageView;
  }
}

class AnalyticsEvent extends Equatable {
  final String id;
  final String eventName;
  final String? profileId;
  final String sessionId;
  final Map<String, dynamic> properties;
  final String pageUrl;
  final String? referrer;
  final String deviceType;
  final DateTime createdAt;

  const AnalyticsEvent({
    required this.id,
    required this.eventName,
    this.profileId,
    required this.sessionId,
    this.properties = const {},
    required this.pageUrl,
    this.referrer,
    this.deviceType = 'desktop',
    required this.createdAt,
  });

  AnalyticsEventType get type => AnalyticsEventType.fromString(eventName);

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      id: json['id'] as String? ?? '',
      eventName: json['event_name'] as String? ?? 'page_view',
      profileId: json['profile_id'] as String?,
      sessionId: json['session_id'] as String? ?? '',
      properties: (json['properties'] as Map<String, dynamic>?) ?? {},
      pageUrl: json['page_url'] as String? ?? '',
      referrer: json['referrer'] as String?,
      deviceType: json['device_type'] as String? ?? 'desktop',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'event_name': eventName,
      'profile_id': profileId,
      'session_id': sessionId,
      'properties': properties,
      'page_url': pageUrl,
      'referrer': referrer,
      'device_type': deviceType,
      'created_at': createdAt.toIso8601String(),
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  @override
  List<Object?> get props => [
        id,
        eventName,
        profileId,
        sessionId,
        properties,
        pageUrl,
        referrer,
        deviceType,
        createdAt,
      ];
}
