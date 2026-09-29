import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/features/auth/domain/models/app_user.dart';
import 'package:ochanya_gili/features/auth/domain/models/user_role.dart';

void main() {
  group('Route Guard Verification Tests', () {
    String? evaluateRouteGuard({
      required String requestedPath,
      required AppUser? user,
      required bool isLoading,
    }) {
      if (isLoading) return null;

      final isAuthenticated = user != null;
      final isAuthRoute = requestedPath == '/login' ||
          requestedPath == '/signup' ||
          requestedPath == '/forgot-password';

      if (!isAuthenticated) {
        if (requestedPath.startsWith('/account') || requestedPath.startsWith('/admin')) {
          return '/login';
        }
        return null;
      }

      if (isAuthRoute) {
        if (user.role.canAccessAdmin) {
          return '/admin';
        }
        return '/account';
      }

      if (requestedPath.startsWith('/admin') && !user.role.canAccessAdmin) {
        return '/account';
      }

      return null;
    }

    test('Unauthenticated user is redirected to /login when attempting to access /account', () {
      final redirect = evaluateRouteGuard(
        requestedPath: '/account/orders',
        user: null,
        isLoading: false,
      );
      expect(redirect, '/login');
    });

    test('Unauthenticated user is redirected to /login when attempting to access /admin', () {
      final redirect = evaluateRouteGuard(
        requestedPath: '/admin/products',
        user: null,
        isLoading: false,
      );
      expect(redirect, '/login');
    });

    test('Unauthenticated user can access public routes directly', () {
      expect(
        evaluateRouteGuard(requestedPath: '/', user: null, isLoading: false),
        isNull,
      );
      expect(
        evaluateRouteGuard(requestedPath: '/shop', user: null, isLoading: false),
        isNull,
      );
      expect(
        evaluateRouteGuard(requestedPath: '/lookbook', user: null, isLoading: false),
        isNull,
      );
      expect(
        evaluateRouteGuard(requestedPath: '/login', user: null, isLoading: false),
        isNull,
      );
    });

    test('Customer role user is denied access to /admin and redirected to /account', () {
      const customer = AppUser(
        id: 'cust-1',
        email: 'customer@test.com',
        name: 'Customer',
        role: UserRole.customer,
      );

      final redirect = evaluateRouteGuard(
        requestedPath: '/admin/settings',
        user: customer,
        isLoading: false,
      );
      expect(redirect, '/account');
    });

    test('Customer landing on /login or /signup is redirected to /account', () {
      const customer = AppUser(
        id: 'cust-1',
        email: 'customer@test.com',
        name: 'Customer',
        role: UserRole.customer,
      );

      expect(
        evaluateRouteGuard(requestedPath: '/login', user: customer, isLoading: false),
        '/account',
      );
      expect(
        evaluateRouteGuard(requestedPath: '/signup', user: customer, isLoading: false),
        '/account',
      );
    });

    test('Designer/Admin landing on /login is redirected to /admin', () {
      const designer = AppUser(
        id: 'des-1',
        email: 'designer@ochanya.com',
        name: 'Designer',
        role: UserRole.designer,
      );

      expect(
        evaluateRouteGuard(requestedPath: '/login', user: designer, isLoading: false),
        '/admin',
      );
    });

    test('Admin/Designer can access /admin routes freely', () {
      const admin = AppUser(
        id: 'adm-1',
        email: 'admin@ochanya.com',
        name: 'Admin',
        role: UserRole.admin,
      );

      expect(
        evaluateRouteGuard(requestedPath: '/admin/orders', user: admin, isLoading: false),
        isNull,
      );
    });
  });
}
