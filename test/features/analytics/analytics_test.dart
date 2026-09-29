import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/features/analytics/domain/models/analytics_event.dart';
import 'package:ochanya_gili/features/analytics/domain/models/analytics_metrics.dart';

void main() {
  group('AnalyticsEventType Tests', () {
    test('verifies all 13 required analytics event types', () {
      expect(AnalyticsEventType.pageView.value, 'page_view');
      expect(AnalyticsEventType.productView.value, 'product_view');
      expect(AnalyticsEventType.collectionView.value, 'collection_view');
      expect(AnalyticsEventType.lookbookView.value, 'lookbook_view');
      expect(AnalyticsEventType.addToCart.value, 'add_to_cart');
      expect(AnalyticsEventType.checkoutStarted.value, 'checkout_started');
      expect(AnalyticsEventType.purchaseCompleted.value, 'purchase_completed');
      expect(AnalyticsEventType.customRequestStarted.value, 'custom_request_started');
      expect(AnalyticsEventType.customRequestCompleted.value, 'custom_request_completed');
      expect(AnalyticsEventType.appointmentStarted.value, 'appointment_started');
      expect(AnalyticsEventType.appointmentCompleted.value, 'appointment_completed');
      expect(AnalyticsEventType.wishlistAdded.value, 'wishlist_added');
      expect(AnalyticsEventType.searchQuery.value, 'search_query');
    });

    test('AnalyticsEventType.fromString converts valid and fallback strings', () {
      expect(AnalyticsEventType.fromString('product_view'), AnalyticsEventType.productView);
      expect(AnalyticsEventType.fromString('purchase_completed'), AnalyticsEventType.purchaseCompleted);
      expect(AnalyticsEventType.fromString('unknown_event'), AnalyticsEventType.pageView);
    });
  });

  group('AnalyticsEvent Model Tests', () {
    test('serializes and deserializes AnalyticsEvent JSON correctly', () {
      final now = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final event = AnalyticsEvent(
        id: 'event-uuid-1',
        eventName: 'product_view',
        profileId: 'user-uuid-123',
        sessionId: 'session-xyz',
        properties: {'product_id': 'prod-1', 'price': 185000.0},
        pageUrl: '/shop/structured-ivory-tuxedo-blazer',
        referrer: 'https://ochanyagili.com/collections',
        deviceType: 'web_desktop',
        createdAt: now,
      );

      final json = event.toJson();
      expect(json['id'], 'event-uuid-1');
      expect(json['event_name'], 'product_view');
      expect(json['profile_id'], 'user-uuid-123');
      expect(json['session_id'], 'session-xyz');
      expect(json['properties']['product_id'], 'prod-1');
      expect(json['page_url'], '/shop/structured-ivory-tuxedo-blazer');
      expect(json['referrer'], 'https://ochanyagili.com/collections');
      expect(json['device_type'], 'web_desktop');
      expect(json['created_at'], now.toIso8601String());

      final restored = AnalyticsEvent.fromJson(json);
      expect(restored.id, event.id);
      expect(restored.eventName, event.eventName);
      expect(restored.profileId, event.profileId);
      expect(restored.properties['product_id'], 'prod-1');
      expect(restored.type, AnalyticsEventType.productView);
    });
  });

  group('AnalyticsFunnelMetrics Conversion & Retention Calculations', () {
    test('computes e-commerce funnel conversion rates accurately', () {
      const metrics = AnalyticsFunnelMetrics(
        totalPageViews: 1000,
        totalProductViews: 200,
        totalCartAdditions: 50,
        checkoutsStarted: 20,
        purchasesCompleted: 10,
        totalRevenue: 2500000.0,
        totalOrders: 10,
      );

      // Cart rate = 50 / 200 = 25%
      expect(metrics.cartConversionRate, 25.0);
      // Checkout to purchase = 10 / 20 = 50%
      expect(metrics.checkoutToPurchaseRate, 50.0);
      expect(metrics.checkoutConversionRate, 50.0);
      // Store conversion rate = 10 / 200 = 5%
      expect(metrics.storeConversionRate, 5.0);
      expect(metrics.conversionRate, 5.0);
    });

    test('computes custom atelier and appointment conversion rates accurately', () {
      const metrics = AnalyticsFunnelMetrics(
        customRequestsStarted: 10,
        customRequestsCompleted: 4,
        appointmentsStarted: 8,
        appointmentsCompleted: 6,
      );

      // Custom conversion = 4 / 10 = 40%
      expect(metrics.customConversionRate, 40.0);
      // Appointment conversion = 6 / 8 = 75%
      expect(metrics.appointmentCompletionRate, 75.0);
      expect(metrics.appointmentConversionRate, 75.0);
    });

    test('handles zero denominator gracefully without division-by-zero errors', () {
      const emptyMetrics = AnalyticsFunnelMetrics();

      expect(emptyMetrics.cartConversionRate, 0.0);
      expect(emptyMetrics.checkoutToPurchaseRate, 0.0);
      expect(emptyMetrics.storeConversionRate, 0.0);
      expect(emptyMetrics.customConversionRate, 0.0);
      expect(emptyMetrics.appointmentCompletionRate, 0.0);
      expect(emptyMetrics.retentionRate, 0.0);
    });

    test('computes patron retention rate correctly', () {
      const metrics = AnalyticsFunnelMetrics(
        totalCustomers: 20,
        repeatCustomers: 6,
        retentionRate: 30.0,
      );

      expect(metrics.totalCustomers, 20);
      expect(metrics.repeatCustomers, 6);
      expect(metrics.retentionRate, 30.0);
    });
  });

  group('Popular Item & Search Metrics Tests', () {
    test('PopularItemMetric instantiates and equates correctly', () {
      const p1 = PopularItemMetric(id: 'prod-1', name: 'Ivory Tuxedo', views: 42);
      const p2 = PopularItemMetric(id: 'prod-1', name: 'Ivory Tuxedo', views: 42);
      const p3 = PopularItemMetric(id: 'prod-2', name: 'Peplum Gown', views: 25);

      expect(p1, equals(p2));
      expect(p1 == p3, isFalse);
    });

    test('SearchMetric instantiates and equates correctly', () {
      const s1 = SearchMetric(query: 'silk blazer', count: 15);
      const s2 = SearchMetric(query: 'silk blazer', count: 15);
      const s3 = SearchMetric(query: 'gown', count: 8);

      expect(s1, equals(s2));
      expect(s1 == s3, isFalse);
    });
  });
}
