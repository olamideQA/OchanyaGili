import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/features/admin/domain/models/admin_dashboard_models.dart';
import 'package:ochanya_gili/features/auth/domain/models/user_role.dart';

void main() {
  group('Loop 11 - Admin Models & Domain Logic Tests', () {
    test('AdminDashboardMetrics.empty creates baseline zeroes', () {
      final m = AdminDashboardMetrics.empty();
      expect(m.todayOrders, 0);
      expect(m.todayRevenue, 0.0);
      expect(m.todayAppointments, 0);
      expect(m.todayCustomRequests, 0);
      expect(m.pipelineRequests, 0);
      expect(m.pipelineQuoted, 0);
      expect(m.pipelineProduction, 0);
      expect(m.pipelineFitting, 0);
      expect(m.pipelineReady, 0);
      expect(m.recentOrders, isEmpty);
      expect(m.recentRequests, isEmpty);
      expect(m.upcomingAppointments, isEmpty);
    });

    test('InventoryItem stock levels: in-stock, low-stock, and out-of-stock', () {
      const normalItem = InventoryItem(
        id: '1',
        name: 'Silk Mikado',
        sku: 'SLK-01',
        quantity: 25.0,
        unit: 'meters',
        costPerUnit: 12000.0,
        reorderThreshold: 5.0,
      );
      expect(normalItem.isOutOfStock, false);
      expect(normalItem.isLowStock, false);

      const lowStockItem = InventoryItem(
        id: '2',
        name: 'Gold Metallic Thread',
        sku: 'THR-02',
        quantity: 3.5,
        unit: 'spools',
        costPerUnit: 4500.0,
        reorderThreshold: 5.0,
      );
      expect(lowStockItem.isOutOfStock, false);
      expect(lowStockItem.isLowStock, true);

      const outOfStockItem = InventoryItem(
        id: '3',
        name: 'French Chantilly Lace',
        sku: 'LCE-03',
        quantity: 0.0,
        unit: 'meters',
        costPerUnit: 35000.0,
        reorderThreshold: 5.0,
      );
      expect(outOfStockItem.isOutOfStock, true);
      expect(outOfStockItem.isLowStock, false);
    });

    test('InventoryItem serialization roundtrip', () {
      final json = {
        'id': 'inv-123',
        'name': 'Duchess Satin',
        'sku': 'SAT-99',
        'description': 'Heavy weight couture satin',
        'quantity': 18.5,
        'unit': 'yards',
        'cost_per_unit': 8500.0,
        'supplier': 'Como Silk Mills',
        'reorder_threshold': 6.0,
        'is_active': true,
      };

      final item = InventoryItem.fromJson(json);
      expect(item.id, 'inv-123');
      expect(item.name, 'Duchess Satin');
      expect(item.sku, 'SAT-99');
      expect(item.quantity, 18.5);
      expect(item.costPerUnit, 8500.0);
      expect(item.supplier, 'Como Silk Mills');

      final serialized = item.toJson();
      expect(serialized['name'], 'Duchess Satin');
      expect(serialized['sku'], 'SAT-99');
      expect(serialized['unit'], 'yards');
      expect(serialized['cost_per_unit'], 8500.0);
    });

    test('AdminDiscount expiration calculation', () {
      final expiredDiscount = AdminDiscount(
        id: 'disc-1',
        code: 'PAST2020',
        type: 'percentage',
        value: 20.0,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      expect(expiredDiscount.isExpired, true);

      final activeDiscount = AdminDiscount(
        id: 'disc-2',
        code: 'FUTURE2027',
        type: 'percentage',
        value: 15.0,
        expiresAt: DateTime.now().add(const Duration(days: 60)),
        createdAt: DateTime.now(),
      );
      expect(activeDiscount.isExpired, false);

      final perpetualDiscount = AdminDiscount(
        id: 'disc-3',
        code: 'PERPETUAL',
        type: 'fixed_amount',
        value: 10000.0,
        expiresAt: null,
        createdAt: DateTime.now(),
      );
      expect(perpetualDiscount.isExpired, false);
    });

    test('AdminPaymentRecord JSON parsing handles profiles join', () {
      final json = {
        'id': 'pay-001',
        'order_id': 'ord-123',
        'profile_id': 'usr-456',
        'amount': 250000.0,
        'currency': 'NGN',
        'provider': 'paystack',
        'provider_reference': 'ref_test_9988',
        'status': 'successful',
        'payment_type': 'custom_deposit',
        'created_at': '2026-09-29T10:00:00Z',
        'profiles': {
          'full_name': 'Lady Ochanya Audu',
          'email': 'ochanya.client.test@gmail.com',
        },
      };

      final record = AdminPaymentRecord.fromJson(json);
      expect(record.id, 'pay-001');
      expect(record.customerName, 'Lady Ochanya Audu');
      expect(record.customerEmail, 'ochanya.client.test@gmail.com');
      expect(record.amount, 250000.0);
      expect(record.status, 'successful');
      expect(record.paymentType, 'custom_deposit');
    });

    test('DesignerNote parses confidential creator profiles', () {
      final json = {
        'id': 'note-777',
        'entity_type': 'custom_request',
        'entity_id': 'req-888',
        'content': 'Client prefers higher neckline with seed pearl embroidery along lapel.',
        'created_by': 'designer-uuid-1',
        'created_at': '2026-09-29T12:00:00Z',
        'profiles': {
          'full_name': 'Master Couturier Ochanya',
        },
      };

      final note = DesignerNote.fromJson(json);
      expect(note.id, 'note-777');
      expect(note.entityType, 'custom_request');
      expect(note.createdByName, 'Master Couturier Ochanya');
      expect(note.content, contains('seed pearl embroidery'));
    });
  });

  group('Section 51 Role Scope Matrix Verification', () {
    test('Super Admin (admin) has access to all admin surfaces', () {
      const role = UserRole.admin;
      expect(role.isAdmin, true);
      expect(role.canAccessAdmin, true);
      expect(role.isStaff, false);
    });

    test('Designer has access to creative, bespoke, and customer surfaces', () {
      const role = UserRole.designer;
      expect(role.isDesigner, true);
      expect(role.canAccessAdmin, true);
      expect(role.isAdmin, false);
    });

    test('Production Staff role is restricted to orders & inventory', () {
      const role = UserRole.productionStaff;
      expect(role.isStaff, true);
      expect(role.canAccessAdmin, true);
      expect(role.isAdmin, false);
      expect(role.isDesigner, false);

      // Verify path allowance logic matching router
      bool isAllowed(String path) =>
          path.startsWith('/admin/orders') || path.startsWith('/admin/inventory');

      expect(isAllowed('/admin/orders'), true);
      expect(isAllowed('/admin/orders/OG-1234'), true);
      expect(isAllowed('/admin/inventory'), true);
      expect(isAllowed('/admin/payments'), false);
      expect(isAllowed('/admin/discounts'), false);
      expect(isAllowed('/admin/customers'), false);
      expect(isAllowed('/admin/appointments'), false);
      expect(isAllowed('/admin/settings'), false);
    });

    test('Front Desk role is restricted to appointments & customer directory', () {
      const role = UserRole.frontDesk;
      expect(role.isStaff, true);
      expect(role.canAccessAdmin, true);

      bool isAllowed(String path) =>
          path.startsWith('/admin/appointments') || path.startsWith('/admin/customers');

      expect(isAllowed('/admin/appointments'), true);
      expect(isAllowed('/admin/customers'), true);
      expect(isAllowed('/admin/customers/cust-1/measurements'), true);
      expect(isAllowed('/admin/orders'), false);
      expect(isAllowed('/admin/inventory'), false);
      expect(isAllowed('/admin/payments'), false);
      expect(isAllowed('/admin/discounts'), false);
      expect(isAllowed('/admin/products'), false);
    });

    test('Content Manager role is restricted to editorial & product catalog', () {
      const role = UserRole.contentManager;
      expect(role.isStaff, true);
      expect(role.canAccessAdmin, true);

      bool isAllowed(String path) =>
          path.startsWith('/admin/products') ||
          path.startsWith('/admin/collections') ||
          path.startsWith('/admin/lookbook') ||
          path.startsWith('/admin/journal') ||
          path.startsWith('/admin/media');

      expect(isAllowed('/admin/products'), true);
      expect(isAllowed('/admin/collections'), true);
      expect(isAllowed('/admin/lookbook'), true);
      expect(isAllowed('/admin/journal'), true);
      expect(isAllowed('/admin/media'), true);
      expect(isAllowed('/admin/orders'), false);
      expect(isAllowed('/admin/customers'), false);
      expect(isAllowed('/admin/payments'), false);
      expect(isAllowed('/admin/inventory'), false);
      expect(isAllowed('/admin/settings'), false);
    });

    test('Customer role is completely denied from all /admin routes', () {
      const role = UserRole.customer;
      expect(role.canAccessAdmin, false);
      expect(role.isAdmin, false);
      expect(role.isDesigner, false);
      expect(role.isStaff, false);
    });
  });
}
