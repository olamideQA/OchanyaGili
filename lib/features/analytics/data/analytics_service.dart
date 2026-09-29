import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:ochanya_gili/features/analytics/domain/models/analytics_event.dart';

class AnalyticsService {
  final SupabaseClient _client;
  final String sessionId;
  final Map<String, DateTime> _recentEvents = {};
  static const Duration _dedupWindow = Duration(milliseconds: 3000);

  AnalyticsService(this._client) : sessionId = const Uuid().v4();

  /// Determine device type string
  String get _deviceType {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  /// Core tracking method with deduplication guard
  Future<void> trackEvent(
    AnalyticsEventType type, {
    Map<String, dynamic> properties = const {},
    String pageUrl = '',
    String? deduplicationKey,
  }) async {
    final now = DateTime.now();
    final key = deduplicationKey ?? '${type.eventName}:${properties.values.take(3).join('-')}';

    // Deduplication check: ignore if fired within debounce window
    final lastFired = _recentEvents[key];
    if (lastFired != null && now.difference(lastFired) < _dedupWindow) {
      return;
    }
    _recentEvents[key] = now;

    // Prune stale cache entries
    if (_recentEvents.length > 200) {
      _recentEvents.removeWhere((_, time) => now.difference(time) > const Duration(minutes: 5));
    }

    try {
      final currentUserId = _client.auth.currentUser?.id;
      final payload = <String, dynamic>{
        'event_name': type.eventName,
        'profile_id': currentUserId,
        'session_id': sessionId,
        'properties': properties,
        'page_url': pageUrl,
        'device_type': _deviceType,
        'created_at': now.toIso8601String(),
      };

      // Non-blocking fire-and-forget insert
      unawaited(_client.from('analytics_events').insert(payload));
    } catch (_) {
      // Analytics must never break primary UI workflows
    }
  }

  // =========================================================================
  // High-Level Instrumentation API
  // =========================================================================

  void trackPageView(String path, {String? title}) {
    trackEvent(
      AnalyticsEventType.pageView,
      pageUrl: path,
      properties: {'title': title ?? path},
      deduplicationKey: 'page_view:$path',
    );
  }

  void trackProductView({
    required String productId,
    required String name,
    required String slug,
    required double price,
    String? category,
  }) {
    trackEvent(
      AnalyticsEventType.productView,
      pageUrl: '/shop/$slug',
      properties: {
        'product_id': productId,
        'name': name,
        'slug': slug,
        'price': price,
        'category': category,
      },
      deduplicationKey: 'product_view:$productId',
    );
  }

  void trackCollectionView({
    required String collectionId,
    required String name,
    required String slug,
  }) {
    trackEvent(
      AnalyticsEventType.collectionView,
      pageUrl: '/collections/$slug',
      properties: {
        'collection_id': collectionId,
        'name': name,
        'slug': slug,
      },
      deduplicationKey: 'collection_view:$collectionId',
    );
  }

  void trackLookbookView(String slug) {
    trackEvent(
      AnalyticsEventType.lookbookView,
      pageUrl: '/lookbook/$slug',
      properties: {'slug': slug},
      deduplicationKey: 'lookbook_view:$slug',
    );
  }

  void trackAddToCart({
    required String productId,
    required String name,
    required double price,
    String? size,
    String? colour,
    int quantity = 1,
  }) {
    trackEvent(
      AnalyticsEventType.addToCart,
      pageUrl: '/shop',
      properties: {
        'product_id': productId,
        'name': name,
        'price': price,
        'size': size,
        'colour': colour,
        'quantity': quantity,
      },
      deduplicationKey: 'add_to_cart:$productId:${size ?? ''}',
    );
  }

  void trackCheckoutStarted({
    required double total,
    required int itemCount,
  }) {
    trackEvent(
      AnalyticsEventType.checkoutStarted,
      pageUrl: '/checkout',
      properties: {
        'total': total,
        'item_count': itemCount,
      },
      deduplicationKey: 'checkout_started:$sessionId',
    );
  }

  void trackPurchaseCompleted({
    required String orderNumber,
    required double total,
    required int itemCount,
  }) {
    trackEvent(
      AnalyticsEventType.purchaseCompleted,
      pageUrl: '/checkout/confirmation/$orderNumber',
      properties: {
        'order_number': orderNumber,
        'total': total,
        'item_count': itemCount,
      },
      deduplicationKey: 'purchase_completed:$orderNumber',
    );
  }

  void trackCustomRequestStarted({String? garmentType}) {
    trackEvent(
      AnalyticsEventType.customRequestStarted,
      pageUrl: '/create-your-look',
      properties: {'garment_type': garmentType ?? 'Bespoke'},
      deduplicationKey: 'custom_started:$sessionId',
    );
  }

  void trackCustomRequestCompleted({
    required String requestId,
    required String garmentType,
  }) {
    trackEvent(
      AnalyticsEventType.customRequestCompleted,
      pageUrl: '/create-your-look',
      properties: {
        'request_id': requestId,
        'garment_type': garmentType,
      },
      deduplicationKey: 'custom_completed:$requestId',
    );
  }

  void trackAppointmentStarted({String? appointmentTypeId}) {
    trackEvent(
      AnalyticsEventType.appointmentStarted,
      pageUrl: '/appointments/book',
      properties: {'type_id': appointmentTypeId},
      deduplicationKey: 'appointment_started:$sessionId',
    );
  }

  void trackAppointmentCompleted({
    required String appointmentId,
    required String typeName,
  }) {
    trackEvent(
      AnalyticsEventType.appointmentCompleted,
      pageUrl: '/appointments/book',
      properties: {
        'appointment_id': appointmentId,
        'type_name': typeName,
      },
      deduplicationKey: 'appointment_completed:$appointmentId',
    );
  }

  void trackWishlistAdded({
    required String productId,
    required String name,
  }) {
    trackEvent(
      AnalyticsEventType.wishlistAdded,
      pageUrl: '/shop',
      properties: {
        'product_id': productId,
        'name': name,
      },
      deduplicationKey: 'wishlist:$productId',
    );
  }

  void trackSearchQuery(String query, {int resultCount = 0}) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return;

    trackEvent(
      AnalyticsEventType.searchQuery,
      pageUrl: '/shop',
      properties: {
        'query': clean,
        'results_count': resultCount,
      },
      deduplicationKey: 'search:$clean',
    );
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(Supabase.instance.client);
});
