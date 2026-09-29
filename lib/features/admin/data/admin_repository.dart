import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/features/admin/domain/models/admin_dashboard_models.dart';
import 'package:ochanya_gili/features/journal/domain/models/journal_post.dart';

class AdminRepository {
  final SupabaseClient _client;

  AdminRepository(this._client);

  /// Aggregates live master metrics for the /admin dashboard
  Future<AdminDashboardMetrics> getDashboardMetrics() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final todayDateString =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      // 1. Today's orders & revenue
      final todayOrdersRes = await _client
          .from('orders')
          .select('id, total, payment_status')
          .gte('created_at', todayStart);

      final todayOrdersList = todayOrdersRes as List<dynamic>;
      final todayOrders = todayOrdersList.length;
      double todayRevenue = 0.0;
      for (final o in todayOrdersList) {
        final pStatus = o['payment_status'] as String? ?? 'pending';
        if (pStatus != 'failed' && pStatus != 'refunded') {
          todayRevenue += ((o['total'] as num?)?.toDouble() ?? 0.0);
        }
      }

      // 2. Today's appointments
      final todayApptsRes = await _client
          .from('appointments')
          .select('id')
          .eq('scheduled_date', todayDateString);
      final todayAppointments = (todayApptsRes as List<dynamic>).length;

      // 3. Today's custom requests
      final todayReqsRes = await _client
          .from('custom_requests')
          .select('id')
          .gte('created_at', todayStart);
      final todayCustomRequests = (todayReqsRes as List<dynamic>).length;

      // 4. Production Pipeline Funnel counts
      // Requests (submitted, under_review)
      final reqsCountRes = await _client
          .from('custom_requests')
          .select('id')
          .inFilter('status', ['submitted', 'under_review']);
      final pipelineRequests = (reqsCountRes as List<dynamic>).length;

      // Quoted (quote_sent, accepted)
      final quotedCountRes = await _client
          .from('custom_requests')
          .select('id')
          .inFilter('status', ['quote_sent', 'accepted']);
      final pipelineQuoted = (quotedCountRes as List<dynamic>).length;

      // Production (in_production on orders + custom_requests)
      final prodOrdersRes = await _client
          .from('orders')
          .select('id')
          .eq('status', 'in_production');
      final prodReqsRes = await _client
          .from('custom_requests')
          .select('id')
          .eq('status', 'in_production');
      final pipelineProduction =
          (prodOrdersRes as List<dynamic>).length + (prodReqsRes as List<dynamic>).length;

      // Fitting (ready_for_fitting on orders + confirmed fitting appts)
      final fittingOrdersRes = await _client
          .from('orders')
          .select('id')
          .eq('status', 'ready_for_fitting');
      final fittingApptsRes = await _client
          .from('appointments')
          .select('id')
          .eq('status', 'confirmed');
      final pipelineFitting =
          (fittingOrdersRes as List<dynamic>).length + (fittingApptsRes as List<dynamic>).length;

      // Ready (ready_for_delivery, delivered, completed)
      final readyOrdersRes = await _client
          .from('orders')
          .select('id')
          .inFilter('status', ['ready_for_delivery', 'delivered']);
      final pipelineReady = (readyOrdersRes as List<dynamic>).length;

      // 5. Recent Orders (last 5)
      final recentOrdersRaw = await _client
          .from('orders')
          .select('id, order_number, total, status, payment_status, created_at, profiles(full_name)')
          .order('created_at', ascending: false)
          .limit(5);
      final recentOrders = (recentOrdersRaw as List<dynamic>)
          .map((e) => AdminOrderSummary.fromJson(e as Map<String, dynamic>))
          .toList();

      // 6. Recent Custom Requests (last 5)
      final recentReqsRaw = await _client
          .from('custom_requests')
          .select('id, request_number, garment_type, status, created_at, profiles(full_name)')
          .order('created_at', ascending: false)
          .limit(5);
      final recentRequests = (recentReqsRaw as List<dynamic>)
          .map((e) => AdminRequestSummary.fromJson(e as Map<String, dynamic>))
          .toList();

      // 7. Upcoming Appointments (next 5)
      final upcomingApptsRaw = await _client
          .from('appointments')
          .select(
              'id, scheduled_date, start_time, status, profiles(full_name), appointment_types(name)')
          .gte('scheduled_date', todayDateString)
          .order('scheduled_date', ascending: true)
          .order('start_time', ascending: true)
          .limit(5);
      final upcomingAppointments = (upcomingApptsRaw as List<dynamic>)
          .map((e) => AdminAppointmentSummary.fromJson(e as Map<String, dynamic>))
          .toList();

      return AdminDashboardMetrics(
        todayOrders: todayOrders,
        todayRevenue: todayRevenue,
        todayAppointments: todayAppointments,
        todayCustomRequests: todayCustomRequests,
        pipelineRequests: pipelineRequests,
        pipelineQuoted: pipelineQuoted,
        pipelineProduction: pipelineProduction,
        pipelineFitting: pipelineFitting,
        pipelineReady: pipelineReady,
        recentOrders: recentOrders,
        recentRequests: recentRequests,
        upcomingAppointments: upcomingAppointments,
      );
    } catch (e) {
      // Return empty with fallback if database query encountered error
      return AdminDashboardMetrics.empty();
    }
  }

  /// Fetch customers directory
  Future<List<AdminCustomer>> getCustomers({String? searchQuery}) async {
    var query = _client.from('profiles').select();
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('full_name.ilike.%$q%,email.ilike.%$q%,phone.ilike.%$q%');
    }

    final data = await query.order('created_at', ascending: false).limit(100);
    final profiles = data as List<dynamic>;

    // Enrich with order and measurement counts
    final List<AdminCustomer> customers = [];
    for (final p in profiles) {
      final pMap = Map<String, dynamic>.from(p as Map<String, dynamic>);
      final pid = pMap['id'] as String;

      // Count orders
      try {
        final ordersRes = await _client.from('orders').select('id').eq('profile_id', pid);
        pMap['orders_count'] = (ordersRes as List<dynamic>).length;
      } catch (_) {
        pMap['orders_count'] = 0;
      }

      // Count measurement profiles
      try {
        final measRes =
            await _client.from('measurement_profiles').select('id').eq('profile_id', pid);
        pMap['measurements_count'] = (measRes as List<dynamic>).length;
      } catch (_) {
        pMap['measurements_count'] = 0;
      }

      customers.add(AdminCustomer.fromJson(pMap));
    }

    return customers;
  }

  /// Get inventory items
  Future<List<InventoryItem>> getInventory({String? searchQuery}) async {
    var query = _client.from('inventory').select();
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('name.ilike.%$q%,sku.ilike.%$q%,supplier.ilike.%$q%');
    }
    final data = await query.order('name', ascending: true);
    return (data as List<dynamic>)
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Adjust stock level and record in inventory_transactions
  Future<void> adjustStock({
    required String inventoryId,
    required double newQuantity,
    required String reason,
    required String performedBy,
  }) async {
    // 1. Update inventory table
    await _client.from('inventory').update({
      'quantity': newQuantity,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', inventoryId);

    // 2. Insert audit log in inventory_transactions
    await _client.from('inventory_transactions').insert({
      'inventory_id': inventoryId,
      'type': 'adjustment',
      'quantity': newQuantity,
      'notes': reason,
      'performed_by': performedBy,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Create new inventory item
  Future<InventoryItem> createInventoryItem({
    required String name,
    required String sku,
    String? description,
    required double quantity,
    required String unit,
    required double costPerUnit,
    String? supplier,
    required double reorderThreshold,
  }) async {
    final res = await _client.from('inventory').insert({
      'name': name.trim(),
      'sku': sku.trim().toUpperCase(),
      'description': description,
      'quantity': quantity,
      'unit': unit.trim(),
      'cost_per_unit': costPerUnit,
      'supplier': supplier,
      'reorder_threshold': reorderThreshold,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).select().single();

    return InventoryItem.fromJson(res);
  }

  /// Fetch payments audit log
  Future<List<AdminPaymentRecord>> getPayments({String? statusFilter}) async {
    var query = _client.from('payments').select('*, profiles(full_name, email)');
    if (statusFilter != null && statusFilter != 'all') {
      query = query.eq('status', statusFilter);
    }
    final data = await query.order('created_at', ascending: false).limit(100);
    return (data as List<dynamic>)
        .map((e) => AdminPaymentRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Record or log a manual / offline payment
  Future<void> recordPayment({
    required String profileId,
    String? orderId,
    required double amount,
    required String currency,
    required String provider,
    String? providerReference,
    required String status,
    required String paymentType,
  }) async {
    await _client.from('payments').insert({
      'profile_id': profileId,
      'order_id': orderId,
      'amount': amount,
      'currency': currency,
      'provider': provider,
      'provider_reference': providerReference,
      'status': status,
      'payment_type': paymentType,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fetch all discount codes
  Future<List<AdminDiscount>> getDiscounts() async {
    final data = await _client.from('discounts').select().order('created_at', ascending: false);
    return (data as List<dynamic>)
        .map((e) => AdminDiscount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a discount voucher
  Future<AdminDiscount> createDiscount(AdminDiscount discount) async {
    final res = await _client.from('discounts').insert(discount.toJson()).select().single();
    return AdminDiscount.fromJson(res);
  }

  /// Toggle discount active status
  Future<void> toggleDiscountActive(String discountId, bool isActive) async {
    await _client.from('discounts').update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', discountId);
  }

  /// Fetch designer notes for an entity
  /// NOTE: Only accessible to 'admin' and 'designer' via server-side RLS
  Future<List<DesignerNote>> getDesignerNotes({
    required String entityType,
    required String entityId,
  }) async {
    final data = await _client
        .from('designer_notes')
        .select('*, profiles(full_name)')
        .eq('entity_type', entityType)
        .eq('entity_id', entityId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((e) => DesignerNote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Add a private designer note
  Future<DesignerNote> addDesignerNote({
    required String entityType,
    required String entityId,
    required String content,
    required String createdBy,
  }) async {
    final res = await _client.from('designer_notes').insert({
      'entity_type': entityType,
      'entity_id': entityId,
      'content': content.trim(),
      'created_by': createdBy,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).select('*, profiles(full_name)').single();

    return DesignerNote.fromJson(res);
  }

  /// Delete a designer note
  Future<void> deleteDesignerNote(String noteId) async {
    await _client.from('designer_notes').delete().eq('id', noteId);
  }

  /// Fetch journal posts for management
  Future<List<JournalPost>> getJournalPosts() async {
    final data = await _client.from('journal_posts').select().order('created_at', ascending: false);
    return (data as List<dynamic>)
        .map((e) => JournalPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Toggle journal post publish status
  Future<void> toggleJournalPublish(String postId, bool isPublished) async {
    await _client.from('journal_posts').update({
      'is_published': isPublished,
      'published_at': isPublished ? DateTime.now().toIso8601String() : null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', postId);
  }

  /// Create a new journal article
  Future<JournalPost> createJournalPost(JournalPost post) async {
    final json = post.toJson();
    json.remove('id');
    final res = await _client.from('journal_posts').insert(json).select().single();
    return JournalPost.fromJson(res);
  }

  /// List storage bucket assets for media manager
  Future<List<AdminMediaItem>> getMediaItems() async {
    try {
      final files = await _client.storage.from('products').list();
      return files.map((f) {
        final url = _client.storage.from('products').getPublicUrl(f.name);
        return AdminMediaItem(
          name: f.name,
          bucket: 'products',
          url: url,
          createdAt: f.createdAt != null ? DateTime.tryParse(f.createdAt!) : null,
          size: f.metadata?['size'] as int?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(Supabase.instance.client);
});

final adminDashboardMetricsProvider = FutureProvider<AdminDashboardMetrics>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getDashboardMetrics();
});

final adminCustomersProvider =
    FutureProvider.family<List<AdminCustomer>, String?>((ref, search) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getCustomers(searchQuery: search);
});

final adminInventoryProvider =
    FutureProvider.family<List<InventoryItem>, String?>((ref, search) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getInventory(searchQuery: search);
});

final adminPaymentsProvider =
    FutureProvider.family<List<AdminPaymentRecord>, String?>((ref, filter) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getPayments(statusFilter: filter);
});

final adminDiscountsProvider = FutureProvider<List<AdminDiscount>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getDiscounts();
});

final adminJournalPostsProvider = FutureProvider<List<JournalPost>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getJournalPosts();
});

final adminMediaProvider = FutureProvider<List<AdminMediaItem>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getMediaItems();
});
