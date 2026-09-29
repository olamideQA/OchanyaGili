import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/features/account/domain/models/customer_account_models.dart';
import 'package:ochanya_gili/features/orders/domain/models/order.dart';

void main() {
  group('CustomerAddress', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'addr-001',
        'profile_id': 'user-123',
        'label': 'Maitama Residence',
        'full_name': 'Lady Ochanya Audu',
        'phone': '+2348012345678',
        'address_line1': '14 Mississippi Street',
        'address_line2': 'Penthouse B',
        'city': 'Maitama',
        'state': 'Abuja FCT',
        'country': 'Nigeria',
        'postal_code': '900271',
        'instructions': 'Deliver to private concierge desk.',
        'is_default': true,
        'created_at': '2026-09-29T00:00:00.000Z',
      };

      final addr = CustomerAddress.fromJson(json);
      expect(addr.id, 'addr-001');
      expect(addr.profileId, 'user-123');
      expect(addr.label, 'Maitama Residence');
      expect(addr.fullName, 'Lady Ochanya Audu');
      expect(addr.phone, '+2348012345678');
      expect(addr.addressLine1, '14 Mississippi Street');
      expect(addr.addressLine2, 'Penthouse B');
      expect(addr.city, 'Maitama');
      expect(addr.state, 'Abuja FCT');
      expect(addr.country, 'Nigeria');
      expect(addr.postalCode, '900271');
      expect(addr.instructions, 'Deliver to private concierge desk.');
      expect(addr.isDefault, isTrue);
    });

    test('formattedAddress includes addressLine2 when present', () {
      const addr = CustomerAddress(
        profileId: 'user-1',
        fullName: 'Test Client',
        phone: '123',
        addressLine1: '42 Victoria Island',
        addressLine2: 'Suite 401',
        city: 'Lagos',
        state: 'Lagos State',
        country: 'Nigeria',
      );

      expect(addr.formattedAddress,
          '42 Victoria Island, Suite 401, Lagos, Lagos State, Nigeria');
    });

    test('formattedAddress omits addressLine2 when null or empty', () {
      const addr = CustomerAddress(
        profileId: 'user-1',
        fullName: 'Test Client',
        phone: '123',
        addressLine1: '12 Maitama Road',
        city: 'Abuja',
        state: 'FCT',
        country: 'Nigeria',
      );

      expect(addr.formattedAddress, '12 Maitama Road, Abuja, FCT, Nigeria');
    });

    test('toJson serializes correctly and omits id when includeId is false', () {
      const addr = CustomerAddress(
        id: 'addr-99',
        profileId: 'user-1',
        fullName: 'Simon Test',
        phone: '+2348000000000',
        addressLine1: 'Street 1',
        city: 'Abuja',
        state: 'FCT',
        isDefault: true,
      );

      final withId = addr.toJson(includeId: true);
      expect(withId['id'], 'addr-99');
      expect(withId['is_default'], isTrue);

      final withoutId = addr.toJson(includeId: false);
      expect(withoutId.containsKey('id'), isFalse);
    });
  });

  group('CustomerNotification', () {
    test('fromJson parses correctly with all types', () {
      final json = {
        'id': 'notif-001',
        'profile_id': 'user-123',
        'title': 'Atelier Construction Started',
        'body': 'Master craftsmen have begun hand-cutting your bespoke gown.',
        'type': 'order',
        'reference_type': 'order',
        'reference_id': 'order-uuid',
        'is_read': false,
        'channel': 'in_app',
        'created_at': '2026-09-29T02:00:00.000Z',
      };

      final notif = CustomerNotification.fromJson(json);
      expect(notif.id, 'notif-001');
      expect(notif.title, 'Atelier Construction Started');
      expect(notif.type, 'order');
      expect(notif.referenceType, 'order');
      expect(notif.referenceId, 'order-uuid');
      expect(notif.isRead, isFalse);
    });
  });

  group('WishlistItem', () {
    test('fromJson parses correctly with product join', () {
      final json = {
        'id': 'wish-001',
        'profile_id': 'user-123',
        'product_id': 'prod-001',
        'created_at': '2026-09-29T01:00:00.000Z',
        'products': {
          'id': 'prod-001',
          'name': 'The Ochanya Royal Silk Gown',
          'slug': 'royal-silk-gown',
          'description': 'Pure silk evening gown with corset detailing.',
          'product_type': 'made_to_order',
          'base_price': 385000.0,
          'is_active': true,
        },
      };

      final item = WishlistItem.fromJson(json);
      expect(item.id, 'wish-001');
      expect(item.productId, 'prod-001');
      expect(item.product?.name, 'The Ochanya Royal Silk Gown');
      expect(item.product?.basePrice, 385000.0);
    });
  });

  group('CustomerDashboardOverview', () {
    test('instantiates with expected default values', () {
      const overview = CustomerDashboardOverview();
      expect(overview.totalOrders, 0);
      expect(overview.activeOrdersCount, 0);
      expect(overview.latestOrder, isNull);
      expect(overview.customRequestsCount, 0);
      expect(overview.upcomingAppointmentsCount, 0);
      expect(overview.savedLooksCount, 0);
      expect(overview.savedMeasurementsCount, 0);
      expect(overview.unreadNotificationsCount, 0);
    });

    test('holds aggregated metrics and active order reference', () {
      final order = AppOrder(
        id: 'ord-1',
        orderNumber: 'OG-20260929-1001',
        profileId: 'user-1',
        status: OrderStatus.inProduction,
        subtotal: 350000,
        deliveryFee: 15000,
        total: 365000,
        paymentStatus: PaymentStatus.successful,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final overview = CustomerDashboardOverview(
        totalOrders: 3,
        activeOrdersCount: 1,
        latestOrder: order,
        customRequestsCount: 2,
        upcomingAppointmentsCount: 1,
        savedLooksCount: 5,
        savedMeasurementsCount: 2,
        unreadNotificationsCount: 3,
      );

      expect(overview.totalOrders, 3);
      expect(overview.activeOrdersCount, 1);
      expect(overview.latestOrder?.orderNumber, 'OG-20260929-1001');
      expect(overview.savedLooksCount, 5);
      expect(overview.savedMeasurementsCount, 2);
      expect(overview.unreadNotificationsCount, 3);
    });
  });
}
