import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ochanya_gili/core/theme/app_theme.dart';
import 'package:ochanya_gili/features/auth/data/auth_repository.dart';
import 'package:ochanya_gili/features/auth/presentation/providers/auth_provider.dart';
import 'package:ochanya_gili/features/account/data/customer_account_repository.dart';

class CustomerSettingsScreen extends ConsumerStatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  ConsumerState<CustomerSettingsScreen> createState() =>
      _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState
    extends ConsumerState<CustomerSettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;
  String? _statusMessage;
  bool _isSuccess = false;

  // Preferences
  String _preferredUnit = 'inches';
  bool _emailNotifications = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile(String userId) async {
    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    try {
      final repo = ref.read(customerAccountRepositoryProvider);
      await repo.updateProfile(
        profileId: userId,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      // Refresh auth profile
      ref.invalidate(currentUserProvider);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSuccess = true;
          _statusMessage = 'Profile updated successfully.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSuccess = false;
          _statusMessage = 'Failed to update profile: $e';
        });
      }
    }
  }

  Future<void> _handlePasswordReset(String email) async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset instructions sent to $email'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: userAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: colors.primaryText)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text('Please sign in to view settings.',
                  style: TextStyle(color: colors.primaryText)),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'PREFERENCES & SECURITY',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.5,
                        color: colors.accentVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Account Settings',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Section 1: Personal Details
                    _buildSectionCard(
                      title: 'PERSONAL PROFILE',
                      colors: colors,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: _inputDecoration('Full Name', colors),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phoneController,
                            decoration:
                                _inputDecoration('Phone Number', colors),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller:
                                TextEditingController(text: user.email),
                            readOnly: true,
                            decoration: _inputDecoration(
                              'Email Address (Authoritative)',
                              colors,
                              helperText:
                                  'Associated with your Supabase atelier account',
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_statusMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              color: _isSuccess
                                  ? colors.success.withValues(alpha: 0.1)
                                  : colors.error.withValues(alpha: 0.1),
                              child: Row(
                                children: [
                                  Icon(
                                    _isSuccess
                                        ? Icons.check_circle_outline
                                        : Icons.error_outline,
                                    color: _isSuccess
                                        ? colors.success
                                        : colors.error,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _statusMessage!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _isSuccess
                                            ? colors.success
                                            : colors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.accent,
                              foregroundColor: colors.onAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero),
                            ),
                            onPressed: _isSaving
                                ? null
                                : () => _handleSaveProfile(user.id),
                            child: _isSaving
                                ? SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.onAccent,
                                    ),
                                  )
                                : const Text(
                                    'SAVE CHANGES',
                                    style: TextStyle(
                                        fontSize: 11,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Section 2: Atelier Preferences
                    _buildSectionCard(
                      title: 'ATELIER PREFERENCES',
                      colors: colors,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Measurement Units',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colors.primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Default unit for custom anatomical profiling',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: colors.secondaryText),
                                  ),
                                ],
                              ),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                      value: 'inches',
                                      label: Text('Inches (in)')),
                                  ButtonSegment(
                                      value: 'cm', label: Text('CM')),
                                ],
                                selected: {_preferredUnit},
                                onSelectionChanged: (val) {
                                  setState(() => _preferredUnit = val.first);
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Production & Fitting Updates',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.primaryText,
                              ),
                            ),
                            subtitle: Text(
                              'Receive email alerts on status milestones & fittings',
                              style: TextStyle(
                                  fontSize: 12, color: colors.secondaryText),
                            ),
                            value: _emailNotifications,
                            activeThumbColor: colors.accentVariant,
                            onChanged: (val) {
                              setState(() => _emailNotifications = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Section 3: Security & Session
                    _buildSectionCard(
                      title: 'SECURITY & SESSION',
                      colors: colors,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Password & Authentication',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colors.primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Request a secure password reset link',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: colors.secondaryText),
                                  ),
                                ],
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colors.primaryText,
                                  side: BorderSide(color: colors.border),
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero),
                                ),
                                onPressed: () =>
                                    _handlePasswordReset(user.email),
                                child: const Text('RESET PASSWORD',
                                    style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sign Out of Atelier',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colors.error,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Terminate active session on this device',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: colors.secondaryText),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.error,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero),
                                ),
                                onPressed: _handleLogout,
                                child: const Text(
                                  'SIGN OUT',
                                  style: TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 1.0,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required AppColorTokens colors,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: colors.accentVariant,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, AppColorTokens colors,
      {String? helperText}) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      labelStyle: TextStyle(fontSize: 12, color: colors.secondaryText),
      filled: true,
      fillColor: colors.surfaceVariant,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
