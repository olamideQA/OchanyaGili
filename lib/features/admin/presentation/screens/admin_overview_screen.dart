import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/admin/data/admin_repository.dart';
import 'package:ochanya_gili/features/admin/domain/models/admin_dashboard_models.dart';
import 'package:ochanya_gili/features/analytics/data/analytics_repository.dart';
import 'package:ochanya_gili/features/analytics/domain/models/analytics_metrics.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final metricsAsync = ref.watch(adminDashboardMetricsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final currencyFormatter = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ATELIER COMMAND & OVERVIEW',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Executive dashboard, live commissions & production tracking',
                      style: TextStyle(color: colors.secondaryText, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (user != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.accentVariant.withValues(alpha: 0.15),
                          border: Border.all(color: colors.accentVariant.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          user.role.name.toUpperCase().replaceAllMapped(
                                RegExp(r'[A-Z]'),
                                (m) => ' ${m[0]}',
                              ).trim(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: colors.primaryText,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.invalidate(adminDashboardMetricsProvider);
                        ref.invalidate(analyticsMetricsProvider);
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('REFRESH'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryText,
                        side: BorderSide(color: colors.border),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            metricsAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: CircularProgressIndicator(color: colors.primaryText),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text('Error loading dashboard: $err', style: TextStyle(color: colors.error)),
                ),
              ),
              data: (metrics) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 4 Today's Metric Cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 900;
                        return GridView.count(
                          crossAxisCount: isWide ? 4 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isWide ? 2.1 : 1.8,
                          children: [
                            _MetricCard(
                              title: "TODAY'S REVENUE",
                              value: currencyFormatter.format(metrics.todayRevenue),
                              icon: Icons.payments_outlined,
                              colors: colors,
                              accentColor: colors.accentVariant,
                            ),
                            _MetricCard(
                              title: "TODAY'S ORDERS",
                              value: '${metrics.todayOrders}',
                              icon: Icons.shopping_bag_outlined,
                              colors: colors,
                              onTap: () => context.go('/admin/orders'),
                            ),
                            _MetricCard(
                              title: 'NEW CUSTOM REQUESTS',
                              value: '${metrics.todayCustomRequests}',
                              icon: Icons.design_services_outlined,
                              colors: colors,
                              onTap: () => context.go('/admin/custom-requests'),
                            ),
                            _MetricCard(
                              title: "TODAY'S APPOINTMENTS",
                              value: '${metrics.todayAppointments}',
                              icon: Icons.calendar_today_outlined,
                              colors: colors,
                              onTap: () => context.go('/admin/appointments'),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Production Pipeline Funnel
                    _buildPipelineFunnel(context, metrics, colors),
                    const SizedBox(height: 32),

                    // Atelier Analytics & Conversion Intelligence (Loop 14)
                    _buildAnalyticsSection(context, ref, colors),
                    const SizedBox(height: 32),

                    // Tables Section: Recent Orders & Custom Requests
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 1100;
                        if (isDesktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildRecentOrdersCard(context, metrics, colors, currencyFormatter)),
                              const SizedBox(width: 24),
                              Expanded(flex: 2, child: _buildRecentRequestsCard(context, metrics, colors)),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildRecentOrdersCard(context, metrics, colors, currencyFormatter),
                              const SizedBox(height: 24),
                              _buildRecentRequestsCard(context, metrics, colors),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Upcoming Appointments Card
                    _buildUpcomingAppointmentsCard(context, metrics, colors),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineFunnel(BuildContext context, AdminDashboardMetrics metrics, AppColorTokens colors) {
    final stages = [
      (
        '1. REQUESTS',
        metrics.pipelineRequests,
        'Submitted & Review',
        Icons.inbox_outlined,
        '/admin/custom-requests',
      ),
      (
        '2. QUOTED',
        metrics.pipelineQuoted,
        'Quotes Pending Client',
        Icons.request_quote_outlined,
        '/admin/custom-requests',
      ),
      (
        '3. PRODUCTION',
        metrics.pipelineProduction,
        'Active In Atelier',
        Icons.cut_outlined,
        '/admin/orders',
      ),
      (
        '4. FITTING',
        metrics.pipelineFitting,
        'Ready & Scheduled',
        Icons.accessibility_new_outlined,
        '/admin/appointments',
      ),
      (
        '5. READY / DELIVERED',
        metrics.pipelineReady,
        'Dispatched & Done',
        Icons.task_alt_outlined,
        '/admin/orders',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRODUCTION PIPELINE FUNNEL',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colors.primaryText,
                ),
              ),
              Text(
                'Full Atelier Lifecycle Slices',
                style: TextStyle(fontSize: 12, color: colors.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return isWide
                  ? Row(
                      children: stages
                          .map(
                            (s) => Expanded(
                              child: _FunnelStageWidget(
                                title: s.$1,
                                count: s.$2,
                                subtitle: s.$3,
                                icon: s.$4,
                                onTap: () => context.go(s.$5),
                                colors: colors,
                              ),
                            ),
                          )
                          .toList(),
                    )
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: stages
                          .map(
                            (s) => SizedBox(
                              width: (constraints.maxWidth - 24) / 2,
                              child: _FunnelStageWidget(
                                title: s.$1,
                                count: s.$2,
                                subtitle: s.$3,
                                icon: s.$4,
                                onTap: () => context.go(s.$5),
                                colors: colors,
                              ),
                            ),
                          )
                          .toList(),
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersCard(
    BuildContext context,
    AdminDashboardMetrics metrics,
    AppColorTokens colors,
    NumberFormat currency,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT COMMISSIONS',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colors.primaryText,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/admin/orders'),
                child: Text('VIEW ALL', style: TextStyle(color: colors.primaryText, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (metrics.recentOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No commissions recorded yet.', style: TextStyle(color: colors.secondaryText)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.recentOrders.length,
              separatorBuilder: (context, index) => Divider(color: colors.border, height: 1),
              itemBuilder: (context, index) {
                final o = metrics.recentOrders[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                  title: Row(
                    children: [
                      Text(
                        o.orderNumber,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.primaryText),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: colors.surfaceVariant,
                        child: Text(
                          o.status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.primaryText),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${o.customerName} • ${DateFormat('dd MMM, HH:mm').format(o.createdAt)}',
                    style: TextStyle(fontSize: 12, color: colors.secondaryText),
                  ),
                  trailing: Text(
                    currency.format(o.total),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.primaryText),
                  ),
                  onTap: () => context.go('/admin/orders'),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentRequestsCard(BuildContext context, AdminDashboardMetrics metrics, AppColorTokens colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BESPOKE INQUIRIES',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colors.primaryText,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/admin/custom-requests'),
                child: Text('VIEW ALL', style: TextStyle(color: colors.primaryText, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (metrics.recentRequests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No bespoke inquiries pending.', style: TextStyle(color: colors.secondaryText)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.recentRequests.length,
              separatorBuilder: (context, index) => Divider(color: colors.border, height: 1),
              itemBuilder: (context, index) {
                final r = metrics.recentRequests[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                  title: Text(
                    r.garmentType.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.primaryText),
                  ),
                  subtitle: Text(
                    '${r.customerName} • ${r.requestNumber}',
                    style: TextStyle(fontSize: 12, color: colors.secondaryText),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.accentVariant.withValues(alpha: 0.15),
                      border: Border.all(color: colors.accentVariant.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      r.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.primaryText),
                    ),
                  ),
                  onTap: () => context.go('/admin/custom-requests'),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointmentsCard(BuildContext context, AdminDashboardMetrics metrics, AppColorTokens colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UPCOMING SALON FITTINGS & CONSULTATIONS',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colors.primaryText,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/admin/appointments'),
                child: Text('MANAGE APPOINTMENTS', style: TextStyle(color: colors.primaryText, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (metrics.upcomingAppointments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No upcoming appointments scheduled.', style: TextStyle(color: colors.secondaryText)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.upcomingAppointments.length,
              separatorBuilder: (context, index) => Divider(color: colors.border, height: 1),
              itemBuilder: (context, index) {
                final a = metrics.upcomingAppointments[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    color: colors.surfaceVariant,
                    child: Icon(Icons.event, size: 20, color: colors.primaryText),
                  ),
                  title: Text(
                    a.customerName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.primaryText),
                  ),
                  subtitle: Text(
                    '${a.appointmentType} • ${DateFormat('EEE, dd MMM yyyy').format(a.date)} at ${a.startTime}',
                    style: TextStyle(fontSize: 12, color: colors.secondaryText),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: a.status == 'confirmed'
                        ? colors.success.withValues(alpha: 0.1)
                        : colors.surfaceVariant,
                    child: Text(
                      a.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: a.status == 'confirmed' ? colors.success : colors.primaryText,
                      ),
                    ),
                  ),
                  onTap: () => context.go('/admin/appointments'),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(
    BuildContext context,
    WidgetRef ref,
    AppColorTokens colors,
  ) {
    final analyticsAsync = ref.watch(analyticsMetricsProvider);

    return analyticsAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: CircularProgressIndicator(color: colors.primaryText),
          ),
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (analytics) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'ATELIER ANALYTICS & CONVERSION INTELLIGENCE',
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        color: colors.accentVariant.withValues(alpha: 0.15),
                        child: Text(
                          'REAL-TIME',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            color: colors.accentVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${analytics.totalPageViews} Impressions',
                    style: TextStyle(fontSize: 12, color: colors.secondaryText),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Funnel + Intake Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 950;
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildEcommerceFunnelCard(context, analytics, colors),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: _buildConversionSummaryCard(context, analytics, colors),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildEcommerceFunnelCard(context, analytics, colors),
                        const SizedBox(height: 20),
                        _buildConversionSummaryCard(context, analytics, colors),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // Demand & Search Insights Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 1000;
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildPopularProductsCard(context, analytics, colors),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildPopularCollectionsCard(context, analytics, colors),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildTopSearchesCard(context, analytics, colors),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildPopularProductsCard(context, analytics, colors),
                        const SizedBox(height: 20),
                        _buildPopularCollectionsCard(context, analytics, colors),
                        const SizedBox(height: 20),
                        _buildTopSearchesCard(context, analytics, colors),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEcommerceFunnelCard(
    BuildContext context,
    AnalyticsFunnelMetrics analytics,
    AppColorTokens colors,
  ) {
    final stages = [
      ('1. VIEWS', analytics.totalProductViews, 'Product Views', Icons.visibility_outlined),
      ('2. BAG', analytics.totalCartAdditions, '${analytics.cartConversionRate.toStringAsFixed(1)}% of views', Icons.shopping_bag_outlined),
      ('3. CHECKOUT', analytics.checkoutsStarted, 'Checkout Initiated', Icons.shopping_cart_checkout_outlined),
      ('4. PURCHASE', analytics.purchasesCompleted, '${analytics.checkoutConversionRate.toStringAsFixed(1)}% checkouts', Icons.task_alt_outlined),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'E-COMMERCE CONVERSION FUNNEL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: colors.primaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accentVariant.withValues(alpha: 0.15),
                  border: Border.all(color: colors.accentVariant.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '${analytics.conversionRate.toStringAsFixed(1)}% Conversion',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 550;
              return GridView.count(
                crossAxisCount: isSmall ? 2 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: isSmall ? 2.0 : 1.5,
                children: stages.map((s) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.$1,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: colors.secondaryText,
                              ),
                            ),
                            Icon(s.$4, size: 14, color: colors.accentVariant),
                          ],
                        ),
                        Text(
                          '${s.$2}',
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryText,
                          ),
                        ),
                        Text(
                          s.$3,
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConversionSummaryCard(
    BuildContext context,
    AnalyticsFunnelMetrics analytics,
    AppColorTokens colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INTAKE & CLIENT RETENTION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 14),
          _IntakeRow(
            title: 'Custom Commissions',
            countText: '${analytics.customRequestsCompleted} / ${analytics.customRequestsStarted}',
            rateText: '${analytics.customConversionRate.toStringAsFixed(1)}% Completed',
            icon: Icons.design_services_outlined,
            colors: colors,
          ),
          const Divider(height: 16),
          _IntakeRow(
            title: 'Private Salon Appointments',
            countText: '${analytics.appointmentsCompleted} / ${analytics.appointmentsStarted}',
            rateText: '${analytics.appointmentConversionRate.toStringAsFixed(1)}% Confirmed',
            icon: Icons.calendar_today_outlined,
            colors: colors,
          ),
          const Divider(height: 16),
          _IntakeRow(
            title: 'Patron Retention Rate',
            countText: '${analytics.repeatCustomers} of ${analytics.totalCustomers} Repeat',
            rateText: '${analytics.retentionRate.toStringAsFixed(1)}% Loyalty',
            icon: Icons.loyalty_outlined,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildPopularProductsCard(
    BuildContext context,
    AnalyticsFunnelMetrics analytics,
    AppColorTokens colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOP IN-DEMAND SILHOUETTES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: colors.primaryText,
                ),
              ),
              Icon(Icons.trending_up, size: 16, color: colors.accentVariant),
            ],
          ),
          const SizedBox(height: 12),
          if (analytics.popularProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No product view data yet.',
                  style: TextStyle(fontSize: 11, color: colors.secondaryText),
                ),
              ),
            )
          else
            ...analytics.popularProducts.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final p = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      color: colors.surface,
                      alignment: Alignment.center,
                      child: Text(
                        '$idx',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.primaryText),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.name,
                        style: TextStyle(fontSize: 12, color: colors.primaryText, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: colors.surface,
                      child: Text(
                        '${p.views} views',
                        style: TextStyle(fontSize: 10, color: colors.secondaryText, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPopularCollectionsCard(
    BuildContext context,
    AnalyticsFunnelMetrics analytics,
    AppColorTokens colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOP EXPLORED ANTHOLOGIES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: colors.primaryText,
                ),
              ),
              Icon(Icons.auto_stories_outlined, size: 16, color: colors.accentVariant),
            ],
          ),
          const SizedBox(height: 12),
          if (analytics.popularCollections.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No collection view data yet.',
                  style: TextStyle(fontSize: 11, color: colors.secondaryText),
                ),
              ),
            )
          else
            ...analytics.popularCollections.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final c = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      color: colors.surface,
                      alignment: Alignment.center,
                      child: Text(
                        '$idx',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.primaryText),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.name,
                        style: TextStyle(fontSize: 12, color: colors.primaryText, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: colors.surface,
                      child: Text(
                        '${c.views} views',
                        style: TextStyle(fontSize: 10, color: colors.secondaryText, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTopSearchesCard(
    BuildContext context,
    AnalyticsFunnelMetrics analytics,
    AppColorTokens colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOP SEARCH QUERIES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: colors.primaryText,
                ),
              ),
              Icon(Icons.search, size: 16, color: colors.accentVariant),
            ],
          ),
          const SizedBox(height: 12),
          if (analytics.topSearches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No search queries recorded yet.',
                  style: TextStyle(fontSize: 11, color: colors.secondaryText),
                ),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: analytics.topSearches.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.query,
                        style: TextStyle(fontSize: 11, color: colors.primaryText),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        color: colors.accentVariant.withValues(alpha: 0.2),
                        child: Text(
                          '${s.count}',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.primaryText),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final AppColorTokens colors;
  final Color? accentColor;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.colors,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: colors.secondaryText,
                  ),
                ),
                Icon(icon, size: 20, color: accentColor ?? colors.secondaryText),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FunnelStageWidget extends StatelessWidget {
  final String title;
  final int count;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final AppColorTokens colors;

  const _FunnelStageWidget({
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 18, color: colors.secondaryText),
                Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: colors.primaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: colors.secondaryText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _IntakeRow extends StatelessWidget {
  final String title;
  final String countText;
  final String rateText;
  final IconData icon;
  final AppColorTokens colors;

  const _IntakeRow({
    required this.title,
    required this.countText,
    required this.rateText,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.accentVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primaryText),
              ),
              Text(
                countText,
                style: TextStyle(fontSize: 10, color: colors.secondaryText),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: colors.surface,
          child: Text(
            rateText,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.primaryText),
          ),
        ),
      ],
    );
  }
}

