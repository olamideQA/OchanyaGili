import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/core/security/input_sanitizer.dart';
import 'package:ochanya_gili/core/security/file_upload_validator.dart';
import 'package:ochanya_gili/core/security/secure_error_handler.dart';
import 'package:ochanya_gili/features/auth/domain/models/user_role.dart';

void main() {
  group('Loop 15: InputSanitizer Security Tests', () {
    test('strips malicious <script> tags and payloads completely', () {
      const payload = "Hello <script>alert('XSS attack')</script>World";
      expect(InputSanitizer.sanitize(payload), 'Hello World');
    });

    test('strips event handlers and javascript: pseudo-protocols', () {
      const handlerPayload = '<img src="x" onerror="alert(1)">Atelier Couture';
      expect(InputSanitizer.sanitize(handlerPayload), 'Atelier Couture');

      const jsUriPayload = '<a href="javascript:stealCookies()">Click here</a>';
      expect(InputSanitizer.sanitize(jsUriPayload), 'Click here');
    });

    test('sanitizes multiline customer notes while preserving line formatting', () {
      const rawNotes = "Please fit tightly around waist.\n<script>doBadThing()</script>\nSilk lining preferred.";
      final sanitized = InputSanitizer.sanitizeNotes(rawNotes);
      expect(sanitized, "Please fit tightly around waist.\n\nSilk lining preferred.");
    });

    test('handles null and empty inputs safely', () {
      expect(InputSanitizer.sanitize(null), '');
      expect(InputSanitizer.sanitize(''), '');
      expect(InputSanitizer.sanitizeNotes(null), '');
      expect(InputSanitizer.sanitizeNotes(''), '');
    });
  });

  group('Loop 15: FileUploadValidator Security Tests', () {
    test('rejects empty file uploads', () {
      final res = FileUploadValidator.validateImage(
        fileName: 'inspiration.jpg',
        byteLength: 0,
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('empty'));
    });

    test('rejects files exceeding 10MB upload threshold', () {
      final res = FileUploadValidator.validateImage(
        fileName: 'huge_gown.png',
        byteLength: 11 * 1024 * 1024,
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('exceeds'));
    });

    test('rejects unapproved file extensions (.exe, .php, .sh, .svg)', () {
      for (final ext in ['exe', 'php', 'sh', 'svg', 'html', 'bat']) {
        final res = FileUploadValidator.validateImage(
          fileName: 'malicious.$ext',
          byteLength: 1024,
        );
        expect(res.isValid, isFalse, reason: 'Failed to reject .$ext');
        expect(res.errorMessage, contains('Unsupported'));
      }
    });

    test('accepts valid atelier images (JPG, PNG, WebP)', () {
      for (final ext in ['jpg', 'jpeg', 'png', 'webp', 'PNG', 'JPG']) {
        final res = FileUploadValidator.validateImage(
          fileName: 'couture_dress.$ext',
          byteLength: 500 * 1024,
          mimeType: 'image/jpeg',
        );
        expect(res.isValid, isTrue, reason: 'Rejected valid extension .$ext');
      }
    });

    test('rejects mismatching non-image MIME types', () {
      final res = FileUploadValidator.validateImage(
        fileName: 'document.png',
        byteLength: 1024,
        mimeType: 'application/x-msdownload',
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('MIME'));
    });
  });

  group('Loop 15: SecureErrorHandler Tests', () {
    test('shields PostgreSQL check constraint violations with safe message', () {
      const rawError = 'new row for relation "orders" violates check constraint "chk_orders_total_non_negative"';
      final safeMessage = SecureErrorHandler.getUserMessage(rawError);
      expect(safeMessage, contains('validation rules'));
      expect(safeMessage.contains('chk_orders_total_non_negative'), isFalse);
    });

    test('shields unique constraint violations with safe message', () {
      const rawError = 'duplicate key value violates unique constraint "appointments_pkey"';
      final safeMessage = SecureErrorHandler.getUserMessage(rawError);
      expect(safeMessage, contains('already exists'));
    });

    test('shields role and security privilege violations with safe message', () {
      const rawError = 'Security Violation: Privileged role change rejected.';
      final safeMessage = SecureErrorHandler.getUserMessage(rawError);
      expect(safeMessage, contains('permission'));
    });

    test('provides clean network error fallback', () {
      const rawError = 'SocketException: OS Error: connection refused';
      final safeMessage = SecureErrorHandler.getUserMessage(rawError);
      expect(safeMessage, contains('Network connection'));
    });
  });

  group('Loop 15: Role-Based Authorization Tests', () {
    test('verifies admin and staff access boundaries', () {
      expect(UserRole.admin.canAccessAdmin, isTrue);
      expect(UserRole.designer.canAccessAdmin, isTrue);
      expect(UserRole.productionStaff.canAccessAdmin, isTrue);
      expect(UserRole.frontDesk.canAccessAdmin, isTrue);
      expect(UserRole.contentManager.canAccessAdmin, isTrue);
      expect(UserRole.customer.canAccessAdmin, isFalse);

      expect(UserRole.admin.isAdmin, isTrue);
      expect(UserRole.designer.isAdmin, isFalse);
      expect(UserRole.customer.isAdmin, isFalse);

      // admin and designer have their own getters, they are NOT staff
      expect(UserRole.admin.isStaff, isFalse);
      expect(UserRole.designer.isStaff, isFalse);
      expect(UserRole.customer.isStaff, isFalse);
      expect(UserRole.productionStaff.isStaff, isTrue);
      expect(UserRole.frontDesk.isStaff, isTrue);
      expect(UserRole.contentManager.isStaff, isTrue);

      expect(UserRole.designer.isDesigner, isTrue);
      expect(UserRole.admin.isDesigner, isFalse);
    });
  });
}
