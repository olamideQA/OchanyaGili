import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ochanya_gili/features/auth/data/auth_repository.dart';
import 'package:ochanya_gili/features/auth/domain/models/app_user.dart';
import 'package:ochanya_gili/features/auth/domain/models/user_role.dart';

final authStateProvider = StreamProvider<supabase.AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  // Watch auth changes so currentUser re-evaluates on login/logout
  ref.watch(authStateProvider);
  final repository = ref.watch(authRepositoryProvider);
  return repository.getCurrentUser();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user != null;
});

final userRoleProvider = Provider<UserRole>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user?.role ?? UserRole.customer;
});
