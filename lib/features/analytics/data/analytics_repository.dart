import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/features/analytics/domain/models/analytics_metrics.dart';

class AnalyticsRepository {
  final SupabaseClient _client;

  AnalyticsRepository(this._client);

  Future<AnalyticsFunnelMetrics> getFunnelMetrics() async {
    try {
      // 1. Fetch raw event counts from analytics_events
      final eventsRes = await _client
          .from('analytics_events')
          .select('event_name, properties');

      int pageViews = 0;
      int productViews = 0;
      int cartAdditions = 0;
      int checkouts = 0;
      int purchases = 0;
      int customStarted = 0;
      int customCompleted = 0;
      int appointmentsStarted = 0;
      int appointmentsCompleted = 0;

      final Map<String, int> productViewCounts = {};
      final Map<String, String> productNames = {};
      final Map<String, int> collectionViewCounts = {};
      final Map<String, String> collectionNames = {};
      final Map<String, int> searchCounts = {};

      for (final row in (eventsRes as List<dynamic>)) {
        final name = row['event_name'] as String? ?? '';
        final props = (row['properties'] as Map<String, dynamic>?) ?? {};

        switch (name) {
          case 'page_view':
            pageViews++;
            break;
          case 'product_view':
            productViews++;
            final pid = props['product_id'] as String? ?? '';
            final pname = props['name'] as String? ?? 'Couture Piece';
            if (pid.isNotEmpty) {
              productViewCounts[pid] = (productViewCounts[pid] ?? 0) + 1;
              productNames[pid] = pname;
            }
            break;
          case 'collection_view':
            final cid = props['collection_id'] as String? ?? '';
            final cname = props['name'] as String? ?? 'Collection';
            if (cid.isNotEmpty) {
              collectionViewCounts[cid] = (collectionViewCounts[cid] ?? 0) + 1;
              collectionNames[cid] = cname;
            }
            break;
          case 'add_to_cart':
            cartAdditions++;
            break;
          case 'checkout_started':
            checkouts++;
            break;
          case 'purchase_completed':
            purchases++;
            break;
          case 'custom_request_started':
            customStarted++;
            break;
          case 'custom_request_completed':
            customCompleted++;
            break;
          case 'appointment_started':
            appointmentsStarted++;
            break;
          case 'appointment_completed':
            appointmentsCompleted++;
            break;
          case 'search_query':
            final q = (props['query'] as String? ?? '').trim();
            if (q.isNotEmpty) {
              searchCounts[q] = (searchCounts[q] ?? 0) + 1;
            }
            break;
        }
      }

      // 2. Fetch order revenue & order counts
      final ordersRes = await _client
          .from('orders')
          .select('id, total, status, profile_id')
          .neq('status', 'cancelled');

      double totalRevenue = 0.0;
      int totalOrders = 0;
      final Map<String, int> customerOrderCounts = {};

      for (final order in (ordersRes as List<dynamic>)) {
        totalOrders++;
        totalRevenue += (order['total'] as num?)?.toDouble() ?? 0.0;
        final profileId = order['profile_id'] as String?;
        if (profileId != null) {
          customerOrderCounts[profileId] = (customerOrderCounts[profileId] ?? 0) + 1;
        }
      }

      final totalCustomers = customerOrderCounts.length;
      final repeatCustomers = customerOrderCounts.values.where((c) => c > 1).length;
      final retentionRate = totalCustomers == 0 ? 0.0 : (repeatCustomers / totalCustomers) * 100;

      // 3. Build top popular products list
      final popularProducts = productViewCounts.entries.map((e) {
        return PopularItemMetric(
          id: e.key,
          name: productNames[e.key] ?? e.key,
          views: e.value,
        );
      }).toList()
        ..sort((a, b) => b.views.compareTo(a.views));

      // 4. Build top popular collections list
      final popularCollections = collectionViewCounts.entries.map((e) {
        return PopularItemMetric(
          id: e.key,
          name: collectionNames[e.key] ?? e.key,
          views: e.value,
        );
      }).toList()
        ..sort((a, b) => b.views.compareTo(a.views));

      // 5. Build top searches
      final topSearches = searchCounts.entries.map((e) {
        return SearchMetric(query: e.key, count: e.value);
      }).toList()
        ..sort((a, b) => b.count.compareTo(a.count));

      return AnalyticsFunnelMetrics(
        totalPageViews: pageViews,
        totalProductViews: productViews,
        totalCartAdditions: cartAdditions,
        checkoutsStarted: checkouts,
        purchasesCompleted: purchases,
        totalRevenue: totalRevenue,
        totalOrders: totalOrders,
        customRequestsStarted: customStarted,
        customRequestsCompleted: customCompleted,
        appointmentsStarted: appointmentsStarted,
        appointmentsCompleted: appointmentsCompleted,
        totalCustomers: totalCustomers,
        repeatCustomers: repeatCustomers,
        retentionRate: retentionRate,
        popularProducts: popularProducts.take(5).toList(),
        popularCollections: popularCollections.take(5).toList(),
        topSearches: topSearches.take(5).toList(),
      );
    } catch (_) {
      // Fallback baseline for clean dashboard rendering
      return const AnalyticsFunnelMetrics();
    }
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(Supabase.instance.client);
});

final analyticsMetricsProvider = FutureProvider<AnalyticsFunnelMetrics>((ref) {
  return ref.watch(analyticsRepositoryProvider).getFunnelMetrics();
});
