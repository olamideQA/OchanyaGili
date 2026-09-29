import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';
import 'package:ochanya_gili/features/appointments/data/appointments_repository.dart';
import 'package:ochanya_gili/features/appointments/domain/models/appointment.dart';
import 'package:ochanya_gili/features/analytics/data/analytics_service.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  final String? customRequestId;
  final String? preselectedTypeSlug;

  const BookAppointmentScreen({
    super.key,
    this.customRequestId,
    this.preselectedTypeSlug,
  });

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  AppointmentType? _selectedType;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeSlot? _selectedSlot;
  final _notesController = TextEditingController();
  bool _isBooking = false;
  String? _errorMessage;

  // Slots state
  bool _isLoadingSlots = false;
  AvailableSlotsResult? _slotsResult;

  @override
  void initState() {
    super.initState();
    // Auto-advance if tomorrow is Sunday
    if (_selectedDate.weekday == DateTime.sunday) {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(analyticsServiceProvider).trackAppointmentStarted(
          appointmentTypeId: widget.preselectedTypeSlug,
        );
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    if (_selectedType == null) return;

    setState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(appointmentsRepositoryProvider);
      final res = await repo.getAvailableSlots(
        date: _selectedDate,
        appointmentTypeSlug: _selectedType!.slug,
      );
      if (mounted) {
        setState(() {
          _slotsResult = res;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load available slots: $e';
          _isLoadingSlots = false;
        });
      }
    }
  }

  Future<void> _handleBook() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to book an appointment.')),
      );
      return;
    }

    if (_selectedType == null) {
      setState(() => _errorMessage = 'Please select an appointment type.');
      return;
    }
    if (_selectedSlot == null) {
      setState(() => _errorMessage = 'Please select a time slot.');
      return;
    }

    setState(() {
      _isBooking = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(appointmentsRepositoryProvider);
      final bookingRes = await repo.bookAppointment(
        profileId: user.id,
        appointmentTypeSlug: _selectedType!.slug,
        scheduledDate: _selectedDate,
        startTime: _selectedSlot!.startTime,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        customRequestId: widget.customRequestId,
      );

      if (!bookingRes.success) {
        setState(() {
          _errorMessage = bookingRes.error ?? 'Booking failed.';
          _isBooking = false;
        });
        return;
      }

      // If fee > 0, settle the booking fee using server-side RPC
      if (_selectedType!.hasFee && bookingRes.appointmentId != null) {
        final paymentRef =
            'OG-APPT-${DateTime.now().millisecondsSinceEpoch}-${bookingRes.appointmentId!.substring(0, 6)}';
        final feeRes = await repo.settleBookingFee(
          appointmentId: bookingRes.appointmentId!,
          paymentReference: paymentRef,
          amountPaid: _selectedType!.bookingFee,
        );

        if (feeRes['success'] != true) {
          setState(() {
            _errorMessage =
                'Appointment reserved but fee settlement failed: ${feeRes['error']}';
            _isBooking = false;
          });
          return;
        }
      }

      if (mounted) {
        setState(() => _isBooking = false);
        ref.read(analyticsServiceProvider).trackAppointmentCompleted(
              appointmentId: bookingRes.appointmentId ?? '',
              typeName: _selectedType!.name,
            );
        _showSuccessDialog(bookingRes.appointmentId ?? '');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error submitting booking: $e';
          _isBooking = false;
        });
      }
    }
  }

  void _showSuccessDialog(String appointmentId) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: colors.success, size: 28),
            const SizedBox(width: 12),
            Text(
              'APPOINTMENT CONFIRMED',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: colors.primaryText,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your private session with the atelier has been scheduled.',
              style: TextStyle(color: colors.primaryText, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              color: colors.surfaceVariant,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogRow('Service', _selectedType?.name ?? '', colors),
                  const SizedBox(height: 6),
                  _dialogRow('Date', dateStr, colors),
                  const SizedBox(height: 6),
                  _dialogRow('Time', _selectedSlot?.displayRange ?? '', colors),
                  if (_selectedType?.hasFee ?? false) ...[
                    const SizedBox(height: 6),
                    _dialogRow(
                      'Booking Fee',
                      NumberFormat.currency(
                        locale: 'en_NG',
                        symbol: '₦',
                        decimalDigits: 0,
                      ).format(_selectedType!.bookingFee),
                      colors,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/account/appointments');
            },
            child: const Text('VIEW MY APPOINTMENTS'),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value, AppColorTokens colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: colors.secondaryText)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.primaryText)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final typesAsync = ref.watch(appointmentTypesProvider);
    final currencyFormat =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('BOOK AN APPOINTMENT'),
        backgroundColor: colors.surface,
        foregroundColor: colors.primaryText,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/account/appointments'),
        ),
      ),
      body: typesAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: colors.primaryText)),
        error: (e, _) => Center(child: Text('Error loading types: $e')),
        data: (types) {
          if (types.isEmpty) {
            return const Center(child: Text('No appointment types available.'));
          }

          // Preselect if needed
          if (_selectedType == null) {
            if (widget.preselectedTypeSlug != null) {
              _selectedType = types.firstWhere(
                (t) => t.slug == widget.preselectedTypeSlug,
                orElse: () => types.first,
              );
            } else {
              _selectedType = types.first;
            }
            // Trigger initial slot fetch
            WidgetsBinding.instance.addPostFrameCallback((_) => _fetchSlots());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Header
                    Text(
                      'PRIVATE ATELIER SESSION',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.5,
                        color: colors.accentVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reserve Your Time',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Experience bespoke couture consultations and private fittings at our atelier.',
                      style: TextStyle(fontSize: 13, color: colors.secondaryText),
                    ),
                    const SizedBox(height: 28),

                    // Section 2: Choose Appointment Type
                    _buildSectionHeader('1. SELECT SESSION TYPE', colors),
                    const SizedBox(height: 12),
                    Column(
                      children: types.map((type) {
                        final isSelected = _selectedType?.id == type.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            border: Border.all(
                              color: isSelected
                                  ? colors.accentVariant
                                  : colors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedType = type);
                              _fetchSlots();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    margin: const EdgeInsets.only(top: 2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? colors.accentVariant
                                            : colors.border,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: colors.accentVariant,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              type.name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: colors.primaryText,
                                              ),
                                            ),
                                            Text(
                                              type.hasFee
                                                  ? currencyFormat.format(
                                                      type.bookingFee)
                                                  : 'Complimentary',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: type.hasFee
                                                    ? colors.accentVariant
                                                    : colors.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${type.durationMinutes} mins${type.bufferMinutes > 0 ? ' (+${type.bufferMinutes} min transition)' : ''}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colors.secondaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          type.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.primaryText
                                                .withValues(alpha: 0.8),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // Section 3: Select Date
                    _buildSectionHeader('2. SELECT DATE', colors),
                    const SizedBox(height: 12),
                    _buildDateSelector(colors),
                    const SizedBox(height: 28),

                    // Section 4: Available Time Slots
                    _buildSectionHeader('3. SELECT AVAILABLE TIME SLOT', colors),
                    const SizedBox(height: 12),
                    _buildSlotsSection(colors),
                    const SizedBox(height: 28),

                    // Section 5: Notes & Special Requests
                    _buildSectionHeader('4. SPECIAL REQUESTS / NOTES', colors),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Provide any preferences, specific fabrics, or context regarding your appointment...',
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
                    const SizedBox(height: 28),

                    // Error Message Display
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: colors.error.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: colors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                    color: colors.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Section 6: Summary & Confirm Button
                    _buildBookingSummary(colors, currencyFormat),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: colors.onAccent,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                        ),
                        onPressed: (_isBooking || _selectedSlot == null)
                            ? null
                            : _handleBook,
                        child: _isBooking
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onAccent,
                                ),
                              )
                            : Text(
                                _selectedType?.hasFee ?? false
                                    ? 'CONFIRM & SETTLE BOOKING FEE (${currencyFormat.format(_selectedType!.bookingFee)})'
                                    : 'CONFIRM APPOINTMENT',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColorTokens colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: colors.primaryText,
      ),
    );
  }

  Widget _buildDateSelector(AppColorTokens colors) {
    // Generate next 14 days
    final now = DateTime.now();
    final days = List.generate(14, (i) => now.add(Duration(days: i + 1)));

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = DateUtils.isSameDay(day, _selectedDate);
          final isSunday = day.weekday == DateTime.sunday;

          return Container(
            width: 68,
            decoration: BoxDecoration(
              color: isSelected ? colors.accent : colors.surface,
              border: Border.all(
                color: isSelected ? colors.accent : colors.border,
              ),
            ),
            child: InkWell(
              onTap: isSunday
                  ? null
                  : () {
                      setState(() => _selectedDate = day);
                      _fetchSlots();
                    },
              child: Opacity(
                opacity: isSunday ? 0.35 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(day).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? colors.onAccent
                              : colors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? colors.onAccent
                              : colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM').format(day).toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.5,
                          color: isSelected
                              ? colors.onAccent.withValues(alpha: 0.7)
                              : colors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotsSection(AppColorTokens colors) {
    if (_isLoadingSlots) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CircularProgressIndicator(color: colors.primaryText),
        ),
      );
    }

    if (_slotsResult == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: colors.surface,
        child: Text(
          'Select a date and appointment type above to view open slots.',
          style: TextStyle(color: colors.secondaryText, fontSize: 13),
        ),
      );
    }

    if (!_slotsResult!.isAvailable) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: colors.surfaceVariant,
        child: Row(
          children: [
            Icon(Icons.event_busy, color: colors.secondaryText, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _slotsResult!.reason ??
                    'The atelier is unavailable on this date.',
                style: TextStyle(color: colors.primaryText, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final slots = _slotsResult!.slots;

    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: colors.surfaceVariant,
        child: Row(
          children: [
            Icon(Icons.schedule, color: colors.secondaryText, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'All slots for ${DateFormat('MMMM d').format(_selectedDate)} are fully booked. Please select another date.',
                style: TextStyle(color: colors.primaryText, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: slots.map((slot) {
            final isSelected = _selectedSlot?.startTime == slot.startTime;
            return Container(
              decoration: BoxDecoration(
                color: isSelected ? colors.accent : colors.surface,
                border: Border.all(
                  color: isSelected ? colors.accent : colors.border,
                ),
              ),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedSlot = slot);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    slot.displayRange,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      letterSpacing: 0.5,
                      color: isSelected ? colors.onAccent : colors.primaryText,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          '${slots.length} available slot${slots.length == 1 ? '' : 's'} on ${DateFormat('EEEE, MMMM d').format(_selectedDate)}',
          style: TextStyle(fontSize: 11, color: colors.secondaryText),
        ),
      ],
    );
  }

  Widget _buildBookingSummary(
      AppColorTokens colors, NumberFormat currencyFormat) {
    if (_selectedSlot == null || _selectedType == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESERVATION SUMMARY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: colors.accentVariant,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow('Session', _selectedType!.name, colors),
          const SizedBox(height: 6),
          _summaryRow(
            'Date & Time',
            '${DateFormat('MMM d, yyyy').format(_selectedDate)} at ${_selectedSlot!.displayRange}',
            colors,
          ),
          const SizedBox(height: 6),
          _summaryRow(
            'Duration',
            '${_selectedType!.durationMinutes} minutes',
            colors,
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Fee',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.primaryText,
                ),
              ),
              Text(
                _selectedType!.hasFee
                    ? currencyFormat.format(_selectedType!.bookingFee)
                    : 'COMPLIMENTARY',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _selectedType!.hasFee
                      ? colors.accentVariant
                      : colors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, AppColorTokens colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: colors.secondaryText)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.primaryText)),
      ],
    );
  }
}
