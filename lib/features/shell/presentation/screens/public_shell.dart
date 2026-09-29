import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/nav_bar.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';
import 'package:ochanya_gili/features/cms/domain/models/brand_header.dart';
import 'package:ochanya_gili/features/cms/domain/models/navigation_item.dart';

class PublicShell extends ConsumerStatefulWidget {
  final Widget child;

  const PublicShell({
    super.key,
    required this.child,
  });

  static final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  ConsumerState<PublicShell> createState() => _PublicShellState();
}

class _PublicShellState extends ConsumerState<PublicShell> {
  bool _dismissedAnnouncement = false;

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/2348080008888?text=Hello%20Ochanya%20Gili%20Atelier');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;

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
    final visibleNavItems = navItems.where((i) => i.isVisible).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final shouldShowAnnouncement = !_dismissedAnnouncement &&
        brandHeader.showAnnouncement &&
        brandHeader.announcementText.isNotEmpty;

    return Scaffold(
      key: PublicShell.scaffoldKey,
      backgroundColor: colors.background,
      appBar: _PublicHeader(
        showAnnouncement: shouldShowAnnouncement,
        announcementText: brandHeader.announcementText,
        onCloseAnnouncement: () => setState(() => _dismissedAnnouncement = true),
      ),
      endDrawer: Drawer(
        backgroundColor: colors.surface,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              ListTile(
                title: Text(
                  brandHeader.brandName,
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    color: colors.text,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.close, color: colors.text),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const Divider(),
              for (final item in visibleNavItems)
                _DrawerLink(
                  title: item.title,
                  path: item.path,
                  isExternal: item.isExternal,
                ),
              const Divider(),
              const _DrawerLink(title: 'Cart', path: '/cart'),
              const _DrawerLink(title: 'Client Sign In', path: '/login'),
            ],
          ),
        ),
      ),
      body: widget.child,
      floatingActionButton: FloatingActionButton(
        onPressed: _openWhatsApp,
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        tooltip: 'Chat on WhatsApp',
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}

/// Dynamic sticky header: customizable announcement bar above the nav.
class _PublicHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool showAnnouncement;
  final String announcementText;
  final VoidCallback onCloseAnnouncement;

  const _PublicHeader({
    required this.showAnnouncement,
    required this.announcementText,
    required this.onCloseAnnouncement,
  });

  @override
  Size get preferredSize => Size.fromHeight(showAnnouncement ? 102.0 : 64.0);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showAnnouncement)
          _AnnouncementBar(
            text: announcementText,
            onClose: onCloseAnnouncement,
          ),
        const SizedBox(height: 64, child: NavBar()),
      ],
    );
  }
}

class _AnnouncementBar extends StatelessWidget {
  final String text;
  final VoidCallback onClose;
  const _AnnouncementBar({required this.text, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          InkWell(
            onTap: onClose,
            child: const Icon(Icons.close, size: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _DrawerLink extends StatelessWidget {
  final String title;
  final String path;
  final bool isExternal;

  const _DrawerLink({
    required this.title,
    required this.path,
    this.isExternal = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    return ListTile(
      title: Text(title, style: TextStyle(color: colors.text, fontSize: 15)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: colors.textMuted),
      onTap: () async {
        Navigator.of(context).pop();
        if (isExternal || path.startsWith('http://') || path.startsWith('https://')) {
          final uri = Uri.tryParse(path);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } else {
          context.go(path);
        }
      },
    );
  }
}
