import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';
import 'package:ochanya_gili/features/appointments/data/appointments_repository.dart';
import 'package:ochanya_gili/features/appointments/domain/models/appointment.dart';

class CustomerAppointmentsScreen extends ConsumerWidget {
  const CustomerAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: userAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: colors.primaryText)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                'Please sign in to view your atelier appointments.',
                style: TextStyle(color: colors.primaryText),
              ),
            );
          }

          final appointmentsAsync =
              ref.watch(customerAppointmentsProvider(user.id));

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ATELIER CALENDAR',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 2.5,
                                color: colors.accentVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'My Appointments',
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colors.primaryText,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.go('/account/appointments/book'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('BOOK NEW APPOINTMENT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: colors.onAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                            textStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    appointmentsAsync.when(
                      loading: () => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: CircularProgressIndicator(
                              color: colors.primaryText),
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Text('Error loading appointments: $e',
                            style: TextStyle(color: colors.error)),
                      ),
                      data: (appointments) {
                        if (appointments.isEmpty) {
                          return _buildEmptyState(context, colors);
                        }

                        final upcoming =
                            appointments.where((a) => a.isUpcoming).toList();
                        final past =
                            appointments.where((a) => !a.isUpcoming).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (upcoming.isNotEmpty) ...[
                              _buildSubHeader('UPCOMING APPOINTMENTS', colors),
                              const SizedBox(height: 16),
                              ...upcoming.map((appt) =>
                                  _buildAppointmentCard(context, ref, appt, colors, user.id)),
                              const SizedBox(height: 36),
                            ],
                            if (past.isNotEmpty) ...[
                              _buildSubHeader('PAST APPOINTMENTS', colors),
                              const SizedBox(height: 16),
                              ...past.map((appt) =>
                                  _buildAppointmentCard(context, ref, appt, colors, user.id)),
                            ],
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

  Widget _buildEmptyState(BuildContext context, AppColorTokens colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 48, color: colors.secondaryText),
          const SizedBox(height: 16),
          Text(
            'No Appointments Scheduled',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Schedule a private style consultation, measurement session, or fitting with our master atelier team.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.secondaryText),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/account/appointments/book'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
            child: const Text(
              'SCHEDULE A SESSION',
              style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    WidgetRef ref,
    Appointment appt,
    AppColorTokens colors,
    String userId,
  ) {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(appt.scheduledDate);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appt.type?.name ?? 'Atelier Session',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateStr  •  ${appt.startTime} – ${appt.endTime}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(appt.status, colors),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: colors.secondaryText),
                  const SizedBox(width: 6),
                  Text(
                    '${appt.type?.durationMinutes ?? 60} mins',
                    style: TextStyle(fontSize: 12, color: colors.secondaryText),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    appt.bookingFeePaid
                        ? Icons.check_circle_outline
                        : Icons.hourglass_empty,
                    size: 14,
                    color: appt.bookingFeePaid
                        ? colors.success
                        : colors.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    appt.type?.hasFee ?? false
                        ? (appt.bookingFeePaid
                            ? 'Fee Paid (${currencyFormat.format(appt.type!.bookingFee)})'
                            : 'Fee Pending (${currencyFormat.format(appt.type!.bookingFee)})')
                        : 'Complimentary',
                    style: TextStyle(
                      fontSize: 12,
                      color: appt.bookingFeePaid
                          ? colors.success
                          : colors.secondaryText,
                    ),
                  ),
                ],
              ),
              if (appt.isUpcoming && appt.status != AppointmentStatus.cancelled)
                TextButton(
                  onPressed: () =>
                      _confirmCancellation(context, ref, appt, colors, userId),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.error,
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('CANCEL APPOINTMENT'),
                ),
            ],
          ),
          if (appt.notes != null && appt.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Notes: ${appt.notes}',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: colors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AppointmentStatus status, AppColorTokens colors) {
    Color bg;
    Color fg;

    switch (status) {
      case AppointmentStatus.confirmed:
        bg = colors.success.withValues(alpha: 0.15);
        fg = colors.success;
        break;
      case AppointmentStatus.pendingPayment:
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange.shade800;
        break;
      case AppointmentStatus.completed:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade800;
        break;
      case AppointmentStatus.cancelled:
        bg = colors.error.withValues(alpha: 0.15);
        fg = colors.error;
        break;
      case AppointmentStatus.noShow:
        bg = colors.secondaryText.withValues(alpha: 0.15);
        fg = colors.secondaryText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: bg,
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: fg,
        ),
      ),
    );
  }

  void _confirmCancellation(
    BuildContext context,
    WidgetRef ref,
    Appointment appt,
    AppColorTokens colors,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'CANCEL APPOINTMENT',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: colors.primaryText,
          ),
        ),
        content: Text(
          'Are you sure you wish to cancel your ${appt.type?.name ?? 'session'} on ${DateFormat('MMMM d').format(appt.scheduledDate)}?',
          style: TextStyle(color: colors.primaryText, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('KEEP', style: TextStyle(color: colors.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final repo = ref.read(appointmentsRepositoryProvider);
              await repo.cancelAppointment(appt.id);
              ref.invalidate(customerAppointmentsProvider(userId));
            },
            child: const Text('CANCEL SESSION'),
          ),
        ],
      ),
    );
  }
}
