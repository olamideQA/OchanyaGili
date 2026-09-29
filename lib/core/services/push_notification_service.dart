import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/core/config/supabase_config.dart';
import 'package:ochanya_gili/core/utils/logger.dart';

/// Service managing mobile and web push notification device tokens.
/// Reusable across Android, iOS, and Web platforms.
class PushNotificationService {
  final SupabaseClient _client;

  PushNotificationService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  /// Returns the normalized platform string: 'android', 'ios', or 'web'
  static String get currentPlatform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'web';
    }
  }

  /// Registers or refreshes a device token in Supabase
  Future<bool> registerDevice({
    required String token,
    String? deviceName,
    String? appVersion = '1.0.0+1',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      AppLogger.w('Cannot register device token: User is not authenticated');
      return false;
    }

    try {
      await _client.from('user_devices').upsert(
        {
          'profile_id': user.id,
          'device_token': token,
          'platform': currentPlatform,
          'device_name': deviceName ?? (kIsWeb ? 'Browser Client' : 'Mobile Client'),
          'app_version': appVersion,
          'is_active': true,
          'last_active_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'profile_id,device_token',
      );
      AppLogger.i('Push notification device token registered successfully for $currentPlatform');
      return true;
    } catch (e, st) {
      AppLogger.e('Failed to register push device token', e, st);
      return false;
    }
  }

  /// Deactivates a device token upon user logout
  Future<bool> unregisterDevice(String token) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client
          .from('user_devices')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('profile_id', user.id)
          .eq('device_token', token);
      AppLogger.i('Device token unregistered on logout');
      return true;
    } catch (e, st) {
      AppLogger.e('Failed to unregister device token', e, st);
      return false;
    }
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});
