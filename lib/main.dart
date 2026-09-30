import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ochanya_gili/app.dart';
import 'package:ochanya_gili/core/config/env_config.dart';
import 'package:ochanya_gili/core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fail loudly (all modes) when backend keys are missing instead of
  // booting a half-working app. See TEMPLATE_SETUP.md.
  try {
    EnvConfig.validate();
  } catch (e) {
    runApp(_MisconfiguredApp(message: e.toString()));
    return;
  }

  // Initialize Supabase services
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: OchanyaGiliApp(),
    ),
  );
}

/// Plain error screen shown when --dart-define keys were not provided.
class _MisconfiguredApp extends StatelessWidget {
  final String message;
  const _MisconfiguredApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backend not configured',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(message, style: const TextStyle(height: 1.6)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
