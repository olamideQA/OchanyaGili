import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/features/account/domain/models/customer_account_models.dart';
import 'package:ochanya_gili/features/orders/domain/models/order.dart';
import 'package:ochanya_gili/features/custom_atelier/domain/models/custom_request.dart';
import 'package:ochanya_gili/features/appointments/domain/models/appointment.dart';

class CustomerAccountRepository {
  final SupabaseClient _client;

  CustomerAccountRepository(this._client);

  /// Fetch aggregated dashboard overview for customer
  Future<CustomerDashboardOverview> getDashboardOverview(
      String profileId) async {
    // 1. Orders
    final ordersData = await _client
        .from('orders')
        .select('*, order_items(*, products(*))')
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);

    final ordersList = (ordersData as List<dynamic>)
        .map((json) => AppOrder.fromJson(json as Map<String, dynamic>))
        .toList();

    final activeOrders =
        ordersList.where((o) => o.status.isActive).toList();
    final latestOrder = ordersList.isNotEmpty ? ordersList.first : null;

    // 2. Custom Requests
    final requestsData = await _client
        .from('custom_requests')
        .select('*, custom_request_images(*)')
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);

    final requestsList = (requestsData as List<dynamic>)
        .map((json) => CustomRequest.fromJson(json as Map<String, dynamic>))
        .toList();
    final latestRequest =
        requestsList.isNotEmpty ? requestsList.first : null;

    // 3. Appointments
    final apptsData = await _client
        .from('appointments')
        .select('*, appointment_types(*)')
        .eq('profile_id', profileId)
        .neq('status', 'cancelled')
        .order('scheduled_date', ascending: true)
        .order('start_time', ascending: true);

    final apptsList = (apptsData as List<dynamic>)
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();

    final upcoming = apptsList.where((a) => a.isUpcoming).toList();
    final nextAppt = upcoming.isNotEmpty ? upcoming.first : null;

    // 4. Wishlist count
    final wishlistData = await _client
        .from('wishlist')
        .select('id')
        .eq('profile_id', profileId);
    final wishlistCount = (wishlistData as List<dynamic>).length;

    // 5. Measurements count
    final measurementsData = await _client
        .from('measurement_profiles')
        .select('id')
        .eq('profile_id', profileId);
    final measurementsCount = (measurementsData as List<dynamic>).length;

    // 6. Unread notifications count
    final notifsData = await _client
        .from('notifications')
        .select('id')
        .eq('profile_id', profileId)
        .eq('is_read', false);
    final unreadNotifs = (notifsData as List<dynamic>).length;

    return CustomerDashboardOverview(
      totalOrders: ordersList.length,
      activeOrdersCount: activeOrders.length,
      latestOrder: latestOrder,
      customRequestsCount: requestsList.length,
      latestCustomRequest: latestRequest,
      upcomingAppointmentsCount: upcoming.length,
      nextAppointment: nextAppt,
      savedLooksCount: wishlistCount,
      savedMeasurementsCount: measurementsCount,
      unreadNotificationsCount: unreadNotifs,
    );
  }

  // ==========================================
  // Addresses
  // ==========================================

  Future<List<CustomerAddress>> getAddresses(String profileId) async {
    final data = await _client
        .from('addresses')
        .select()
        .eq('profile_id', profileId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((json) => CustomerAddress.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CustomerAddress> saveAddress(CustomerAddress address) async {
    if (address.isDefault) {
      // Clear previous default
      await _client
          .from('addresses')
          .update({'is_default': false})
          .eq('profile_id', address.profileId);
    }

    if (address.id.isNotEmpty) {
      final res = await _client
          .from('addresses')
          .update(address.toJson(includeId: false))
          .eq('id', address.id)
          .select()
          .single();
      return CustomerAddress.fromJson(res);
    } else {
      final res = await _client
          .from('addresses')
          .insert(address.toJson(includeId: false))
          .select()
          .single();
      return CustomerAddress.fromJson(res);
    }
  }

  Future<void> setDefaultAddress(String profileId, String addressId) async {
    await _client
        .from('addresses')
        .update({'is_default': false})
        .eq('profile_id', profileId);

    await _client
        .from('addresses')
        .update({'is_default': true})
        .eq('id', addressId);
  }

  Future<void> deleteAddress(String addressId) async {
    await _client.from('addresses').delete().eq('id', addressId);
  }

  // ==========================================
  // Wishlist
  // ==========================================

  Future<List<WishlistItem>> getWishlist(String profileId) async {
    final data = await _client
        .from('wishlist')
        .select('*, products(*, product_images(*))')
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((json) => WishlistItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> addToWishlist(String profileId, String productId) async {
    await _client.from('wishlist').upsert({
      'profile_id': profileId,
      'product_id': productId,
    }, onConflict: 'profile_id,product_id');
  }

  Future<void> removeFromWishlist(String profileId, String productId) async {
    await _client
        .from('wishlist')
        .delete()
        .eq('profile_id', profileId)
        .eq('product_id', productId);
  }

  Future<bool> isInWishlist(String profileId, String productId) async {
    final data = await _client
        .from('wishlist')
        .select('id')
        .eq('profile_id', profileId)
        .eq('product_id', productId);

    return (data as List<dynamic>).isNotEmpty;
  }

  // ==========================================
  // Notifications
  // ==========================================

  Future<List<CustomerNotification>> getNotifications(String profileId) async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((json) =>
            CustomerNotification.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllNotificationsRead(String profileId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('profile_id', profileId)
        .eq('is_read', false);
  }

  // ==========================================
  // Profile Update
  // ==========================================

  Future<void> updateProfile({
    required String profileId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _client.from('profiles').update(updates).eq('id', profileId);
  }
}

// Riverpod Providers
final customerAccountRepositoryProvider =
    Provider<CustomerAccountRepository>((ref) {
  return CustomerAccountRepository(Supabase.instance.client);
});

final customerDashboardOverviewProvider =
    FutureProvider.family<CustomerDashboardOverview, String>((ref, profileId) async {
  final repo = ref.watch(customerAccountRepositoryProvider);
  return repo.getDashboardOverview(profileId);
});

final customerAddressesProvider =
    FutureProvider.family<List<CustomerAddress>, String>((ref, profileId) async {
  final repo = ref.watch(customerAccountRepositoryProvider);
  return repo.getAddresses(profileId);
});

final customerWishlistProvider =
    FutureProvider.family<List<WishlistItem>, String>((ref, profileId) async {
  final repo = ref.watch(customerAccountRepositoryProvider);
  return repo.getWishlist(profileId);
});

final customerNotificationsProvider =
    FutureProvider.family<List<CustomerNotification>, String>((ref, profileId) async {
  final repo = ref.watch(customerAccountRepositoryProvider);
  return repo.getNotifications(profileId);
});
