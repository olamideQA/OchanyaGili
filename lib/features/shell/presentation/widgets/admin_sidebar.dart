import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/auth/data/auth_repository.dart';
import 'package:ochanya_gili/features/auth/domain/models/user_role.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';

class AdminSidebar extends ConsumerWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final role = user?.role ?? UserRole.admin;

    final roleLabel = role.name.toUpperCase().replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => ' ${m[0]}',
        ).trim();

    return Container(
      width: 250,
      color: colors.surface,
      child: Column(
        children: [
          // Brand & User Role header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OCHANYA GILI',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    color: colors.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Atelier Control & Ops',
                  style: TextStyle(color: colors.secondaryText, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.accentVariant.withValues(alpha: 0.15),
                    border: Border.all(color: colors.accentVariant.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: colors.border, height: 1),

          // Role-filtered navigation menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _buildMenuItems(context, colors, role),
            ),
          ),

          Divider(color: colors.border, height: 1),

          // Sign Out & Switch Account
          ListTile(
            leading: Icon(Icons.logout, color: colors.secondaryText, size: 20),
            title: Text(
              'Sign Out',
              style: TextStyle(color: colors.secondaryText, fontSize: 13),
            ),
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context, AppColorTokens colors, UserRole role) {
    final List<Widget> items = [];

    // Super Admin: Everything
    if (role == UserRole.admin) {
      items.addAll([
        _SidebarItem(icon: Icons.dashboard_outlined, title: 'Dashboard', path: '/admin', colors: colors),
        _SidebarItem(icon: Icons.shopping_bag_outlined, title: 'Orders', path: '/admin/orders', colors: colors),
        _SidebarItem(icon: Icons.design_services_outlined, title: 'Custom Requests', path: '/admin/custom-requests', colors: colors),
        _SidebarItem(icon: Icons.calendar_today_outlined, title: 'Appointments', path: '/admin/appointments', colors: colors),
        _SidebarItem(icon: Icons.people_outline, title: 'Customers', path: '/admin/customers', colors: colors),
        _SidebarItem(icon: Icons.checkroom_outlined, title: 'Products', path: '/admin/products', colors: colors),
        _SidebarItem(icon: Icons.collections_outlined, title: 'Collections', path: '/admin/collections', colors: colors),
        _SidebarItem(icon: Icons.auto_stories_outlined, title: 'Lookbook', path: '/admin/lookbook', colors: colors),
        _SidebarItem(icon: Icons.article_outlined, title: 'Journal', path: '/admin/journal', colors: colors),
        _SidebarItem(icon: Icons.inventory_2_outlined, title: 'Inventory', path: '/admin/inventory', colors: colors),
        _SidebarItem(icon: Icons.payments_outlined, title: 'Payments', path: '/admin/payments', colors: colors),
        _SidebarItem(icon: Icons.local_offer_outlined, title: 'Discounts', path: '/admin/discounts', colors: colors),
        _SidebarItem(icon: Icons.perm_media_outlined, title: 'Media', path: '/admin/media', colors: colors),
        _SidebarItem(icon: Icons.travel_explore_outlined, title: 'SEO & Performance', path: '/admin/seo', colors: colors),
        _SidebarSectionHeader(title: 'Storefront Studio', colors: colors),
        _SidebarItem(icon: Icons.tab_outlined, title: 'Header & Navigation', path: '/admin/navigation', colors: colors),
        _SidebarItem(icon: Icons.palette_outlined, title: 'Theme & Colors', path: '/admin/theme', colors: colors),
        _SidebarItem(icon: Icons.view_column_outlined, title: 'Footer & Socials', path: '/admin/footer', colors: colors),
        _SidebarItem(icon: Icons.description_outlined, title: 'Custom Pages', path: '/admin/custom-pages', colors: colors),
        _SidebarItem(icon: Icons.settings_outlined, title: 'Homepage CMS', path: '/admin/settings', colors: colors),
      ]);
    }

    // Designer: products, collections, lookbook, journal, customers, orders, custom requests, appointments, inventory, media
    else if (role == UserRole.designer) {
      items.addAll([
        _SidebarItem(icon: Icons.dashboard_outlined, title: 'Dashboard', path: '/admin', colors: colors),
        _SidebarItem(icon: Icons.shopping_bag_outlined, title: 'Orders', path: '/admin/orders', colors: colors),
        _SidebarItem(icon: Icons.design_services_outlined, title: 'Custom Requests', path: '/admin/custom-requests', colors: colors),
        _SidebarItem(icon: Icons.calendar_today_outlined, title: 'Appointments', path: '/admin/appointments', colors: colors),
        _SidebarItem(icon: Icons.people_outline, title: 'Customers', path: '/admin/customers', colors: colors),
        _SidebarItem(icon: Icons.checkroom_outlined, title: 'Products', path: '/admin/products', colors: colors),
        _SidebarItem(icon: Icons.collections_outlined, title: 'Collections', path: '/admin/collections', colors: colors),
        _SidebarItem(icon: Icons.auto_stories_outlined, title: 'Lookbook', path: '/admin/lookbook', colors: colors),
        _SidebarItem(icon: Icons.article_outlined, title: 'Journal', path: '/admin/journal', colors: colors),
        _SidebarItem(icon: Icons.inventory_2_outlined, title: 'Inventory', path: '/admin/inventory', colors: colors),
        _SidebarItem(icon: Icons.perm_media_outlined, title: 'Media', path: '/admin/media', colors: colors),
        _SidebarItem(icon: Icons.travel_explore_outlined, title: 'SEO & Performance', path: '/admin/seo', colors: colors),
      ]);
    }
    // Production Staff: orders + production status + inventory
    else if (role == UserRole.productionStaff) {
      items.addAll([
        _SidebarItem(icon: Icons.shopping_bag_outlined, title: 'Orders (Production)', path: '/admin/orders', colors: colors),
        _SidebarItem(icon: Icons.inventory_2_outlined, title: 'Inventory & Materials', path: '/admin/inventory', colors: colors),
      ]);
    }
    // Front Desk: appointments + customers
    else if (role == UserRole.frontDesk) {
      items.addAll([
        _SidebarItem(icon: Icons.calendar_today_outlined, title: 'Appointments & Salon', path: '/admin/appointments', colors: colors),
        _SidebarItem(icon: Icons.people_outline, title: 'Client Directory', path: '/admin/customers', colors: colors),
      ]);
    }
    // Content Manager: products, collections, lookbook, journal, media
    else if (role == UserRole.contentManager) {
      items.addAll([
        _SidebarItem(icon: Icons.checkroom_outlined, title: 'Products', path: '/admin/products', colors: colors),
        _SidebarItem(icon: Icons.collections_outlined, title: 'Collections', path: '/admin/collections', colors: colors),
        _SidebarItem(icon: Icons.auto_stories_outlined, title: 'Lookbook', path: '/admin/lookbook', colors: colors),
        _SidebarItem(icon: Icons.article_outlined, title: 'Journal Articles', path: '/admin/journal', colors: colors),
        _SidebarItem(icon: Icons.perm_media_outlined, title: 'Media Assets', path: '/admin/media', colors: colors),
      ]);
    }

    return items;
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String path;
  final AppColorTokens colors;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.path,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final isSelected = currentPath == path || (path != '/admin' && currentPath.startsWith(path));

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      leading: Icon(
        icon,
        size: 18,
        color: isSelected ? colors.primaryText : colors.secondaryText,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? colors.primaryText : colors.secondaryText,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedTileColor: colors.surfaceVariant,
      onTap: () {
        context.go(path);
        if (MediaQuery.of(context).size.width < 1440) {
          // If drawer is open on smaller screen
          final scaffold = Scaffold.maybeOf(context);
          if (scaffold?.isDrawerOpen ?? false) {
            Navigator.pop(context);
          }
        }
      },
    );
  }
}

class _SidebarSectionHeader extends StatelessWidget {
  final String title;
  final AppColorTokens colors;

  const _SidebarSectionHeader({
    required this.title,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 16, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colors.accentVariant,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

