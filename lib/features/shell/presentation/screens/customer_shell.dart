import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/auth/data/auth_repository.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';

class CustomerShell extends ConsumerStatefulWidget {
  final Widget child;

  const CustomerShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell> {
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/account/orders')) return 1;
    if (location.startsWith('/account/custom-requests')) return 2;
    if (location.startsWith('/account/appointments')) return 3;
    if (location.startsWith('/account/wishlist')) return 4;
    return 0; // dashboard
  }

  void _onBottomNavTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/account');
        break;
      case 1:
        context.go('/account/orders');
        break;
      case 2:
        context.go('/account/custom-requests');
        break;
      case 3:
        context.go('/account/appointments');
        break;
      case 4:
        context.go('/account/wishlist');
        break;
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(
                'MY ATELIER ACCOUNT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: colors.primaryText,
                ),
              ),
              backgroundColor: colors.surface,
              iconTheme: IconThemeData(color: colors.primaryText),
              elevation: 0,
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: colors.surface,
              child: _buildDrawerContent(colors, context, user?.name ?? 'Client', user?.email ?? ''),
            ),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 270,
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(right: BorderSide(color: colors.border)),
              ),
              child: Column(
                children: [
                  // Client Profile Header in Sidebar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 28),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: colors.border)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OCHANYA GILI PRIVÉ',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2.5,
                            fontWeight: FontWeight.bold,
                            color: colors.accentVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.name ?? 'Atelier Client',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Navigation Links
                  Expanded(
                    child: _buildNavList(colors, context),
                  ),

                  // Return to Store Link
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: colors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.storefront_outlined, size: 16),
                          label: const Text('BACK TO ATELIER'),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.secondaryText,
                            textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _calculateSelectedIndex(context),
              onTap: (index) => _onBottomNavTapped(index, context),
              backgroundColor: colors.surface,
              selectedItemColor: colors.accentVariant,
              unselectedItemColor: colors.secondaryText,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard),
                    label: 'Overview'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.inventory_2_outlined),
                    activeIcon: Icon(Icons.inventory_2),
                    label: 'Orders'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.design_services_outlined),
                    activeIcon: Icon(Icons.design_services),
                    label: 'Bespoke'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today_outlined),
                    activeIcon: Icon(Icons.calendar_today),
                    label: 'Fittings'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.favorite_border),
                    activeIcon: Icon(Icons.favorite),
                    label: 'Wishlist'),
              ],
            ),
    );
  }

  Widget _buildDrawerContent(AppColorTokens colors, BuildContext context,
      String clientName, String clientEmail) {
    return Column(
      children: [
        DrawerHeader(
          decoration: BoxDecoration(color: colors.surfaceVariant),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'OCHANYA GILI PRIVÉ',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                  color: colors.accentVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                clientName,
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.primaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                clientEmail,
                style: TextStyle(fontSize: 12, color: colors.secondaryText),
              ),
            ],
          ),
        ),
        Expanded(child: _buildNavList(colors, context)),
      ],
    );
  }

  Widget _buildNavList(AppColorTokens colors, BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _navItem(
          title: 'Dashboard',
          icon: Icons.dashboard_outlined,
          route: '/account',
          isSelected: location == '/account',
          colors: colors,
          context: context,
        ),
        _navItem(
          title: 'My Orders',
          icon: Icons.inventory_2_outlined,
          route: '/account/orders',
          isSelected: location.startsWith('/account/orders'),
          colors: colors,
          context: context,
        ),
        _navItem(
          title: 'Custom Commissions',
          icon: Icons.design_services_outlined,
          route: '/account/custom-requests',
          isSelected: location.startsWith('/account/custom-requests'),
          colors: colors,
          context: context,
        ),
        _navItem(
          title: 'Atelier Appointments',
          icon: Icons.calendar_today_outlined,
          route: '/account/appointments',
          isSelected: location.startsWith('/account/appointments'),
          colors: colors,
          context: context,
        ),
        _navItem(
          title: 'Saved Looks (Wishlist)',
          icon: Icons.favorite_border,
          route: '/account/wishlist',
          isSelected: location.startsWith('/account/wishlist'),
          colors: colors,
          context: context,
        ),
        _navItem(
          title: 'Body Measurements',
          icon: Icons.straighten,
          route: '/account/measurements',
          isSelected: location.startsWith('/account/measurements'),
          colors: colors,
          context: context,
        ),
        _navItem(
          title: 'Delivery Addresses',
          icon: Icons.location_on_outlined,
          route: '/account/addresses',
          isSelected: location.startsWith('/account/addresses'),
          colors: colors,
          context: context,
        ),
        _navItem(
          title: 'Notifications',
          icon: Icons.notifications_none,
          route: '/account/notifications',
          isSelected: location.startsWith('/account/notifications'),
          colors: colors,
          context: context,
        ),
        _navItem(
          title: 'Account Settings',
          icon: Icons.settings_outlined,
          route: '/account/settings',
          isSelected: location.startsWith('/account/settings'),
          colors: colors,
          context: context,
        ),
        const SizedBox(height: 12),
        Divider(color: colors.border, height: 1),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          leading: Icon(Icons.logout, color: colors.error, size: 20),
          title: Text(
            'Sign Out',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.error,
            ),
          ),
          onTap: () => _handleSignOut(context),
        ),
      ],
    );
  }

  Widget _navItem({
    required String title,
    required IconData icon,
    required String route,
    required bool isSelected,
    required AppColorTokens colors,
    required BuildContext context,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? colors.surfaceVariant
            : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: isSelected ? colors.accentVariant : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 21, vertical: 0),
        leading: Icon(
          icon,
          color: isSelected ? colors.primaryText : colors.secondaryText,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? colors.primaryText : colors.secondaryText,
          ),
        ),
        onTap: () {
          context.go(route);
          if (MediaQuery.of(context).size.width < 900) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}
