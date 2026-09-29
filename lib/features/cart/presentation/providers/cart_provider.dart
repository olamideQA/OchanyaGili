import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ochanya_gili/features/cart/domain/models/cart_item.dart';
import 'package:ochanya_gili/features/shop/domain/models/product.dart';

class CartNotifier extends Notifier<CartState> {
  static const String _storageKey = 'ochanya_atelier_cart_v1';

  @override
  CartState build() {
    _loadFromStorage();
    return const CartState();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final items = decoded.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
        state = state.copyWith(items: items);
      }
    } catch (_) {
      // Graceful fallback to in-memory state
    }
  }

  Future<void> _persistToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(state.items.map((i) => i.toJson()).toList());
      await prefs.setString(_storageKey, payload);
    } catch (_) {}
  }

  /// Adds a product to the cart with strict validation
  bool addItem(
    Product product, {
    ProductVariant? variant,
    String? measurementProfileId,
    String? measurementProfileName,
    int quantity = 1,
  }) {
    // 1. STRICT ATELIER RULE: Custom creations cannot be added directly to bag
    if (product.productType.isCustom) {
      throw ArgumentError(
        'Bespoke custom creations require an atelier consultation and cannot be added to bag directly.',
      );
    }

    final id = CartItem.generateId(
      productId: product.id,
      variantId: variant?.id,
      measurementProfileId: measurementProfileId,
    );

    final existingIndex = state.items.indexWhere((item) => item.id == id);
    final unitPrice = variant?.priceOverride ?? product.basePrice;

    List<CartItem> updatedList;
    if (existingIndex >= 0) {
      final existingItem = state.items[existingIndex];
      final newQuantity = existingItem.quantity + quantity;
      final updatedItem = existingItem.copyWith(quantity: newQuantity);
      updatedList = List<CartItem>.from(state.items);
      updatedList[existingIndex] = updatedItem;
    } else {
      final newItem = CartItem(
        id: id,
        product: product,
        variant: variant,
        measurementProfileId: measurementProfileId,
        measurementProfileName: measurementProfileName,
        quantity: quantity,
        unitPrice: unitPrice,
      );
      updatedList = [...state.items, newItem];
    }

    state = state.copyWith(items: updatedList);
    _persistToStorage();
    return true;
  }

  void updateQuantity(String cartItemId, int quantity) {
    if (quantity <= 0) {
      removeItem(cartItemId);
      return;
    }

    final updated = state.items.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updated);
    _persistToStorage();
  }

  void removeItem(String cartItemId) {
    final updated = state.items.where((item) => item.id != cartItemId).toList();
    state = state.copyWith(items: updated);
    _persistToStorage();
  }

  void clearCart() {
    state = const CartState();
    _persistToStorage();
  }
}

final cartNotifierProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});
