import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ochanya_gili/features/auth/domain/models/app_user.dart';
import 'package:ochanya_gili/features/auth/domain/models/user_role.dart';

class AuthRepository {
  final supabase.SupabaseClient _client;

  AuthRepository(this._client);

  Stream<supabase.AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  supabase.User? get currentAuthUser => _client.auth.currentUser;

  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  Future<supabase.AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<AppUser?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        return AppUser(
          id: user.id,
          email: user.email ?? '',
          name: user.userMetadata?['full_name'] as String? ?? user.userMetadata?['name'] as String? ?? '',
          role: UserRole.customer,
          createdAt: DateTime.tryParse(user.createdAt),
        );
      }

      return AppUser.fromJson(response);
    } catch (_) {
      return AppUser(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['full_name'] as String? ?? user.userMetadata?['name'] as String? ?? '',
        role: UserRole.customer,
        createdAt: DateTime.tryParse(user.createdAt),
      );
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(supabase.Supabase.instance.client);
});
