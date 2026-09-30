import 'package:flutter/material.dart';

class AppBreakpoints {
  static const double mobile = 390;
  static const double tablet = 768;
  static const double desktop = 1440;
  static const double wide = 1920;
}

extension BreakpointExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  
  bool get isMobile => screenWidth < AppBreakpoints.tablet;
  bool get isTablet => screenWidth >= AppBreakpoints.tablet && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;
  bool get isWide => screenWidth >= AppBreakpoints.wide;
}

class ResponsiveBuilder extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;
  final WidgetBuilder? wide;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wide,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isWide && wide != null) {
      return wide!(context);
    }
    if ((context.isDesktop || context.isWide) && desktop != null) {
      return desktop!(context);
    }
    if ((context.isTablet || context.isDesktop || context.isWide) && tablet != null) {
      return tablet!(context);
    }
    return mobile(context);
  }
}
