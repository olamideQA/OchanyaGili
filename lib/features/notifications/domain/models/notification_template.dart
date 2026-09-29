import 'package:equatable/equatable.dart';

enum NotificationChannel {
  inApp('in_app'),
  email('email'),
  push('push');

  final String dbValue;
  const NotificationChannel(this.dbValue);

  static NotificationChannel fromString(String val) {
    return NotificationChannel.values.firstWhere(
      (e) => e.dbValue == val,
      orElse: () => NotificationChannel.inApp,
    );
  }
}

class NotificationTemplate extends Equatable {
  final String id;
  final String eventType; // 'order' | 'custom_request' | 'appointment'
  final String status;
  final String inAppTitle;
  final String inAppBody;
  final String emailSubject;
  final String emailHtml;
  final String pushTitle;
  final String pushBody;
  final String actionUrl;

  const NotificationTemplate({
    required this.id,
    required this.eventType,
    required this.status,
    required this.inAppTitle,
    required this.inAppBody,
    required this.emailSubject,
    required this.emailHtml,
    required this.pushTitle,
    required this.pushBody,
    required this.actionUrl,
  });

  /// Interpolates template placeholders with real commission/client variables
  NotificationTemplate interpolate(Map<String, dynamic> variables) {
    String replace(String text) {
      var result = text;
      variables.forEach((key, value) {
        result = result.replaceAll('{$key}', value?.toString() ?? '');
      });
      return result;
    }

    return NotificationTemplate(
      id: id,
      eventType: eventType,
      status: status,
      inAppTitle: replace(inAppTitle),
      inAppBody: replace(inAppBody),
      emailSubject: replace(emailSubject),
      emailHtml: replace(emailHtml),
      pushTitle: replace(pushTitle),
      pushBody: replace(pushBody),
      actionUrl: replace(actionUrl),
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventType,
        status,
        inAppTitle,
        inAppBody,
        emailSubject,
        pushTitle,
        pushBody,
        actionUrl,
      ];
}

class NotificationTemplateRegistry {
  static final List<NotificationTemplate> templates = [
    // --- ORDER TRANSITIONS ---
    NotificationTemplate(
      id: 'order_confirmed',
      eventType: 'order',
      status: 'confirmed',
      inAppTitle: 'Commission Authenticated & Confirmed',
      inAppBody: 'Your commission #{orderNumber} has been authenticated and entered into the master atelier ledger.',
      emailSubject: 'Commission Confirmed: #{orderNumber} — Ochanya Gili Atelier',
      emailHtml: _wrapEmailHtml(
        headline: 'Commission Authenticated',
        subheadline: 'MASTER ATELIER COMMISSION #{orderNumber}',
        body: 'Dear {customerName},<br><br>We are pleased to confirm receipt of your haute couture commission <strong>#{orderNumber}</strong>. Our couturiers have initiated textile reservations and pattern scaling in the Abuja atelier.',
        ctaText: 'VIEW COMMISSION TIMELINE',
        ctaUrl: 'https://ochanyagili.com/account/orders/{orderNumber}',
      ),
      pushTitle: 'Commission Authenticated',
      pushBody: 'Your commission #{orderNumber} has been confirmed into the atelier ledger.',
      actionUrl: '/account/orders/{orderNumber}',
    ),
    NotificationTemplate(
      id: 'order_processing',
      eventType: 'order',
      status: 'processing',
      inAppTitle: 'Textile Allocation & Pattern Drafting',
      inAppBody: 'Fabrics curated and anatomical block pattern drafted for commission #{orderNumber}.',
      emailSubject: 'Pattern Drafting & Silks Allocated: #{orderNumber}',
      emailHtml: _wrapEmailHtml(
        headline: 'Textiles Allocated',
        subheadline: 'COMMISSION #{orderNumber}',
        body: 'Dear {customerName},<br><br>Your bespoke pattern has been individually drafted according to your anatomical proportions. Pure silks and interlinings have been measured and prepared for precision cutting.',
        ctaText: 'TRACK ATELIER TIMELINE',
        ctaUrl: 'https://ochanyagili.com/account/orders/{orderNumber}',
      ),
      pushTitle: 'Silks Curated for #{orderNumber}',
      pushBody: 'Pattern drafting and textile allocation completed for your commission.',
      actionUrl: '/account/orders/{orderNumber}',
    ),
    NotificationTemplate(
      id: 'order_in_production',
      eventType: 'order',
      status: 'in_production',
      inAppTitle: 'Atelier Craftsmanship in Progress',
      inAppBody: 'Your garment #{orderNumber} has entered cutting, canvassing, and hand assembly by our master couturiers.',
      emailSubject: 'In Production: Hand Assembly of #{orderNumber}',
      emailHtml: _wrapEmailHtml(
        headline: 'Atelier Assembly in Progress',
        subheadline: 'HAND-CRAFTED COUTURE COMMISSION',
        body: 'Dear {customerName},<br><br>Master artisans have commenced hand-assembly of commission <strong>#{orderNumber}</strong>. Every seam, canvassed lapel, and sculptured hemline is shaped with meticulous atelier discipline.',
        ctaText: 'VIEW CRAFTSMANSHIP TIMELINE',
        ctaUrl: 'https://ochanyagili.com/account/orders/{orderNumber}',
      ),
      pushTitle: 'Garment in Production',
      pushBody: 'Commission #{orderNumber} is now in active hand-assembly at the atelier.',
      actionUrl: '/account/orders/{orderNumber}',
    ),
    NotificationTemplate(
      id: 'order_ready_for_fitting',
      eventType: 'order',
      status: 'ready_for_fitting',
      inAppTitle: 'Garment Ready for Private Fitting',
      inAppBody: 'Commission #{orderNumber} has completed primary assembly. Please reserve your private salon fitting session.',
      emailSubject: 'Private Salon Fitting Ready: #{orderNumber}',
      emailHtml: _wrapEmailHtml(
        headline: 'Ready for Salon Fitting',
        subheadline: 'PRIVATE ATELIER FITTING INVITATION',
        body: 'Dear {customerName},<br><br>Your garment <strong>#{orderNumber}</strong> has completed structure assembly. We invite you to reserve your private salon fitting session to perfect drape, ease, and line.',
        ctaText: 'RESERVE FITTING SESSION',
        ctaUrl: 'https://ochanyagili.com/account/appointments/book',
      ),
      pushTitle: 'Ready for Salon Fitting',
      pushBody: 'Commission #{orderNumber} is ready for your private atelier fitting.',
      actionUrl: '/account/appointments/book',
    ),
    NotificationTemplate(
      id: 'order_ready_for_delivery',
      eventType: 'order',
      status: 'ready_for_delivery',
      inAppTitle: 'Quality Inspection Complete',
      inAppBody: 'Commission #{orderNumber} has passed rigorous couture assessment and salon pressing. Ready for delivery.',
      emailSubject: 'Final Assessment Complete: #{orderNumber} Ready',
      emailHtml: _wrapEmailHtml(
        headline: 'Quality Assessment Passed',
        subheadline: 'SALON FINISHING & ARCHIVAL PACKAGING',
        body: 'Dear {customerName},<br><br>Commission <strong>#{orderNumber}</strong> has completed final salon pressing and rigorous quality verification. It is encased in protective archival garment storage awaiting delivery.',
        ctaText: 'REVIEW DELIVERY DETAILS',
        ctaUrl: 'https://ochanyagili.com/account/orders/{orderNumber}',
      ),
      pushTitle: 'Commission Ready for Delivery',
      pushBody: 'Final quality assessment complete for #{orderNumber}. Ready for dispatch.',
      actionUrl: '/account/orders/{orderNumber}',
    ),
    NotificationTemplate(
      id: 'order_shipped',
      eventType: 'order',
      status: 'shipped',
      inAppTitle: 'Commission Dispatched',
      inAppBody: 'Commission #{orderNumber} is secured in protective dust carrier and dispatched with our private courier.',
      emailSubject: 'Dispatched: Your Commission #{orderNumber} is En Route',
      emailHtml: _wrapEmailHtml(
        headline: 'Commission En Route',
        subheadline: 'PRIVATE COURIER DISPATCH',
        body: 'Dear {customerName},<br><br>Your couture garment <strong>#{orderNumber}</strong> is securely in transit with our private courier service.',
        ctaText: 'TRACK DELIVERY',
        ctaUrl: 'https://ochanyagili.com/account/orders/{orderNumber}',
      ),
      pushTitle: 'Commission Dispatched',
      pushBody: 'Commission #{orderNumber} has been dispatched with private courier.',
      actionUrl: '/account/orders/{orderNumber}',
    ),
    NotificationTemplate(
      id: 'order_delivered',
      eventType: 'order',
      status: 'delivered',
      inAppTitle: 'Commission Hand-Delivered',
      inAppBody: 'Commission #{orderNumber} has been safely presented. We trust your bespoke piece brings you joy.',
      emailSubject: 'Delivered: Master Commission #{orderNumber}',
      emailHtml: _wrapEmailHtml(
        headline: 'Commission Hand-Delivered',
        subheadline: 'A CELEBRATION OF CRAFTSMANSHIP',
        body: 'Dear {customerName},<br><br>We are delighted to confirm that commission <strong>#{orderNumber}</strong> has been presented to you. It has been an honor crafting this piece for you.',
        ctaText: 'VIEW COMMISSION ARCHIVE',
        ctaUrl: 'https://ochanyagili.com/account/orders/{orderNumber}',
      ),
      pushTitle: 'Commission Hand-Delivered',
      pushBody: 'Commission #{orderNumber} successfully presented. Thank you.',
      actionUrl: '/account/orders/{orderNumber}',
    ),
    NotificationTemplate(
      id: 'order_cancelled',
      eventType: 'order',
      status: 'cancelled',
      inAppTitle: 'Commission Cancelled',
      inAppBody: 'Commission #{orderNumber} has been marked as cancelled.',
      emailSubject: 'Commission Status Update: Cancelled #{orderNumber}',
      emailHtml: _wrapEmailHtml(
        headline: 'Commission Cancelled',
        subheadline: 'COMMISSION #{orderNumber}',
        body: 'Dear {customerName},<br><br>Commission <strong>#{orderNumber}</strong> has been cancelled. If you have questions or wish to reschedule, our concierge remains at your disposal.',
        ctaText: 'CONTACT CONCIERGE',
        ctaUrl: 'https://ochanyagili.com/contact',
      ),
      pushTitle: 'Commission Cancelled',
      pushBody: 'Commission #{orderNumber} has been cancelled.',
      actionUrl: '/account/orders/{orderNumber}',
    ),

    // --- CUSTOM REQUEST & QUOTE TRANSITIONS ---
    NotificationTemplate(
      id: 'custom_request_submitted',
      eventType: 'custom_request',
      status: 'submitted',
      inAppTitle: 'Bespoke Inquiry Received',
      inAppBody: 'Your custom atelier inquiry #{requestNumber} has been received. Our design studio is reviewing your specifications.',
      emailSubject: 'Bespoke Inquiry Received: #{requestNumber}',
      emailHtml: _wrapEmailHtml(
        headline: 'Bespoke Inquiry Received',
        subheadline: 'CUSTOM ATELIER COMMISSION',
        body: 'Dear {customerName},<br><br>Thank you for commissioning Ochanya Gili. We have received your bespoke inquiry for a <strong>{garmentType}</strong> (#{requestNumber}). Our head designer is reviewing your moodboards and notes.',
        ctaText: 'VIEW INQUIRY STATUS',
        ctaUrl: 'https://ochanyagili.com/account/custom-requests/{id}',
      ),
      pushTitle: 'Bespoke Inquiry Received',
      pushBody: 'Your custom inquiry #{requestNumber} is in review at the atelier.',
      actionUrl: '/account/custom-requests/{id}',
    ),
    NotificationTemplate(
      id: 'custom_request_quote_sent',
      eventType: 'custom_request',
      status: 'quote_sent',
      inAppTitle: 'Couture Quotation Ready',
      inAppBody: 'Your bespoke couture quotation for #{requestNumber} has been prepared. Review specifications & estimate in your account.',
      emailSubject: 'Couture Quotation Ready: #{requestNumber}',
      emailHtml: _wrapEmailHtml(
        headline: 'Couture Quotation Ready',
        subheadline: 'ESTIMATE & TEXTILE ALLOCATION',
        body: 'Dear {customerName},<br><br>Master Couturier Ochanya has prepared your formal quotation for bespoke commission <strong>#{requestNumber}</strong>. Please review line items, estimated delivery, and deposit terms.',
        ctaText: 'REVIEW & ACCEPT QUOTATION',
        ctaUrl: 'https://ochanyagili.com/account/custom-requests/{id}',
      ),
      pushTitle: 'Couture Quotation Ready',
      pushBody: 'Your bespoke quote for #{requestNumber} is ready for review.',
      actionUrl: '/account/custom-requests/{id}',
    ),
    NotificationTemplate(
      id: 'custom_request_customer_approved',
      eventType: 'custom_request',
      status: 'customer_approved',
      inAppTitle: 'Quotation Approved',
      inAppBody: 'Thank you for approving quotation #{requestNumber}. Textile reservations have commenced.',
      emailSubject: 'Quotation Approved: #{requestNumber}',
      emailHtml: _wrapEmailHtml(
        headline: 'Quotation Approved',
        subheadline: 'ATELIER DEPOSIT CONFIRMED',
        body: 'Dear {customerName},<br><br>We have recorded your formal acceptance of bespoke quotation <strong>#{requestNumber}</strong>. Silk bolt reservation and anatomical block preparation have been initiated.',
        ctaText: 'VIEW BESPOKE PROGRESS',
        ctaUrl: 'https://ochanyagili.com/account/custom-requests/{id}',
      ),
      pushTitle: 'Quote Approved',
      pushBody: 'Quotation #{requestNumber} approved. Creation has begun.',
      actionUrl: '/account/custom-requests/{id}',
    ),
    NotificationTemplate(
      id: 'custom_request_under_review',
      eventType: 'custom_request',
      status: 'under_review',
      inAppTitle: 'Bespoke Inquiry Under Review',
      inAppBody: 'Head designer Ochanya is curating silhouettes and initial sketches for #{requestNumber}.',
      emailSubject: 'Atelier Review: Bespoke Inquiry #{requestNumber}',
      emailHtml: _wrapEmailHtml(
        headline: 'Inquiry Under Review',
        subheadline: 'SILHOUETTE CURATION & TEXTILE SOURCING',
        body: 'Dear {customerName},<br><br>Our head designer is currently examining your bespoke request <strong>#{requestNumber}</strong>. We are assessing textile options and architectural tailoring specifications.',
        ctaText: 'VIEW INQUIRY DETAILS',
        ctaUrl: 'https://ochanyagili.com/account/custom-requests/{id}',
      ),
      pushTitle: 'Inquiry Under Review',
      pushBody: 'Atelier review is underway for custom inquiry #{requestNumber}.',
      actionUrl: '/account/custom-requests/{id}',
    ),
    NotificationTemplate(
      id: 'custom_request_in_production',
      eventType: 'custom_request',
      status: 'in_production',
      inAppTitle: 'Bespoke Garment in Production',
      inAppBody: 'Hand crafting and toile fitting preparation underway for #{requestNumber}.',
      emailSubject: 'In Production: Bespoke Commission #{requestNumber}',
      emailHtml: _wrapEmailHtml(
        headline: 'Bespoke Production Initiated',
        subheadline: 'HAND-CRAFTED ATELIER ASSEMBLY',
        body: 'Dear {customerName},<br><br>Your custom garment <strong>#{requestNumber}</strong> is now in active production. Master artisans are constructing the foundational toile and hand-pinning silk layers.',
        ctaText: 'TRACK COMMISSION',
        ctaUrl: 'https://ochanyagili.com/account/custom-requests/{id}',
      ),
      pushTitle: 'Custom Garment in Production',
      pushBody: 'Hand assembly is underway for bespoke piece #{requestNumber}.',
      actionUrl: '/account/custom-requests/{id}',
    ),
    NotificationTemplate(
      id: 'custom_request_ready_for_fitting',
      eventType: 'custom_request',
      status: 'ready_for_fitting',
      inAppTitle: 'Toile Ready for Private Fitting',
      inAppBody: 'Your bespoke garment #{requestNumber} is ready for salon fitting.',
      emailSubject: 'Fitting Invitation: Bespoke Commission #{requestNumber}',
      emailHtml: _wrapEmailHtml(
        headline: 'Fitting Suite Ready',
        subheadline: 'PRIVATE SALON TOILE FITTING',
        body: 'Dear {customerName},<br><br>Your bespoke garment <strong>#{requestNumber}</strong> is ready for your private fitting consultation. Please book an appointment with our master couturier.',
        ctaText: 'BOOK FITTING',
        ctaUrl: 'https://ochanyagili.com/account/appointments/book',
      ),
      pushTitle: 'Bespoke Fitting Ready',
      pushBody: 'Custom piece #{requestNumber} is ready for salon fitting.',
      actionUrl: '/account/appointments/book',
    ),
    NotificationTemplate(
      id: 'custom_request_completed',
      eventType: 'custom_request',
      status: 'completed',
      inAppTitle: 'Bespoke Commission Completed',
      inAppBody: 'Your bespoke garment #{requestNumber} is complete and presented.',
      emailSubject: 'Commission Complete: Bespoke Masterpiece #{requestNumber}',
      emailHtml: _wrapEmailHtml(
        headline: 'Bespoke Masterpiece Completed',
        subheadline: 'SOVEREIGN AFRICAN COUTURE',
        body: 'Dear {customerName},<br><br>We are pleased to celebrate the completion of your bespoke couture garment <strong>#{requestNumber}</strong>. It has been a privilege creating this architectural piece for you.',
        ctaText: 'VIEW COMMISSION ARCHIVE',
        ctaUrl: 'https://ochanyagili.com/account/custom-requests/{id}',
      ),
      pushTitle: 'Bespoke Commission Complete',
      pushBody: 'Your custom piece #{requestNumber} has been successfully completed.',
      actionUrl: '/account/custom-requests/{id}',
    ),

    // --- APPOINTMENT TRANSITIONS ---
    NotificationTemplate(
      id: 'appointment_confirmed',
      eventType: 'appointment',
      status: 'confirmed',
      inAppTitle: 'Salon Appointment Confirmed',
      inAppBody: 'Your private salon appointment on {date} at {time} has been confirmed.',
      emailSubject: 'Salon Appointment Confirmed: {date} at {time}',
      emailHtml: _wrapEmailHtml(
        headline: 'Private Salon Fitting Confirmed',
        subheadline: 'OCHANYA GILI ATELIER & SALON',
        body: 'Dear {customerName},<br><br>We look forward to welcoming you to our private salon on <strong>{date} at {time}</strong>. Our couture specialists will have your dedicated fitting suite prepared.',
        ctaText: 'VIEW APPOINTMENT DETAILS',
        ctaUrl: 'https://ochanyagili.com/account/appointments',
      ),
      pushTitle: 'Appointment Confirmed',
      pushBody: 'Your salon consultation on {date} at {time} is confirmed.',
      actionUrl: '/account/appointments',
    ),
    NotificationTemplate(
      id: 'appointment_reminder_24h',
      eventType: 'appointment',
      status: 'reminder_24h',
      inAppTitle: 'Fitting Tomorrow Reminder',
      inAppBody: 'Reminder: Your private salon consultation is scheduled for tomorrow on {date} at {time}.',
      emailSubject: 'Reminder: Your Fitting Tomorrow at {time}',
      emailHtml: _wrapEmailHtml(
        headline: 'Fitting Tomorrow',
        subheadline: 'OCHANYA GILI SALON REMINDER',
        body: 'Dear {customerName},<br><br>This is a courtesy reminder of your private salon fitting tomorrow, <strong>{date} at {time}</strong> at Plot 104, Maitama Luxury Enclave, Abuja.',
        ctaText: 'SALON LOCATION & DETAILS',
        ctaUrl: 'https://ochanyagili.com/account/appointments',
      ),
      pushTitle: 'Fitting Tomorrow',
      pushBody: 'Your atelier fitting is tomorrow on {date} at {time}.',
      actionUrl: '/account/appointments',
    ),
    NotificationTemplate(
      id: 'appointment_completed',
      eventType: 'appointment',
      status: 'completed',
      inAppTitle: 'Salon Fitting Completed',
      inAppBody: 'Thank you for visiting the Ochanya Gili salon. Fitting adjustments have been logged in your profile.',
      emailSubject: 'Thank You for Visiting the Salon: Fitting Completed',
      emailHtml: _wrapEmailHtml(
        headline: 'Fitting Completed',
        subheadline: 'ANATOMICAL ADJUSTMENTS LOGGED',
        body: 'Dear {customerName},<br><br>Thank you for visiting our salon. All pin markings and silhouette adjustments have been entered into the atelier ledger for precision execution.',
        ctaText: 'VIEW MEASUREMENTS PROFILE',
        ctaUrl: 'https://ochanyagili.com/account/measurements',
      ),
      pushTitle: 'Fitting Completed',
      pushBody: 'Thank you for visiting our salon. Notes have been logged.',
      actionUrl: '/account/appointments',
    ),
    NotificationTemplate(
      id: 'appointment_cancelled',
      eventType: 'appointment',
      status: 'cancelled',
      inAppTitle: 'Salon Appointment Cancelled',
      inAppBody: 'Your salon appointment scheduled for {date} at {time} has been cancelled.',
      emailSubject: 'Salon Appointment Cancelled: {date}',
      emailHtml: _wrapEmailHtml(
        headline: 'Appointment Cancelled',
        subheadline: 'OCHANYA GILI PRIVATE SALON',
        body: 'Dear {customerName},<br><br>Your salon appointment on <strong>{date} at {time}</strong> has been cancelled. If you wish to reschedule, our private concierge is available.',
        ctaText: 'RESCHEDULE APPOINTMENT',
        ctaUrl: 'https://ochanyagili.com/account/appointments/book',
      ),
      pushTitle: 'Appointment Cancelled',
      pushBody: 'Your salon consultation on {date} at {time} has been cancelled.',
      actionUrl: '/account/appointments',
    ),
  ];

  static NotificationTemplate? getTemplate(String eventType, String status) {
    for (final t in templates) {
      if (t.eventType == eventType && t.status == status) {
        return t;
      }
    }
    return null;
  }

  static String _wrapEmailHtml({
    required String headline,
    required String subheadline,
    required String body,
    required String ctaText,
    required String ctaUrl,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Ochanya Gili Haute Couture</title>
</head>
<body style="margin: 0; padding: 0; background-color: #FAFAFA; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; color: #1A1A1A;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #FAFAFA; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background-color: #FFFFFF; border: 1px solid #E0E0E0; padding: 48px 40px;">
          <!-- Brand Header -->
          <tr>
            <td align="center" style="padding-bottom: 32px; border-bottom: 1px solid #EAEAEA;">
              <h1 style="font-family: 'Playfair Display', Georgia, serif; font-size: 24px; letter-spacing: 4px; margin: 0; color: #1A1A1A;">OCHANYA GILI</h1>
              <p style="font-size: 10px; letter-spacing: 2px; color: #C9A96E; margin-top: 6px; text-transform: uppercase;">HAUTE COUTURE ATELIER</p>
            </td>
          </tr>

          <!-- Content Body -->
          <tr>
            <td style="padding-top: 36px; padding-bottom: 36px;">
              <p style="font-size: 11px; letter-spacing: 1.5px; font-weight: bold; color: #C9A96E; text-transform: uppercase; margin: 0 0 10px 0;">$subheadline</p>
              <h2 style="font-family: 'Playfair Display', Georgia, serif; font-size: 22px; margin: 0 0 20px 0; color: #1A1A1A; line-height: 1.3;">$headline</h2>
              <div style="font-size: 14px; line-height: 1.8; color: #444444; margin-bottom: 32px;">
                $body
              </div>
              <table cellpadding="0" cellspacing="0" style="margin-top: 24px;">
                <tr>
                  <td align="center" style="background-color: #1A1A1A; padding: 14px 28px;">
                    <a href="$ctaUrl" style="color: #FFFFFF; text-decoration: none; font-size: 12px; letter-spacing: 1.5px; font-weight: bold; text-transform: uppercase; display: inline-block;">$ctaText</a>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding-top: 32px; border-top: 1px solid #EAEAEA; text-align: center;">
              <p style="font-size: 11px; color: #888888; margin: 0 0 8px 0;">Plot 104, Maitama Luxury Enclave, Abuja, Nigeria</p>
              <p style="font-size: 11px; color: #888888; margin: 0;">Private Concierge: concierge@ochanyagili.com • +234 (0) 808 000 8888</p>
              <p style="font-size: 10px; color: #BBBBBB; margin-top: 16px;">© 2026 OCHANYA GILI. All rights reserved.</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }
}
