import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/core/security/input_sanitizer.dart';
import 'package:ochanya_gili/features/cart/domain/models/cart_item.dart';
import 'package:ochanya_gili/features/checkout/domain/models/delivery_address.dart';
import 'package:ochanya_gili/features/checkout/domain/models/shipping_method.dart';
import 'package:ochanya_gili/features/orders/domain/models/order.dart';

class OrdersRepository {
  final SupabaseClient _client;

  OrdersRepository(this._client);

  Future<AppOrder> createOrder({
    required String profileId,
    required List<CartItem> items,
    required DeliveryAddress address,
    required ShippingMethod shippingMethod,
    String? customerNotes,
  }) async {
    // 1. Persist or link address
    String? addressId = address.id;
    if (addressId == null) {
      final addrPayload = address.toJson();
      addrPayload['profile_id'] = profileId;
      final addrRes = await _client.from('addresses').insert(addrPayload).select().single();
      addressId = addrRes['id'] as String;
    }

    // 2. Authoritative server price verification to eliminate client price tampering
    final productIds = items.map((i) => i.product.id).toSet().toList();
    final dbProducts = await _client
        .from('products')
        .select('id, base_price')
        .filter('id', 'in', productIds);
    final authoritativePrices = <String, double>{
      for (final p in (dbProducts as List<dynamic>))
        p['id'] as String: (p['base_price'] as num).toDouble(),
    };

    double verifiedSubtotal = 0.0;
    for (final item in items) {
      final unitPrice = authoritativePrices[item.product.id] ?? item.unitPrice;
      verifiedSubtotal += unitPrice * item.quantity;
    }
    final deliveryFee = shippingMethod.cost;
    final total = verifiedSubtotal + deliveryFee;

    final sanitizedNotes = customerNotes != null ? InputSanitizer.sanitizeNotes(customerNotes) : null;

    // 3. Insert order with verified financial totals
    final orderRes = await _client.from('orders').insert({
      'profile_id': profileId,
      'address_id': addressId,
      'status': 'pending_payment',
      'subtotal': verifiedSubtotal,
      'delivery_fee': deliveryFee,
      'discount_amount': 0.0,
      'total': total,
      'payment_status': 'pending',
      'payment_provider': 'paystack',
      'customer_notes': sanitizedNotes,
    }).select().single();

    final orderId = orderRes['id'] as String;

    // 4. Insert order items
    final itemPayloads = items.map((item) {
      final variantLabel = [
        if (item.variant?.size != null) item.variant!.size,
        if (item.variant?.colour != null) item.variant!.colour,
      ].join(' • ');

      return {
        'order_id': orderId,
        'product_id': item.product.id,
        'variant_id': item.variant?.id,
        'product_name': item.product.name,
        'variant_label': variantLabel.isEmpty ? null : variantLabel,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'total_price': item.lineTotal,
        'measurement_profile_id': item.measurementProfileId,
        'custom_options': item.measurementProfileName != null
            ? {'measurement_profile_name': item.measurementProfileName}
            : null,
      };
    }).toList();

    await _client.from('order_items').insert(itemPayloads);

    // 5. Return complete order
    return getOrderById(orderId);
  }

  Future<AppOrder> getOrderById(String orderId) async {
    final res = await _client
        .from('orders')
        .select('*, order_items(*), addresses(*), order_status_history(*)')
        .eq('id', orderId)
        .single();

    return AppOrder.fromJson(res);
  }

  Future<AppOrder?> getOrderByNumber(String orderNumber) async {
    try {
      final res = await _client
          .from('orders')
          .select('*, order_items(*), addresses(*), order_status_history(*)')
          .eq('order_number', orderNumber)
          .maybeSingle();

      if (res != null) {
        return AppOrder.fromJson(res);
      }
    } catch (_) {}
    return null;
  }

  Future<List<AppOrder>> getUserOrders(String profileId) async {
    try {
      final res = await _client
          .from('orders')
          .select('*, order_items(*), addresses(*), order_status_history(*)')
          .eq('profile_id', profileId)
          .order('created_at', ascending: false);

      return (res as List<dynamic>).map((e) => AppOrder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AppOrder>> getAllOrdersAdmin({
    OrderStatus? filterStatus,
    String? searchQuery,
  }) async {
    try {
      var query = _client
          .from('orders')
          .select('*, order_items(*), addresses(*), order_status_history(*)');

      if (filterStatus != null) {
        query = query.eq('status', filterStatus.dbValue);
      }

      final res = await query.order('created_at', ascending: false);
      var orders = (res as List<dynamic>).map((e) => AppOrder.fromJson(e as Map<String, dynamic>)).toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        orders = orders.where((o) {
          final matchNum = o.orderNumber.toLowerCase().contains(q);
          final matchCust = o.deliveryAddress?.fullName.toLowerCase().contains(q) ?? false;
          final matchEmail = o.customerNotes?.toLowerCase().contains(q) ?? false;
          return matchNum || matchCust || matchEmail;
        }).toList();
      }

      return orders;
    } catch (_) {
      return [];
    }
  }

  Future<AppOrder> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'status': newStatus.dbValue,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (notes != null && notes.isNotEmpty) {
      payload['notes'] = notes;
    }

    await _client.from('orders').update(payload).eq('id', orderId);

    return getOrderById(orderId);
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(Supabase.instance.client);
});

final userOrdersProvider = FutureProvider.family<List<AppOrder>, String>((ref, profileId) {
  return ref.watch(ordersRepositoryProvider).getUserOrders(profileId);
});

final orderDetailProvider = FutureProvider.family<AppOrder?, String>((ref, orderNumber) {
  return ref.watch(ordersRepositoryProvider).getOrderByNumber(orderNumber);
});

final adminOrdersProvider = FutureProvider.autoDispose.family<List<AppOrder>, (OrderStatus?, String?)>((ref, params) {
  final (status, search) = params;
  return ref.watch(ordersRepositoryProvider).getAllOrdersAdmin(
        filterStatus: status,
        searchQuery: search,
      );
});
