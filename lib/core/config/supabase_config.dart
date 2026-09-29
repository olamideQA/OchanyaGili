import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/core/config/env_config.dart';
import 'package:ochanya_gili/core/utils/logger.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      EnvConfig.validate();
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: EnvConfig.supabaseAnonKey,
      );
      AppLogger.i('Supabase initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to initialize Supabase', e, stackTrace);
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
