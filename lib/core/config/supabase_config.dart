import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/core/config/env_config.dart';
import 'package:ochanya_gili/core/utils/logger.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      EnvConfig.validate();
      // Never let backend trouble block first paint: a hanging init leaves
      // the web splash spinner forever, so cap the wait and continue on
      // demo/local data paths downstream.
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: EnvConfig.supabaseAnonKey,
      ).timeout(const Duration(seconds: 15));
      AppLogger.i('Supabase initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to initialize Supabase', e, stackTrace);
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
