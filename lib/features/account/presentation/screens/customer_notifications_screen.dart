import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';
import 'package:ochanya_gili/features/account/data/customer_account_repository.dart';
import 'package:ochanya_gili/features/account/domain/models/customer_account_models.dart';

class CustomerNotificationsScreen extends ConsumerWidget {
  const CustomerNotificationsScreen({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'order':
        return Icons.local_shipping_outlined;
      case 'custom_request':
        return Icons.auto_awesome;
      case 'appointment':
        return Icons.calendar_today_outlined;
      case 'payment':
        return Icons.payments_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  void _handleNotificationTap(BuildContext context, WidgetRef ref,
      CustomerNotification notif, String userId) async {
    if (!notif.isRead) {
      final repo = ref.read(customerAccountRepositoryProvider);
      await repo.markNotificationRead(notif.id);
      ref.invalidate(customerNotificationsProvider(userId));
      ref.invalidate(customerDashboardOverviewProvider(userId));
    }

    if (!context.mounted) return;

    if (notif.referenceType == 'appointment') {
      context.go('/account/appointments');
    } else if (notif.referenceType == 'custom_request' &&
        notif.referenceId != null) {
      context.go('/account/custom-requests/${notif.referenceId}');
    } else if (notif.referenceType == 'order') {
      context.go('/account/orders');
    }
  }

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
              child: Text('Please sign in to view your notifications.',
                  style: TextStyle(color: colors.primaryText)),
            );
          }

          final notificationsAsync =
              ref.watch(customerNotificationsProvider(user.id));

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
                              'COMMUNICATIONS',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 2.5,
                                color: colors.accentVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Atelier Notifications',
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colors.primaryText,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final repo =
                                ref.read(customerAccountRepositoryProvider);
                            await repo.markAllNotificationsRead(user.id);
                            ref.invalidate(
                                customerNotificationsProvider(user.id));
                            ref.invalidate(
                                customerDashboardOverviewProvider(user.id));
                          },
                          icon: const Icon(Icons.done_all, size: 16),
                          label: const Text('MARK ALL READ'),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.accentVariant,
                            textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    notificationsAsync.when(
                      loading: () => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: CircularProgressIndicator(
                              color: colors.primaryText),
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Text('Error loading notifications: $e',
                            style: TextStyle(color: colors.error)),
                      ),
                      data: (notifications) {
                        if (notifications.isEmpty) {
                          return _buildEmptyState(colors);
                        }

                        return Column(
                          children: notifications.map((notif) {
                            return _buildNotificationCard(
                                context, ref, notif, colors, user.id);
                          }).toList(),
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

  Widget _buildEmptyState(AppColorTokens colors) {
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
          Icon(Icons.notifications_none, size: 48, color: colors.secondaryText),
          const SizedBox(height: 16),
          Text(
            'All Caught Up',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no new notifications from the atelier.',
            style: TextStyle(fontSize: 13, color: colors.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    CustomerNotification notif,
    AppColorTokens colors,
    String userId,
  ) {
    final dateStr =
        DateFormat('MMM d, yyyy  •  h:mm a').format(notif.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notif.isRead
            ? colors.surface
            : colors.surfaceVariant.withValues(alpha: 0.5),
        border: Border.all(
          color: notif.isRead ? colors.border : colors.accentVariant,
          width: notif.isRead ? 1 : 1.5,
        ),
      ),
      child: InkWell(
        onTap: () =>
            _handleNotificationTap(context, ref, notif, userId),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  border: Border.all(color: colors.border),
                ),
                child: Icon(_iconForType(notif.type),
                    size: 20, color: colors.accentVariant),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notif.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: colors.primaryText,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                              fontSize: 11, color: colors.secondaryText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.primaryText.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notif.isRead) ...[
                const SizedBox(width: 12),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accentVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
