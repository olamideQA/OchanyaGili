import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/features/appointments/data/appointments_repository.dart';
import 'package:ochanya_gili/features/appointments/domain/models/appointment.dart';

void main() {
  group('AppointmentStatus', () {
    test('fromString maps all database values correctly', () {
      expect(AppointmentStatus.fromString('pending_payment'),
          AppointmentStatus.pendingPayment);
      expect(AppointmentStatus.fromString('confirmed'),
          AppointmentStatus.confirmed);
      expect(AppointmentStatus.fromString('completed'),
          AppointmentStatus.completed);
      expect(AppointmentStatus.fromString('cancelled'),
          AppointmentStatus.cancelled);
      expect(AppointmentStatus.fromString('no_show'),
          AppointmentStatus.noShow);
    });

    test('fromString falls back to pendingPayment on unknown string', () {
      expect(AppointmentStatus.fromString('unknown'),
          AppointmentStatus.pendingPayment);
      expect(AppointmentStatus.fromString(''),
          AppointmentStatus.pendingPayment);
    });

    test('toJson returns correct snake_case string', () {
      expect(AppointmentStatus.pendingPayment.toJson(), 'pending_payment');
      expect(AppointmentStatus.confirmed.toJson(), 'confirmed');
      expect(AppointmentStatus.completed.toJson(), 'completed');
      expect(AppointmentStatus.cancelled.toJson(), 'cancelled');
      expect(AppointmentStatus.noShow.toJson(), 'no_show');
    });

    test('displayName returns user-facing labels', () {
      expect(AppointmentStatus.pendingPayment.displayName, 'Pending Payment');
      expect(AppointmentStatus.confirmed.displayName, 'Confirmed');
      expect(AppointmentStatus.completed.displayName, 'Completed');
      expect(AppointmentStatus.cancelled.displayName, 'Cancelled');
      expect(AppointmentStatus.noShow.displayName, 'No Show');
    });
  });

  group('AppointmentType', () {
    test('fromJson parses all fields accurately', () {
      final json = {
        'id': 'type-001',
        'name': 'Style Consultation',
        'slug': 'consultation',
        'description': 'One-on-one session with lead designer.',
        'duration_minutes': 60,
        'buffer_minutes': 15,
        'booking_fee': 15000.0,
        'is_active': true,
        'sort_order': 0,
      };

      final type = AppointmentType.fromJson(json);
      expect(type.id, 'type-001');
      expect(type.name, 'Style Consultation');
      expect(type.slug, 'consultation');
      expect(type.description, 'One-on-one session with lead designer.');
      expect(type.durationMinutes, 60);
      expect(type.bufferMinutes, 15);
      expect(type.bookingFee, 15000.0);
      expect(type.isActive, isTrue);
      expect(type.sortOrder, 0);
      expect(type.hasFee, isTrue);
    });

    test('hasFee is false when booking fee is 0', () {
      const type = AppointmentType(
        name: 'Garment Fitting',
        slug: 'fitting',
        bookingFee: 0,
      );
      expect(type.hasFee, isFalse);
    });

    test('toJson serializes correctly', () {
      const type = AppointmentType(
        name: 'Measurement Session',
        slug: 'measurement',
        description: 'Full body anatomical measurements.',
        durationMinutes: 45,
        bufferMinutes: 10,
        bookingFee: 10000.0,
        sortOrder: 1,
      );

      final json = type.toJson();
      expect(json['name'], 'Measurement Session');
      expect(json['slug'], 'measurement');
      expect(json['duration_minutes'], 45);
      expect(json['buffer_minutes'], 10);
      expect(json['booking_fee'], 10000.0);
      expect(json['sort_order'], 1);
    });
  });

  group('DesignerAvailability', () {
    test('fromJson parses days and times correctly', () {
      final json = {
        'id': 'avail-001',
        'day_of_week': 1,
        'start_time': '09:00:00',
        'end_time': '17:00:00',
        'is_available': true,
        'max_appointments': 8,
      };

      final avail = DesignerAvailability.fromJson(json);
      expect(avail.id, 'avail-001');
      expect(avail.dayOfWeek, 1);
      expect(avail.startTime, '09:00');
      expect(avail.endTime, '17:00');
      expect(avail.isAvailable, isTrue);
      expect(avail.maxAppointments, 8);
      expect(avail.dayName, 'Monday');
      expect(avail.dayAbbrev, 'Mon');
    });

    test('dayName and dayAbbrev cover Sunday to Saturday correctly', () {
      const sunday = DesignerAvailability(dayOfWeek: 0, isAvailable: false);
      const saturday = DesignerAvailability(dayOfWeek: 6, isAvailable: true);

      expect(sunday.dayName, 'Sunday');
      expect(sunday.dayAbbrev, 'Sun');
      expect(saturday.dayName, 'Saturday');
      expect(saturday.dayAbbrev, 'Sat');
    });
  });

  group('TimeSlot', () {
    test('displayRange formats AM and PM hours correctly', () {
      const morningSlot = TimeSlot(startTime: '09:00', endTime: '10:00');
      const noonSlot = TimeSlot(startTime: '12:00', endTime: '13:30');
      const afternoonSlot = TimeSlot(startTime: '14:30', endTime: '15:30');

      expect(morningSlot.displayRange, '9:00 AM – 10:00 AM');
      expect(noonSlot.displayRange, '12:00 PM – 1:30 PM');
      expect(afternoonSlot.displayRange, '2:30 PM – 3:30 PM');
    });
  });

  group('Appointment', () {
    test('fromJson parses appointment with joined appointment_types', () {
      final json = {
        'id': 'appt-001',
        'profile_id': 'user-123',
        'appointment_type_id': 'type-001',
        'scheduled_date': '2026-10-05',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
        'status': 'confirmed',
        'booking_fee_paid': true,
        'notes': 'Looking for gala eveningwear silk suggestions.',
        'designer_notes': 'Client preferred Emerald silk faille.',
        'created_at': '2026-09-29T00:00:00.000Z',
        'appointment_types': {
          'id': 'type-001',
          'name': 'Custom Design Consultation',
          'slug': 'custom-design',
          'duration_minutes': 60,
          'buffer_minutes': 15,
          'booking_fee': 25000.0,
        },
      };

      final appt = Appointment.fromJson(json);
      expect(appt.id, 'appt-001');
      expect(appt.profileId, 'user-123');
      expect(appt.scheduledDate, DateTime.parse('2026-10-05'));
      expect(appt.startTime, '10:00');
      expect(appt.endTime, '11:00');
      expect(appt.status, AppointmentStatus.confirmed);
      expect(appt.bookingFeePaid, isTrue);
      expect(appt.notes, 'Looking for gala eveningwear silk suggestions.');
      expect(appt.designerNotes, 'Client preferred Emerald silk faille.');
      expect(appt.type?.name, 'Custom Design Consultation');
      expect(appt.isConfirmed, isTrue);
      expect(appt.isPending, isFalse);
    });

    test('toJson serializes correctly', () {
      final appt = Appointment(
        id: 'appt-002',
        profileId: 'user-456',
        appointmentTypeId: 'type-002',
        scheduledDate: DateTime(2026, 11, 15),
        startTime: '14:00',
        endTime: '15:00',
        status: AppointmentStatus.pendingPayment,
        notes: 'Fitting for bridesmaid gown.',
      );

      final json = appt.toJson();
      expect(json['profile_id'], 'user-456');
      expect(json['appointment_type_id'], 'type-002');
      expect(json['scheduled_date'], '2026-11-15');
      expect(json['start_time'], '14:00');
      expect(json['end_time'], '15:00');
      expect(json['status'], 'pending_payment');
      expect(json['notes'], 'Fitting for bridesmaid gown.');
    });
  });

  group('AvailableSlotsResult & BookingResult', () {
    test('AvailableSlotsResult fromJson parses slot array and counts', () {
      final json = {
        'available': true,
        'slots': [
          {'start_time': '09:00:00', 'end_time': '10:00:00'},
          {'start_time': '10:15:00', 'end_time': '11:15:00'},
        ],
        'booked_count': 2,
        'max_appointments': 8,
      };

      final result = AvailableSlotsResult.fromJson(json);
      expect(result.isAvailable, isTrue);
      expect(result.slots.length, 2);
      expect(result.slots[0].startTime, '09:00');
      expect(result.slots[1].startTime, '10:15');
      expect(result.bookedCount, 2);
      expect(result.maxAppointments, 8);
    });

    test('BookingResult fromJson parses success and error responses', () {
      final successJson = {
        'success': true,
        'appointment_id': 'appt-999',
        'status': 'confirmed',
        'booking_fee': 0,
      };
      final success = BookingResult.fromJson(successJson);
      expect(success.success, isTrue);
      expect(success.appointmentId, 'appt-999');
      expect(success.status, 'confirmed');

      final errorJson = {
        'success': false,
        'error': 'This time slot conflicts with an existing appointment',
      };
      final err = BookingResult.fromJson(errorJson);
      expect(err.success, isFalse);
      expect(err.error,
          'This time slot conflicts with an existing appointment');
    });
  });
}
