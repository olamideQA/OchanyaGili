import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ochanya_gili/features/shell/presentation/screens/public_shell.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/cart/presentation/providers/cart_provider.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';
import 'package:ochanya_gili/features/cms/domain/models/brand_header.dart';
import 'package:ochanya_gili/features/cms/domain/models/navigation_item.dart';

class NavBar extends ConsumerWidget implements PreferredSizeWidget {
  const NavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    const navBreakpoint = 1024.0;
    final isDesktop = screenWidth >= navBreakpoint;

    final brandHeaderAsync = ref.watch(brandHeaderProvider);
    final brandHeader = brandHeaderAsync.value ?? const BrandHeader();

    final navItemsAsync = ref.watch(navigationItemsProvider);
    final navItems = navItemsAsync.value ?? const [
      NavigationItem(id: 'nav-1', title: 'Collections', path: '/collections', sortOrder: 0),
      NavigationItem(id: 'nav-2', title: 'Shop', path: '/shop', sortOrder: 1),
      NavigationItem(id: 'nav-3', title: 'Lookbook', path: '/lookbook', sortOrder: 2),
      NavigationItem(id: 'nav-4', title: 'Journal', path: '/journal', sortOrder: 3),
      NavigationItem(id: 'nav-5', title: 'About', path: '/about', sortOrder: 4),
      NavigationItem(id: 'nav-6', title: 'Contact', path: '/contact', sortOrder: 5),
    ];
    final visibleNavItems = navItems.where((item) => item.isVisible).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return AppBar(
      backgroundColor: colors.surface,
      elevation: 0,
      titleSpacing: 24,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => context.go('/'),
            child: brandHeader.logoUrl.isNotEmpty
                ? Image.network(
                    brandHeader.logoUrl,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Text(
                      brandHeader.brandName,
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        color: colors.text,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        fontSize: 18,
                      ),
                    ),
                  )
                : Text(
                    brandHeader.brandName,
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      color: colors.text,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      fontSize: 18,
                    ),
                  ),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 32),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final item in visibleNavItems)
                      _NavLink(
                        title: item.title,
                        path: item.path,
                        isExternal: item.isExternal,
                        colors: colors,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: colors.text),
          tooltip: 'Search the catalogue',
          onPressed: () => context.go('/shop'),
        ),
        IconButton(
          icon: Icon(Icons.person_outline, color: colors.text),
          onPressed: () => context.go('/login'),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.shopping_bag_outlined, color: colors.text),
              onPressed: () => context.go('/cart'),
            ),
            Consumer(
              builder: (context, ref, _) {
                final cartState = ref.watch(cartNotifierProvider);
                if (cartState.isEmpty) return const SizedBox.shrink();
                return Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.accentVariant,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        '${cartState.totalCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        if (!isDesktop)
          IconButton(
            icon: Icon(Icons.menu, color: colors.text),
            onPressed: () {
              PublicShell.scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        const SizedBox(width: 12),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  final String title;
  final String path;
  final bool isExternal;
  final AppColorTokens colors;

  const _NavLink({
    required this.title,
    required this.path,
    this.isExternal = false,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: InkWell(
        onTap: () async {
          if (isExternal || path.startsWith('http://') || path.startsWith('https://')) {
            final uri = Uri.tryParse(path);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } else {
            context.go(path);
          }
        },
        child: Text(
          title,
          style: TextStyle(
            color: colors.text,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
