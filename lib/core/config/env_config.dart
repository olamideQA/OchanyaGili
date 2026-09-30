enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromString(String env) {
    switch (env.toLowerCase().trim()) {
      case 'development':
      case 'dev':
        return AppEnvironment.development;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
      default:
        return AppEnvironment.production;
    }
  }
}

/// Unified Environment & Deployment Configuration
///
/// TEMPLATE NOTE: every value below ships EMPTY (or generic) on purpose.
/// There are no fallback credentials — a build without `--dart-define`
/// fails fast with a setup message instead of silently phoning home to
/// the template author's backend. Buyers configure via
/// `tool/local_env.json` (gitignored) + `tool/run_dev.ps1` /
/// `tool/build_web.ps1`, see TEMPLATE_SETUP.md.
class EnvConfig {
  static const String environmentName = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  static AppEnvironment get environment => AppEnvironment.fromString(environmentName);

  static bool get isProduction => environment == AppEnvironment.production;
  static bool get isStaging => environment == AppEnvironment.staging;
  static bool get isDevelopment => environment == AppEnvironment.development;

  // Supabase Infrastructure (REQUIRED — no defaults by design)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isBackendConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // Domains & CDN (buyer-owned)
  static const String siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: '',
  );

  static const String cdnUrl = String.fromEnvironment(
    'CDN_URL',
    defaultValue: '',
  );

  // Payment Gateway (Paystack — buyer keys)
  static const String paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: '',
  );

  static const String paystackWebhookUrl = String.fromEnvironment(
    'PAYSTACK_WEBHOOK_URL',
    defaultValue: '',
  );

  // Observability & Telemetry (buyer-owned, optional)
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  static const String gaMeasurementId = String.fromEnvironment(
    'GA_MEASUREMENT_ID',
    defaultValue: '',
  );

  // Deep Linking & Universal Links (TEMPLATE: buyer sets per brand)
  static const String deepLinkScheme = 'atelier';
  static const String deepLinkHost = '';

  // Maison Contacts (TEMPLATE: buyer-owned; real values live in backend settings)
  static const String supportEmail = '';
  static const String contactPhone = '';
  static const String atelierLocation = '';

  /// Validates environment integrity at startup.
  /// Throws a human-readable error (all modes, not just debug) so a
  /// misconfigured buyer build fails loudly instead of half-working.
  static void validate() {
    if (!isBackendConfigured) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_ANON_KEY are missing. '
        'Run tool/run_dev.ps1 (dev) or tool/build_web.ps1 (release) with '
        'tool/local_env.json configured. See TEMPLATE_SETUP.md.',
      );
    }
  }
}
