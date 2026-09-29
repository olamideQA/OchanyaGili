import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/features/auth/domain/models/user_role.dart';

void main() {
  group('UserRole tests', () {
    test('customer has expected permissions', () {
      const role = UserRole.customer;
      expect(role.canAccessAdmin, isFalse);
      expect(role.isAdmin, isFalse);
      expect(role.isDesigner, isFalse);
      expect(role.isStaff, isFalse);
      expect(role.toJson(), 'customer');
    });

    test('designer has admin access', () {
      const role = UserRole.designer;
      expect(role.canAccessAdmin, isTrue);
      expect(role.isDesigner, isTrue);
      expect(role.isAdmin, isFalse);
      expect(role.toJson(), 'designer');
    });

    test('admin has full admin access', () {
      const role = UserRole.admin;
      expect(role.canAccessAdmin, isTrue);
      expect(role.isAdmin, isTrue);
      expect(role.toJson(), 'admin');
    });

    test('staff sub-roles have staff and admin panel access', () {
      expect(UserRole.productionStaff.isStaff, isTrue);
      expect(UserRole.productionStaff.canAccessAdmin, isTrue);
      expect(UserRole.productionStaff.toJson(), 'production_staff');

      expect(UserRole.frontDesk.isStaff, isTrue);
      expect(UserRole.frontDesk.canAccessAdmin, isTrue);
      expect(UserRole.frontDesk.toJson(), 'front_desk');

      expect(UserRole.contentManager.isStaff, isTrue);
      expect(UserRole.contentManager.canAccessAdmin, isTrue);
      expect(UserRole.contentManager.toJson(), 'content_manager');
    });

    test('fromString parses correctly with customer fallback', () {
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('designer'), UserRole.designer);
      expect(UserRole.fromString('production_staff'), UserRole.productionStaff);
      expect(UserRole.fromString('front_desk'), UserRole.frontDesk);
      expect(UserRole.fromString('content_manager'), UserRole.contentManager);
      expect(UserRole.fromString('customer'), UserRole.customer);
      expect(UserRole.fromString('unknown_role'), UserRole.customer);
    });
  });
}
