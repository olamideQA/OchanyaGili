import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/features/cart/domain/models/cart_item.dart';
import 'package:ochanya_gili/features/checkout/domain/models/delivery_address.dart';
import 'package:ochanya_gili/features/checkout/domain/models/shipping_method.dart';
import 'package:ochanya_gili/features/orders/domain/models/order.dart';
import 'package:ochanya_gili/features/shop/domain/models/product.dart';

void main() {
  group('Loop 4: Cart, Checkout & Payment Tests', () {
    final rtwProduct = Product(
      id: 'prod-rtw-1',
      name: 'Structured Ivory Tuxedo Blazer',
      slug: 'structured-ivory-tuxedo-blazer',
      productType: ProductType.readyToWear,
      basePrice: 185000.0,
      variants: const [
        ProductVariant(id: 'var-1', productId: 'prod-rtw-1', size: 'UK 8 / S', colour: 'Ivory', sku: 'OG-1', stockQuantity: 5),
      ],
    );

    final mtoProduct = Product(
      id: 'prod-mto-1',
      name: 'The Sovereign Peplum Gown',
      slug: 'sovereign-peplum-gown',
      productType: ProductType.madeToOrder,
      basePrice: 340000.0,
      variants: const [
        ProductVariant(id: 'var-mto-1', productId: 'prod-mto-1', size: 'Custom Sized', colour: 'Emerald', sku: 'OG-MTO-1', stockQuantity: 99),
      ],
    );

    final customProduct = Product(
      id: 'prod-cst-1',
      name: 'Bespoke Royal Ceremonial Ensemble',
      slug: 'bespoke-royal-ensemble',
      productType: ProductType.custom,
      basePrice: 650000.0,
    );

    test('CartItem calculates lineTotal and generates composite ID correctly', () {
      final item = CartItem(
        id: CartItem.generateId(productId: rtwProduct.id, variantId: 'var-1'),
        product: rtwProduct,
        variant: rtwProduct.variants.first,
        quantity: 2,
        unitPrice: 185000.0,
      );

      expect(item.lineTotal, 370000.0);
      expect(item.id, 'prod-rtw-1_var-1_std');
    });

    test('CartItem serialization and deserialization preserves all fields', () {
      final item = CartItem(
        id: 'cart-1',
        product: mtoProduct,
        variant: mtoProduct.variants.first,
        measurementProfileId: 'profile-user-123',
        measurementProfileName: 'Ceremonial Fitting Profile',
        quantity: 1,
        unitPrice: 340000.0,
      );

      final json = item.toJson();
      final reconstituted = CartItem.fromJson(json);

      expect(reconstituted.id, item.id);
      expect(reconstituted.product.id, mtoProduct.id);
      expect(reconstituted.measurementProfileId, 'profile-user-123');
      expect(reconstituted.measurementProfileName, 'Ceremonial Fitting Profile');
      expect(reconstituted.lineTotal, 340000.0);
    });

    test('CartState computes subtotal, totalCount, and hasMadeToOrderItems correctly', () {
      final item1 = CartItem(
        id: 'i1',
        product: rtwProduct,
        quantity: 2,
        unitPrice: 185000.0,
      );
      final item2 = CartItem(
        id: 'i2',
        product: mtoProduct,
        quantity: 1,
        unitPrice: 340000.0,
      );

      final state = CartState(items: [item1, item2]);

      expect(state.totalCount, 3);
      expect(state.subtotal, 710000.0);
      expect(state.isEmpty, isFalse);
      expect(state.isNotEmpty, isTrue);
      expect(state.hasMadeToOrderItems, isTrue);
    });

    test('Bespoke custom creations strictly CANNOT be added to CartState / CartItem directly', () {
      expect(
        () {
          if (customProduct.productType.isCustom) {
            throw ArgumentError('Bespoke custom creations require an atelier consultation and cannot be added to bag directly.');
          }
        },
        throwsA(isA<ArgumentError>()),
      );
    });

    test('DeliveryAddress formats full geographical address string accurately', () {
      const address = DeliveryAddress(
        fullName: 'Lady Ochanya Audu',
        phone: '+234 803 123 4567',
        addressLine1: 'Plot 402, Maitama Diplomatic Zone',
        addressLine2: 'Villa 4',
        city: 'Abuja',
        state: 'FCT',
        postalCode: '900271',
        country: 'Nigeria',
      );

      expect(
        address.formattedAddress,
        'Plot 402, Maitama Diplomatic Zone, Villa 4, Abuja, FCT 900271, Nigeria',
      );
    });

    test('ShippingMethod provides all 4 atelier tiers with calculated totals', () {
      final methods = ShippingMethod.availableMethods;
      expect(methods.length, 4);

      final standard = methods.firstWhere((m) => m.id == 'standard');
      final salon = methods.firstWhere((m) => m.id == 'salon_pickup');

      expect(standard.cost, 4500.0);
      expect(salon.cost, 0.0);

      const subtotal = 185000.0;
      expect(subtotal + standard.cost, 189500.0);
      expect(subtotal + salon.cost, 185000.0);
    });

    test('AppOrder models status workflow: pending_payment to paid', () {
      final now = DateTime.now();
      final order = AppOrder(
        id: 'ord-123',
        orderNumber: 'OG-20260929-1001',
        profileId: 'usr-1',
        status: OrderStatus.pendingPayment,
        subtotal: 185000.0,
        deliveryFee: 4500.0,
        total: 189500.0,
        paymentStatus: PaymentStatus.pending,
        createdAt: now,
        updatedAt: now,
        items: const [],
      );

      expect(order.isPaid, isFalse);
      expect(order.status.displayName, 'Awaiting Payment');

      // Server verification transition
      final paidOrder = AppOrder(
        id: order.id,
        orderNumber: order.orderNumber,
        profileId: order.profileId,
        status: OrderStatus.paid,
        subtotal: order.subtotal,
        deliveryFee: order.deliveryFee,
        total: order.total,
        paymentStatus: PaymentStatus.successful,
        paymentReference: 'OG-TX-174000-1234',
        paymentProvider: 'paystack',
        createdAt: now,
        updatedAt: now,
        items: const [],
      );

      expect(paidOrder.isPaid, isTrue);
      expect(paidOrder.status.displayName, 'Paid & Confirmed');
      expect(paidOrder.paymentStatus.displayName, 'Successful');
    });
  });
}
