import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/features/appointments/domain/models/appointment.dart';

class AvailableSlotsResult {
  final bool isAvailable;
  final String? reason;
  final List<TimeSlot> slots;
  final int bookedCount;
  final int maxAppointments;

  const AvailableSlotsResult({
    required this.isAvailable,
    this.reason,
    required this.slots,
    this.bookedCount = 0,
    this.maxAppointments = 0,
  });

  factory AvailableSlotsResult.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'] as List<dynamic>? ?? [];
    return AvailableSlotsResult(
      isAvailable: json['available'] as bool? ?? false,
      reason: json['reason'] as String?,
      slots: rawSlots
          .map((s) => TimeSlot.fromJson(s as Map<String, dynamic>))
          .toList(),
      bookedCount: json['booked_count'] as int? ?? 0,
      maxAppointments: json['max_appointments'] as int? ?? 0,
    );
  }
}

class BookingResult {
  final bool success;
  final String? appointmentId;
  final String? error;
  final double bookingFee;
  final String? status;

  const BookingResult({
    required this.success,
    this.appointmentId,
    this.error,
    this.bookingFee = 0,
    this.status,
  });

  factory BookingResult.fromJson(Map<String, dynamic> json) {
    return BookingResult(
      success: json['success'] as bool? ?? false,
      appointmentId: json['appointment_id'] as String?,
      error: json['error'] as String?,
      bookingFee: (json['booking_fee'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String?,
    );
  }
}

class AppointmentsRepository {
  final SupabaseClient _client;

  AppointmentsRepository(this._client);

  /// Fetch active appointment types
  Future<List<AppointmentType>> getAppointmentTypes() async {
    final data = await _client
        .from('appointment_types')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (data as List<dynamic>)
        .map((json) => AppointmentType.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get open time slots for a specific date and appointment type
  Future<AvailableSlotsResult> getAvailableSlots({
    required DateTime date,
    required String appointmentTypeSlug,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final res = await _client.rpc('get_available_slots', params: {
      'p_date': dateStr,
      'p_appointment_type_slug': appointmentTypeSlug,
    });

    return AvailableSlotsResult.fromJson(res as Map<String, dynamic>);
  }

  /// Book an appointment using the concurrent-safe RPC
  Future<BookingResult> bookAppointment({
    required String profileId,
    required String appointmentTypeSlug,
    required DateTime scheduledDate,
    required String startTime,
    String? notes,
    String? customRequestId,
  }) async {
    final dateStr = scheduledDate.toIso8601String().split('T')[0];
    final params = <String, dynamic>{
      'p_profile_id': profileId,
      'p_appointment_type_slug': appointmentTypeSlug,
      'p_scheduled_date': dateStr,
      'p_start_time': startTime,
    };
    if (notes != null) {
      params['p_notes'] = notes;
    }
    if (customRequestId != null) {
      params['p_custom_request_id'] = customRequestId;
    }

    final res = await _client.rpc('book_appointment', params: params);

    return BookingResult.fromJson(res as Map<String, dynamic>);
  }

  /// Settle booking fee payment via server-side RPC
  Future<Map<String, dynamic>> settleBookingFee({
    required String appointmentId,
    required String paymentReference,
    required double amountPaid,
  }) async {
    final res = await _client.rpc('settle_appointment_booking_fee', params: {
      'p_appointment_id': appointmentId,
      'p_payment_reference': paymentReference,
      'p_amount_paid': amountPaid,
    });

    return res as Map<String, dynamic>;
  }

  /// Get appointments for the authenticated customer
  Future<List<Appointment>> getCustomerAppointments(String profileId) async {
    final data = await _client
        .from('appointments')
        .select('*, appointment_types(*)')
        .eq('profile_id', profileId)
        .order('scheduled_date', ascending: false)
        .order('start_time', ascending: false);

    return (data as List<dynamic>)
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get all appointments for admin/designer view
  Future<List<Appointment>> getAllAppointments({
    DateTime? date,
    String? status,
  }) async {
    var query = _client.from('appointments').select('*, appointment_types(*)');

    if (date != null) {
      final dateStr = date.toIso8601String().split('T')[0];
      query = query.eq('scheduled_date', dateStr);
    }

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }

    final data = await query
        .order('scheduled_date', ascending: true)
        .order('start_time', ascending: true);

    return (data as List<dynamic>)
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Cancel an appointment
  Future<void> cancelAppointment(String appointmentId) async {
    await _client.from('appointments').update({
      'status': 'cancelled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', appointmentId);
  }

  /// Get designer weekly availability settings
  Future<List<DesignerAvailability>> getDesignerAvailability() async {
    final data = await _client
        .from('designer_availability')
        .select()
        .order('day_of_week', ascending: true);

    return (data as List<dynamic>)
        .map((json) =>
            DesignerAvailability.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Update designer availability for a day of week
  Future<void> updateDesignerAvailability({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required bool isAvailable,
    required int maxAppointments,
  }) async {
    await _client.from('designer_availability').upsert({
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable,
      'max_appointments': maxAppointments,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'day_of_week');
  }
}

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  return AppointmentsRepository(Supabase.instance.client);
});

final appointmentTypesProvider = FutureProvider<List<AppointmentType>>((ref) async {
  final repo = ref.watch(appointmentsRepositoryProvider);
  return repo.getAppointmentTypes();
});

final customerAppointmentsProvider =
    FutureProvider.family<List<Appointment>, String>((ref, profileId) async {
  final repo = ref.watch(appointmentsRepositoryProvider);
  return repo.getCustomerAppointments(profileId);
});

final designerAvailabilityProvider =
    FutureProvider<List<DesignerAvailability>>((ref) async {
  final repo = ref.watch(appointmentsRepositoryProvider);
  return repo.getDesignerAvailability();
});
