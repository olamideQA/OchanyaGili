import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/shell/presentation/widgets/admin_sidebar.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final isDesktop = MediaQuery.of(context).size.width >= 1440; // Desktop breakpoint

    return Scaffold(
      backgroundColor: colors.background,
      appBar: isDesktop ? null : AppBar(
        title: Text('Admin Panel', style: TextStyle(color: colors.text)),
        backgroundColor: colors.surface,
        iconTheme: IconThemeData(color: colors.text),
      ),
      drawer: isDesktop ? null : const AdminSidebar(),
      body: Row(
        children: [
          if (isDesktop) const AdminSidebar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}
