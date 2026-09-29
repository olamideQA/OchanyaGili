import 'package:flutter/material.dart';

/// Appointment status lifecycle
enum AppointmentStatus {
  pendingPayment('pending_payment', 'Pending Payment'),
  confirmed('confirmed', 'Confirmed'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled'),
  noShow('no_show', 'No Show');

  const AppointmentStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  String toJson() => value;

  static AppointmentStatus fromString(String s) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => AppointmentStatus.pendingPayment,
    );
  }

  Color color(BuildContext context) {
    switch (this) {
      case AppointmentStatus.pendingPayment:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.completed:
        return Colors.blue;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case AppointmentStatus.pendingPayment:
        return Icons.payment;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.noShow:
        return Icons.person_off;
    }
  }
}

/// Appointment type (consultation, measurement, fitting, custom design)
class AppointmentType {
  final String id;
  final String name;
  final String slug;
  final String description;
  final int durationMinutes;
  final int bufferMinutes;
  final double bookingFee;
  final bool isActive;
  final int sortOrder;

  const AppointmentType({
    this.id = '',
    required this.name,
    required this.slug,
    this.description = '',
    this.durationMinutes = 60,
    this.bufferMinutes = 15,
    this.bookingFee = 0,
    this.isActive = true,
    this.sortOrder = 0,
  });

  bool get hasFee => bookingFee > 0;

  factory AppointmentType.fromJson(Map<String, dynamic> json) {
    return AppointmentType(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      bufferMinutes: json['buffer_minutes'] as int? ?? 15,
      bookingFee: (json['booking_fee'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'slug': slug,
    'description': description,
    'duration_minutes': durationMinutes,
    'buffer_minutes': bufferMinutes,
    'booking_fee': bookingFee,
    'is_active': isActive,
    'sort_order': sortOrder,
  };
}

/// Designer availability for a day of the week
class DesignerAvailability {
  final String id;
  final int dayOfWeek; // 0=Sunday, 6=Saturday
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final int maxAppointments;

  const DesignerAvailability({
    this.id = '',
    required this.dayOfWeek,
    this.startTime = '09:00',
    this.endTime = '17:00',
    this.isAvailable = true,
    this.maxAppointments = 8,
  });

  String get dayName {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek];
  }

  String get dayAbbrev {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[dayOfWeek];
  }

  factory DesignerAvailability.fromJson(Map<String, dynamic> json) {
    return DesignerAvailability(
      id: json['id'] as String? ?? '',
      dayOfWeek: json['day_of_week'] as int? ?? 0,
      startTime: (json['start_time'] as String? ?? '09:00:00').substring(0, 5),
      endTime: (json['end_time'] as String? ?? '17:00:00').substring(0, 5),
      isAvailable: json['is_available'] as bool? ?? false,
      maxAppointments: json['max_appointments'] as int? ?? 8,
    );
  }
}

/// A single available time slot
class TimeSlot {
  final String startTime;
  final String endTime;

  const TimeSlot({required this.startTime, required this.endTime});

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: (json['start_time'] as String? ?? '').substring(0, 5),
      endTime: (json['end_time'] as String? ?? '').substring(0, 5),
    );
  }

  /// Format for display: "09:00 AM - 10:00 AM"
  String get displayRange {
    return '${_formatTime(startTime)} – ${_formatTime(endTime)}';
  }

  String _formatTime(String t) {
    final parts = t.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h12:$minute $period';
  }
}

/// Appointment model
class Appointment {
  final String id;
  final String profileId;
  final String appointmentTypeId;
  final DateTime scheduledDate;
  final String startTime;
  final String endTime;
  final AppointmentStatus status;
  final bool bookingFeePaid;
  final String? paymentId;
  final String? notes;
  final String? designerNotes;
  final String? customRequestId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined data
  final AppointmentType? type;

  const Appointment({
    this.id = '',
    this.profileId = '',
    this.appointmentTypeId = '',
    required this.scheduledDate,
    this.startTime = '',
    this.endTime = '',
    this.status = AppointmentStatus.pendingPayment,
    this.bookingFeePaid = false,
    this.paymentId,
    this.notes,
    this.designerNotes,
    this.customRequestId,
    this.createdAt,
    this.updatedAt,
    this.type,
  });

  bool get isPending => status == AppointmentStatus.pendingPayment;
  bool get isConfirmed => status == AppointmentStatus.confirmed;
  bool get isUpcoming =>
      (isConfirmed || isPending) && scheduledDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      appointmentTypeId: json['appointment_type_id'] as String? ?? '',
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      startTime: ((json['start_time'] as String?) ?? '00:00:00').substring(0, 5),
      endTime: ((json['end_time'] as String?) ?? '00:00:00').substring(0, 5),
      status: AppointmentStatus.fromString(json['status'] as String? ?? ''),
      bookingFeePaid: json['booking_fee_paid'] as bool? ?? false,
      paymentId: json['payment_id'] as String?,
      notes: json['notes'] as String?,
      designerNotes: json['designer_notes'] as String?,
      customRequestId: json['custom_request_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      type: json['appointment_types'] != null
          ? AppointmentType.fromJson(json['appointment_types'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'profile_id': profileId,
    'appointment_type_id': appointmentTypeId,
    'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
    'start_time': startTime,
    'end_time': endTime,
    'status': status.toJson(),
    'booking_fee_paid': bookingFeePaid,
    if (notes != null) 'notes': notes,
    if (customRequestId != null) 'custom_request_id': customRequestId,
  };
}
