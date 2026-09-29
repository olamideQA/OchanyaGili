import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';
import 'package:ochanya_gili/features/account/data/customer_account_repository.dart';
import 'package:ochanya_gili/features/account/domain/models/customer_account_models.dart';
import 'package:ochanya_gili/features/orders/domain/models/order.dart';
import 'package:ochanya_gili/features/appointments/domain/models/appointment.dart';
import 'package:ochanya_gili/features/custom_atelier/domain/models/custom_request.dart';

class CustomerDashboardScreen extends ConsumerWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: userAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: colors.primaryText)),
        error: (e, _) => Center(child: Text('Error loading account: $e')),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                'Please sign in to access your atelier account.',
                style: TextStyle(color: colors.primaryText),
              ),
            );
          }

          final overviewAsync =
              ref.watch(customerDashboardOverviewProvider(user.id));

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Editorial Greeting
                    _buildGreeting(user.name, colors),
                    const SizedBox(height: 28),

                    overviewAsync.when(
                      loading: () => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: CircularProgressIndicator(
                              color: colors.primaryText),
                        ),
                      ),
                      error: (e, _) => Container(
                        padding: const EdgeInsets.all(16),
                        color: colors.error.withValues(alpha: 0.1),
                        child: Text('Failed to load overview: $e',
                            style: TextStyle(color: colors.error)),
                      ),
                      data: (overview) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Metric Counters Row
                            _buildMetricsRow(overview, colors, context),
                            const SizedBox(height: 32),

                            // Active Order Section
                            if (overview.latestOrder != null &&
                                overview.latestOrder!.status.isActive) ...[
                              _buildSubHeader('ACTIVE ATELIER ORDER', colors),
                              const SizedBox(height: 12),
                              _buildActiveOrderCard(
                                  context, overview.latestOrder!, colors),
                              const SizedBox(height: 28),
                            ],

                            // Next Appointment Section
                            if (overview.nextAppointment != null) ...[
                              _buildSubHeader(
                                  'UPCOMING ATELIER APPOINTMENT', colors),
                              const SizedBox(height: 12),
                              _buildNextAppointmentCard(
                                  context, overview.nextAppointment!, colors),
                              const SizedBox(height: 28),
                            ],

                            // Latest Bespoke Commission Request
                            if (overview.latestCustomRequest != null) ...[
                              _buildSubHeader(
                                  'LATEST BESPOKE COMMISSION', colors),
                              const SizedBox(height: 12),
                              _buildCustomRequestCard(context,
                                  overview.latestCustomRequest!, colors),
                              const SizedBox(height: 28),
                            ],

                            // Quick Atelier Shortcuts
                            _buildSubHeader('ATELIER SERVICES & ACCESS', colors),
                            const SizedBox(height: 12),
                            _buildQuickActionsGrid(context, colors),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreeting(String name, AppColorTokens colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'OCHANYA GILI PRIVÉ',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2.5,
                color: colors.accentVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              color: colors.accentVariant.withValues(alpha: 0.15),
              child: Text(
                'ATELIER CLIENT',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.bold,
                  color: colors.accentVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Welcome, $name',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colors.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your bespoke commissions, private fittings, measurements, and order journeys.',
          style: TextStyle(fontSize: 13, color: colors.secondaryText),
        ),
      ],
    );
  }

  Widget _buildSubHeader(String title, AppColorTokens colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 2.0,
        fontWeight: FontWeight.bold,
        color: colors.secondaryText,
      ),
    );
  }

  Widget _buildMetricsRow(CustomerDashboardOverview overview,
      AppColorTokens colors, BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;
        final items = [
          _MetricItem(
            label: 'ACTIVE ORDERS',
            value: '${overview.activeOrdersCount}',
            icon: Icons.inventory_2_outlined,
            route: '/account/orders',
          ),
          _MetricItem(
            label: 'BESPOKE COMMISSIONS',
            value: '${overview.customRequestsCount}',
            icon: Icons.design_services_outlined,
            route: '/account/custom-requests',
          ),
          _MetricItem(
            label: 'UPCOMING SESSIONS',
            value: '${overview.upcomingAppointmentsCount}',
            icon: Icons.calendar_today_outlined,
            route: '/account/appointments',
          ),
          _MetricItem(
            label: 'SAVED LOOKS',
            value: '${overview.savedLooksCount}',
            icon: Icons.favorite_border,
            route: '/account/wishlist',
          ),
        ];

        if (isNarrow) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: items.map((m) => _buildMetricCard(m, colors, context)).toList(),
          );
        }

        return Row(
          children: items
              .map((m) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _buildMetricCard(m, colors, context),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildMetricCard(
      _MetricItem item, AppColorTokens colors, BuildContext context) {
    return InkWell(
      onTap: () => context.go(item.route),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(item.icon, size: 18, color: colors.secondaryText),
                Icon(Icons.arrow_forward, size: 14, color: colors.border),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.value,
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.primaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
                color: colors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard(
      BuildContext context, AppOrder order, AppColorTokens colors) {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.accentVariant, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: colors.surfaceVariant,
            child: Icon(Icons.inventory_2, color: colors.accentVariant, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Order ${order.orderNumber}',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusChip(order.status.displayName, colors.accentVariant, colors),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Placed on ${DateFormat('MMMM d, yyyy').format(order.createdAt)} • ${currencyFormat.format(order.total)}',
                  style: TextStyle(fontSize: 12, color: colors.secondaryText),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stage: ${order.status.stageNumber} of 6  —  ${order.status.displayName}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.primaryText,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
            onPressed: () =>
                context.go('/account/orders/${order.orderNumber}'),
            child: const Text(
              'TRACK TIMELINE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextAppointmentCard(
      BuildContext context, Appointment appt, AppColorTokens colors) {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(appt.scheduledDate);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: colors.surfaceVariant,
            child: Icon(Icons.event, color: colors.accent, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      appt.type?.name ?? 'Atelier Consultation',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusChip(
                      appt.status.displayName,
                      appt.status == AppointmentStatus.confirmed
                          ? colors.success
                          : colors.warning,
                      colors,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr  •  ${appt.startTime} – ${appt.endTime}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.primaryText),
                ),
                const SizedBox(height: 2),
                Text(
                  appt.bookingFeePaid ? 'Booking Fee Paid' : 'Fee Pending',
                  style: TextStyle(fontSize: 11, color: colors.secondaryText),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primaryText,
              side: BorderSide(color: colors.border),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
            onPressed: () => context.go('/account/appointments'),
            child: const Text(
              'VIEW CALENDAR',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRequestCard(
      BuildContext context, CustomRequest req, AppColorTokens colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: colors.surfaceVariant,
            child: Icon(Icons.auto_awesome, color: colors.accentVariant, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      req.requestNumber,
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusChip(req.status.displayName, colors.accentVariant, colors),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${req.occasion} • ${req.direction} • ${req.fabric}',
                  style: TextStyle(fontSize: 12, color: colors.secondaryText),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
            onPressed: () =>
                context.go('/account/custom-requests/${req.id}'),
            child: const Text(
              'VIEW PROPOSAL',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, AppColorTokens colors) {
    final actions = [
      _QuickAction(
        title: 'Book a Fitting',
        subtitle: 'Schedule private session',
        icon: Icons.calendar_month,
        route: '/account/appointments/book',
      ),
      _QuickAction(
        title: 'Create Your Look',
        subtitle: 'Bespoke couture wizard',
        icon: Icons.draw_outlined,
        route: '/account/custom-requests/new',
      ),
      _QuickAction(
        title: 'My Measurements',
        subtitle: '18-point anatomical profile',
        icon: Icons.straighten,
        route: '/account/measurements',
      ),
      _QuickAction(
        title: 'Delivery Addresses',
        subtitle: 'Manage saved locations',
        icon: Icons.location_on_outlined,
        route: '/account/addresses',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: actions.map((a) {
        return InkWell(
          onTap: () => context.go(a.route),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(a.icon, color: colors.accentVariant, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        a.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.subtitle,
                        style: TextStyle(
                            fontSize: 11, color: colors.secondaryText),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: colors.border),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusChip(
      String label, Color accentColor, AppColorTokens colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: accentColor.withValues(alpha: 0.15),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 1.0,
          fontWeight: FontWeight.bold,
          color: accentColor,
        ),
      ),
    );
  }
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;
  final String route;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.route,
  });
}

class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}
