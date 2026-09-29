import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/app.dart';
import 'package:ochanya_gili/core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase services
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: OchanyaGiliApp(),
    ),
  );
}
