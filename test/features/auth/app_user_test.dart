import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/features/auth/domain/models/app_user.dart';
import 'package:ochanya_gili/features/auth/domain/models/user_role.dart';

void main() {
  group('AppUser tests', () {
    test('fromJson and toJson round-trip', () {
      final user = AppUser(
        id: 'usr-123',
        email: 'client@ochanyagili.com',
        name: 'Ochanya Test',
        role: UserRole.customer,
        phone: '+2348000000000',
        avatarUrl: 'https://example.com/avatar.jpg',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final json = user.toJson();
      final parsed = AppUser.fromJson(json);

      expect(parsed.id, user.id);
      expect(parsed.email, user.email);
      expect(parsed.name, user.name);
      expect(parsed.role, user.role);
      expect(parsed.phone, user.phone);
      expect(parsed.avatarUrl, user.avatarUrl);
      expect(parsed.createdAt, user.createdAt);
      expect(parsed, equals(user));
    });

    test('copyWith updates properties properly', () {
      const user = AppUser(
        id: 'usr-1',
        email: 'test@ochanya.com',
        name: 'Initial Name',
        role: UserRole.customer,
      );

      final updated = user.copyWith(
        name: 'Updated Name',
        role: UserRole.designer,
      );

      expect(updated.name, 'Updated Name');
      expect(updated.role, UserRole.designer);
      expect(updated.id, 'usr-1');
      expect(updated.email, 'test@ochanya.com');
    });
  });
}
