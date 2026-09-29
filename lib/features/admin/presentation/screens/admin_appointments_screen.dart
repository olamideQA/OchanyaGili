import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/appointments/data/appointments_repository.dart';
import 'package:ochanya_gili/features/appointments/domain/models/appointment.dart';

final adminAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final repo = ref.watch(appointmentsRepositoryProvider);
  return repo.getAllAppointments();
});

class AdminAppointmentsScreen extends ConsumerStatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  ConsumerState<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends ConsumerState<AdminAppointmentsScreen> {
  AppointmentStatus? _selectedStatusFilter;
  DateTime? _selectedDateFilter;
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAppointmentDetailDialog(
      BuildContext context, Appointment appt, AppColorTokens colors) {
    AppointmentStatus targetStatus = appt.status;
    final designerNotesController =
        TextEditingController(text: appt.designerNotes ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APPOINTMENT DETAILS',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${appt.type?.name ?? 'Session'} • ${DateFormat('MMM d, yyyy').format(appt.scheduledDate)} at ${appt.startTime}',
                    style:
                        TextStyle(color: colors.secondaryText, fontSize: 13),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client Information
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: colors.surfaceVariant,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BOOKING SUMMARY',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: colors.accentVariant)),
                            const SizedBox(height: 6),
                            _detailRow('Date',
                                DateFormat('EEEE, MMMM d, yyyy').format(appt.scheduledDate), colors),
                            _detailRow('Time', '${appt.startTime} – ${appt.endTime}', colors),
                            _detailRow('Duration', '${appt.type?.durationMinutes ?? 60} mins', colors),
                            _detailRow(
                              'Fee Status',
                              appt.bookingFeePaid ? 'Paid' : 'Unpaid / Pending',
                              colors,
                              valueColor: appt.bookingFeePaid
                                  ? colors.success
                                  : colors.warning,
                            ),
                            if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _detailRow('Customer Notes', appt.notes!, colors),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Status Selector
                      Text(
                        'UPDATE STATUS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AppointmentStatus>(
                        initialValue: targetStatus,
                        dropdownColor: colors.surface,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: colors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: colors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        items: AppointmentStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Icon(status.icon, size: 16, color: status.color(context)),
                                const SizedBox(width: 8),
                                Text(status.displayName,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: colors.primaryText)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => targetStatus = val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Private Designer Notes
                      Row(
                        children: [
                          Icon(Icons.lock_outline,
                              size: 14, color: colors.accentVariant),
                          const SizedBox(width: 6),
                          Text(
                            'ATELIER DESIGNER NOTES (INTERNAL ONLY)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: colors.primaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'These notes are never visible to the customer under any circumstance.',
                        style: TextStyle(
                            fontSize: 11,
                            color: colors.secondaryText,
                            fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: designerNotesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              'Enter fitting observations, design alterations, fabric swatches requested...',
                          hintStyle: TextStyle(
                              fontSize: 12, color: colors.secondaryText),
                          filled: true,
                          fillColor: colors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: colors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: colors.accent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text('CLOSE',
                      style: TextStyle(color: colors.secondaryText)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onAccent,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          try {
                            await Supabase.instance.client
                                .from('appointments')
                                .update({
                              'status': targetStatus.toJson(),
                              'designer_notes':
                                  designerNotesController.text.trim().isEmpty
                                      ? null
                                      : designerNotesController.text.trim(),
                              'updated_at': DateTime.now().toIso8601String(),
                            }).eq('id', appt.id);

                            if (context.mounted) {
                              Navigator.of(dialogCtx).pop();
                              ref.invalidate(adminAppointmentsProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: colors.surface,
                                  content: Text('Appointment updated successfully',
                                      style: TextStyle(color: colors.primaryText)),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Failed to update: $e')),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: colors.onAccent),
                        )
                      : const Text('SAVE CHANGES'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openAvailabilityDialog(BuildContext context, AppColorTokens colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            Icon(Icons.tune, color: colors.accentVariant, size: 22),
            const SizedBox(width: 10),
            Text(
              'ATELIER AVAILABILITY CONFIGURATION',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: colors.primaryText,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Consumer(
            builder: (context, ref, _) {
              final availAsync = ref.watch(designerAvailabilityProvider);
              return availAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (availList) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: availList.map((avail) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 6),
                        color: avail.isAvailable
                            ? colors.surface
                            : colors.surfaceVariant,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 90,
                              child: Text(
                                avail.dayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: avail.isAvailable
                                      ? colors.primaryText
                                      : colors.secondaryText,
                                ),
                              ),
                            ),
                            Text(
                              avail.isAvailable
                                  ? '${avail.startTime} – ${avail.endTime}'
                                  : 'CLOSED',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: avail.isAvailable
                                    ? colors.primaryText
                                    : colors.error,
                              ),
                            ),
                            Text(
                              avail.isAvailable
                                  ? 'Max: ${avail.maxAppointments}/day'
                                  : '—',
                              style: TextStyle(
                                  fontSize: 11, color: colors.secondaryText),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, AppColorTokens colors,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(fontSize: 11, color: colors.secondaryText)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? colors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final appointmentsAsync = ref.watch(adminAppointmentsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ATELIER OPERATIONS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.5,
                        color: colors.accentVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Appointments Calendar',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          _openAvailabilityDialog(context, colors),
                      icon: const Icon(Icons.schedule, size: 16),
                      label: const Text('AVAILABILITY SCHEDULE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryText,
                        side: BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: () =>
                          ref.invalidate(adminAppointmentsProvider),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by client notes, service...',
                        hintStyle: TextStyle(
                            fontSize: 13, color: colors.secondaryText),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: colors.surfaceVariant,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().isEmpty ? null : val.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<AppointmentStatus?>(
                    value: _selectedStatusFilter,
                    hint: Text('All Statuses',
                        style: TextStyle(
                            fontSize: 12, color: colors.primaryText)),
                    dropdownColor: colors.surface,
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Statuses')),
                      ...AppointmentStatus.values.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.displayName),
                        ),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedStatusFilter = val),
                  ),
                  const SizedBox(width: 16),
                  if (_selectedDateFilter != null) ...[
                    Chip(
                      label: Text(
                        DateFormat('MMM d').format(_selectedDateFilter!),
                        style: const TextStyle(fontSize: 11),
                      ),
                      onDeleted: () =>
                          setState(() => _selectedDateFilter = null),
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDateFilter ?? DateTime.now(),
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _selectedDateFilter = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(
                      _selectedDateFilter == null
                          ? 'FILTER BY DATE'
                          : DateFormat('MMM d, yyyy').format(_selectedDateFilter!),
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primaryText,
                      side: BorderSide(color: colors.border),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Appointments List / Table
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
                var filtered = appointments;

                if (_selectedStatusFilter != null) {
                  filtered = filtered
                      .where((a) => a.status == _selectedStatusFilter)
                      .toList();
                }

                if (_selectedDateFilter != null) {
                  filtered = filtered
                      .where((a) => DateUtils.isSameDay(
                          a.scheduledDate, _selectedDateFilter!))
                      .toList();
                }

                if (_searchQuery != null) {
                  filtered = filtered.where((a) {
                    final notesMatch =
                        a.notes?.toLowerCase().contains(_searchQuery!) ?? false;
                    final typeMatch = a.type?.name
                            .toLowerCase()
                            .contains(_searchQuery!) ??
                        false;
                    return notesMatch || typeMatch;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(48),
                    color: colors.surface,
                    child: Center(
                      child: Text(
                        'No appointments match your filters.',
                        style: TextStyle(
                            color: colors.secondaryText, fontSize: 14),
                      ),
                    ),
                  );
                }

                return Column(
                  children: filtered.map((appt) {
                    return _buildAppointmentRow(context, appt, colors);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentRow(
      BuildContext context, Appointment appt, AppColorTokens colors) {
    final dateStr = DateFormat('MMM d, yyyy').format(appt.scheduledDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          // Date & Time block
          Container(
            width: 120,
            padding: const EdgeInsets.all(8),
            color: colors.surfaceVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${appt.startTime} – ${appt.endTime}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Service details
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt.type?.name ?? 'Atelier Session',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${appt.type?.durationMinutes ?? 60} mins  •  ${appt.bookingFeePaid ? 'Fee Paid' : 'Fee Pending'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: appt.bookingFeePaid
                        ? colors.success
                        : colors.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: appt.status.color(context).withValues(alpha: 0.15),
            child: Text(
              appt.status.displayName.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: appt.status.color(context),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Has Designer Notes indicator
          if (appt.designerNotes != null && appt.designerNotes!.isNotEmpty) ...[
            Tooltip(
              message: 'Has private designer notes',
              child: Icon(Icons.note_alt, size: 18, color: colors.accentVariant),
            ),
            const SizedBox(width: 12),
          ],

          // Manage Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
            onPressed: () =>
                _openAppointmentDetailDialog(context, appt, colors),
            child: const Text('MANAGE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
