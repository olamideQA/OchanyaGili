import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/core/router/app_router.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/cms/data/cms_repository.dart';

class OchanyaGiliApp extends ConsumerWidget {
  const OchanyaGiliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeTokensAsync = ref.watch(dynamicThemeTokensProvider);
    final brandHeaderAsync = ref.watch(brandHeaderProvider);

    final appTokens = themeTokensAsync.whenOrNull(
      data: (tokens) => tokens.toAppColorTokens(),
    );
    final brandName = brandHeaderAsync.whenOrNull(
      data: (header) => header.brandName,
    ) ?? 'Ochanya Gili';

    return MaterialApp.router(
      title: brandName,
      theme: AppTheme.buildTheme(appTokens),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

