import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ochanya_gili/core/router/route_names.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';
import 'package:ochanya_gili/features/auth/presentation/screens/login_screen.dart';
import 'package:ochanya_gili/features/auth/presentation/screens/signup_screen.dart';
import 'package:ochanya_gili/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:ochanya_gili/features/home/presentation/screens/home_screen.dart';
import 'package:ochanya_gili/features/about/presentation/screens/about_screen.dart';
import 'package:ochanya_gili/features/contact/presentation/screens/contact_screen.dart';
import 'package:ochanya_gili/features/journal/presentation/screens/journal_list_screen.dart';
import 'package:ochanya_gili/features/journal/presentation/screens/journal_detail_screen.dart';
import 'package:ochanya_gili/features/collections/presentation/screens/collections_list_screen.dart';
import 'package:ochanya_gili/features/collections/presentation/screens/collection_detail_screen.dart';
import 'package:ochanya_gili/features/lookbook/presentation/screens/lookbook_screen.dart';
import 'package:ochanya_gili/features/shop/presentation/screens/shop_screen.dart';
import 'package:ochanya_gili/features/shop/presentation/screens/product_detail_screen.dart';
import 'package:ochanya_gili/features/auth/domain/models/user_role.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/cms_editor_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_collections_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_lookbook_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_products_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_overview_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_customers_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_inventory_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_payments_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_discounts_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_media_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_journal_screen.dart';
import 'package:ochanya_gili/features/cart/presentation/screens/cart_screen.dart';
import 'package:ochanya_gili/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:ochanya_gili/features/checkout/presentation/screens/order_confirmation_screen.dart';
import 'package:ochanya_gili/features/orders/presentation/screens/customer_orders_screen.dart';
import 'package:ochanya_gili/features/orders/presentation/screens/order_timeline_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:ochanya_gili/features/measurements/presentation/screens/customer_measurements_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_customer_measurements_screen.dart';
import 'package:ochanya_gili/features/custom_atelier/presentation/screens/custom_atelier_screen.dart';
import 'package:ochanya_gili/features/custom_atelier/presentation/screens/customer_custom_requests_screen.dart';
import 'package:ochanya_gili/features/custom_atelier/presentation/screens/custom_request_detail_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_custom_requests_screen.dart';
import 'package:ochanya_gili/features/appointments/presentation/screens/book_appointment_screen.dart';
import 'package:ochanya_gili/features/appointments/presentation/screens/customer_appointments_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_appointments_screen.dart';
import 'package:ochanya_gili/features/account/presentation/screens/customer_dashboard_screen.dart';
import 'package:ochanya_gili/features/account/presentation/screens/customer_wishlist_screen.dart';
import 'package:ochanya_gili/features/account/presentation/screens/customer_addresses_screen.dart';
import 'package:ochanya_gili/features/account/presentation/screens/customer_notifications_screen.dart';
import 'package:ochanya_gili/features/account/presentation/screens/customer_settings_screen.dart';
import 'package:ochanya_gili/core/seo/seo_service.dart';
import 'package:ochanya_gili/core/utils/performance_tracker.dart';
import 'package:ochanya_gili/features/analytics/data/analytics_service.dart';
import 'package:ochanya_gili/features/shell/presentation/screens/public_shell.dart';
import 'package:ochanya_gili/features/shell/presentation/screens/customer_shell.dart';
import 'package:ochanya_gili/features/shell/presentation/screens/admin_shell.dart';
import 'package:ochanya_gili/features/shell/presentation/screens/not_found_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_seo_screen.dart';
import 'package:ochanya_gili/features/cms/presentation/screens/dynamic_page_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_navigation_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_theme_studio_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_footer_screen.dart';
import 'package:ochanya_gili/features/admin/presentation/screens/admin_custom_pages_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(currentUserProvider, (previous, next) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final publicShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'public');
  final customerShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'customer');
  final adminShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'admin');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/',
    errorBuilder: (context, state) => NotFoundScreen(uri: state.uri.toString()),
    redirect: (context, state) {
      final path = state.uri.path;

      // Apply static route SEO metadata and record route transition metric
      ref.read(seoServiceProvider).applyRoute(path);
      ref.read(performanceTrackerProvider).recordSample('route_transition', 45);
      ref.read(analyticsServiceProvider).trackPageView(path);

      final authAsync = ref.read(currentUserProvider);
      if (authAsync.isLoading) return null;

      final user = authAsync.value;
      final isAuthenticated = user != null;
      final isAuthRoute = path == '/login' || path == '/signup' || path == '/forgot-password';

      // Unauthenticated access restrictions
      if (!isAuthenticated) {
        if (path.startsWith('/account') || path.startsWith('/admin')) {
          return '/login';
        }
        return null;
      }

      // Logged in user hitting auth screens
      if (isAuthRoute) {
        if (user.role.canAccessAdmin) {
          if (user.role == UserRole.productionStaff) return '/admin/orders';
          if (user.role == UserRole.frontDesk) return '/admin/appointments';
          if (user.role == UserRole.contentManager) return '/admin/products';
          return '/admin';
        }
        return '/account';
      }

      // Customer trying to hit /admin
      if (path.startsWith('/admin')) {
        if (!user.role.canAccessAdmin) {
          return '/account';
        }

        // Section 51 Role Scope Matrix guards
        if (user.role == UserRole.productionStaff) {
          final isAllowed = path.startsWith('/admin/orders') || path.startsWith('/admin/inventory');
          if (!isAllowed) return '/admin/orders';
        } else if (user.role == UserRole.frontDesk) {
          final isAllowed = path.startsWith('/admin/appointments') || path.startsWith('/admin/customers');
          if (!isAllowed) return '/admin/appointments';
        } else if (user.role == UserRole.contentManager) {
          final isAllowed = path.startsWith('/admin/products') ||
              path.startsWith('/admin/collections') ||
              path.startsWith('/admin/lookbook') ||
              path.startsWith('/admin/journal') ||
              path.startsWith('/admin/media');
          if (!isAllowed) return '/admin/products';
        } else if (user.role == UserRole.designer) {
          final isBlocked = path.startsWith('/admin/settings') ||
              path.startsWith('/admin/discounts') ||
              path.startsWith('/admin/payments');
          if (isBlocked) return '/admin';
        }
      }

      return null;
    },
    routes: [
      // Public Shell Route
      ShellRoute(
        navigatorKey: publicShellNavigatorKey,
        builder: (context, state, child) => PublicShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: RouteNames.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/collections',
            builder: (context, state) => const CollectionsListScreen(),
          ),
          GoRoute(
            path: '/collections/:slug',
            builder: (context, state) {
              final slug = state.pathParameters['slug'] ?? '';
              return CollectionDetailScreen(slug: slug);
            },
          ),
          GoRoute(
            path: '/shop',
            builder: (context, state) => const ShopScreen(),
          ),
          GoRoute(
            path: '/shop/:slug',
            builder: (context, state) {
              final slug = state.pathParameters['slug'] ?? '';
              return ProductDetailScreen(slug: slug);
            },
          ),
          GoRoute(
            path: '/lookbook',
            builder: (context, state) => const LookbookScreen(),
          ),
          GoRoute(
            path: '/lookbook/:slug',
            builder: (context, state) {
              final slug = state.pathParameters['slug'];
              return LookbookScreen(initialSlug: slug);
            },
          ),
          GoRoute(
            path: '/journal',
            builder: (context, state) => const JournalListScreen(),
          ),
          GoRoute(
            path: '/journal/:slug',
            builder: (context, state) {
              final slug = state.pathParameters['slug'] ?? '';
              return JournalDetailScreen(slug: slug);
            },
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: '/contact',
            builder: (context, state) => const ContactScreen(),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/checkout',
            builder: (context, state) => const CheckoutScreen(),
          ),
          GoRoute(
            path: '/checkout/confirmation/:orderNumber',
            builder: (context, state) {
              final orderNumber = state.pathParameters['orderNumber'] ?? '';
              return OrderConfirmationScreen(orderNumber: orderNumber);
            },
          ),
          GoRoute(
            path: '/create-your-look',
            builder: (context, state) => const CustomAtelierScreen(),
          ),
          GoRoute(
            path: '/p/:slug',
            builder: (context, state) {
              final slug = state.pathParameters['slug'] ?? '';
              return DynamicPageScreen(slug: slug);
            },
          ),
        ],
      ),


      // Auth standalone routes
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/signup',
        name: RouteNames.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Customer Account Shell Route
      ShellRoute(
        navigatorKey: customerShellNavigatorKey,
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: '/account',
            name: RouteNames.account,
            builder: (context, state) => const CustomerDashboardScreen(),
          ),
          GoRoute(
            path: '/account/orders',
            builder: (context, state) => const CustomerOrdersScreen(),
          ),
          GoRoute(
            path: '/account/orders/:orderNumber',
            builder: (context, state) {
              final orderNumber = state.pathParameters['orderNumber'] ?? '';
              return OrderTimelineScreen(orderNumber: orderNumber);
            },
          ),
          GoRoute(
            path: '/account/custom-requests',
            builder: (context, state) => const CustomerCustomRequestsScreen(),
          ),
          GoRoute(
            path: '/account/custom-requests/new',
            builder: (context, state) => const CustomAtelierScreen(),
          ),
          GoRoute(
            path: '/account/custom-requests/:id',
            builder: (context, state) {
              final requestId = state.pathParameters['id'] ?? '';
              return CustomRequestDetailScreen(requestId: requestId);
            },
          ),
          GoRoute(
            path: '/account/appointments',
            builder: (context, state) => const CustomerAppointmentsScreen(),
          ),
          GoRoute(
            path: '/account/appointments/book',
            builder: (context, state) {
              final typeSlug = state.uri.queryParameters['type'];
              final customRequestId =
                  state.uri.queryParameters['custom_request_id'];
              return BookAppointmentScreen(
                preselectedTypeSlug: typeSlug,
                customRequestId: customRequestId,
              );
            },
          ),
          GoRoute(
            path: '/account/wishlist',
            builder: (context, state) => const CustomerWishlistScreen(),
          ),
          GoRoute(
            path: '/account/measurements',
            builder: (context, state) => const CustomerMeasurementsScreen(),
          ),
          GoRoute(
            path: '/account/addresses',
            builder: (context, state) => const CustomerAddressesScreen(),
          ),
          GoRoute(
            path: '/account/notifications',
            builder: (context, state) => const CustomerNotificationsScreen(),
          ),
          GoRoute(
            path: '/account/settings',
            builder: (context, state) => const CustomerSettingsScreen(),
          ),
        ],
      ),

      // Admin / Staff Shell Route
      ShellRoute(
        navigatorKey: adminShellNavigatorKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            name: RouteNames.admin,
            builder: (context, state) => const AdminOverviewScreen(),
          ),
          GoRoute(
            path: '/admin/products',
            builder: (context, state) => const AdminProductsScreen(),
          ),
          GoRoute(
            path: '/admin/collections',
            builder: (context, state) => const AdminCollectionsScreen(),
          ),
          GoRoute(
            path: '/admin/lookbook',
            builder: (context, state) => const AdminLookbookScreen(),
          ),
          GoRoute(
            path: '/admin/journal',
            builder: (context, state) => const AdminJournalScreen(),
          ),
          GoRoute(
            path: '/admin/orders',
            builder: (context, state) => const AdminOrdersScreen(),
          ),
          GoRoute(
            path: '/admin/custom-requests',
            builder: (context, state) => const AdminCustomRequestsScreen(),
          ),
          GoRoute(
            path: '/admin/customers',
            builder: (context, state) => const AdminCustomersScreen(),
          ),
          GoRoute(
            path: '/admin/customers/:id/measurements',
            builder: (context, state) {
              final customerId = state.pathParameters['id'] ?? '';
              return AdminCustomerMeasurementsScreen(customerId: customerId);
            },
          ),
          GoRoute(
            path: '/admin/appointments',
            builder: (context, state) => const AdminAppointmentsScreen(),
          ),
          GoRoute(
            path: '/admin/inventory',
            builder: (context, state) => const AdminInventoryScreen(),
          ),
          GoRoute(
            path: '/admin/payments',
            builder: (context, state) => const AdminPaymentsScreen(),
          ),
          GoRoute(
            path: '/admin/media',
            builder: (context, state) => const AdminMediaScreen(),
          ),
          GoRoute(
            path: '/admin/seo',
            builder: (context, state) => const AdminSeoScreen(),
          ),
          GoRoute(
            path: '/admin/discounts',
            builder: (context, state) => const AdminDiscountsScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const CmsEditorScreen(),
          ),
          GoRoute(
            path: '/admin/navigation',
            builder: (context, state) => const AdminNavigationScreen(),
          ),
          GoRoute(
            path: '/admin/theme',
            builder: (context, state) => const AdminThemeStudioScreen(),
          ),
          GoRoute(
            path: '/admin/footer',
            builder: (context, state) => const AdminFooterScreen(),
          ),
          GoRoute(
            path: '/admin/custom-pages',
            builder: (context, state) => const AdminCustomPagesScreen(),
          ),
        ],
      ),

    ],
  );
});
