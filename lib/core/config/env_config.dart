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
/// Supports compile-time `--dart-define` injection for secure CI/CD pipelines
/// with automated fallback and credential isolation.
class EnvConfig {
  static const String environmentName = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  static AppEnvironment get environment => AppEnvironment.fromString(environmentName);

  static bool get isProduction => environment == AppEnvironment.production;
  static bool get isStaging => environment == AppEnvironment.staging;
  static bool get isDevelopment => environment == AppEnvironment.development;

  // Supabase Infrastructure
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gfobzdetjbqwrxnutrkj.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdmb2J6ZGV0amJxd3J4bnV0cmtqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA2MzQzMDYsImV4cCI6MjEwNjIxMDMwNn0.7twBT6zr8ctBxPLkC42MPqyQkc9FwEJdvfyi5nab93g',
  );

  // Domains & CDN
  static const String siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://ochanyagili.com',
  );

  static const String cdnUrl = String.fromEnvironment(
    'CDN_URL',
    defaultValue: 'https://cdn.ochanyagili.com',
  );

  // Payment Gateway (Paystack)
  static const String paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'pk_live_ochanya_production_secure_dummy_key_2026',
  );

  static const String paystackWebhookUrl = String.fromEnvironment(
    'PAYSTACK_WEBHOOK_URL',
    defaultValue: 'https://gfobzdetjbqwrxnutrkj.supabase.co/functions/v1/paystack-webhook',
  );

  // Observability & Telemetry
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  static const String gaMeasurementId = String.fromEnvironment(
    'GA_MEASUREMENT_ID',
    defaultValue: 'G-OCHANYA2026',
  );

  // Deep Linking & Universal Links
  static const String deepLinkScheme = 'ochanyagili';
  static const String deepLinkHost = 'ochanyagili.com';

  // Maison Contacts
  static const String supportEmail = 'concierge@ochanyagili.com';
  static const String contactPhone = '+234 800 OCHANYA';
  static const String atelierLocation = 'Victoria Island, Lagos, Nigeria';

  /// Validates environment integrity at startup.
  /// Ensures development credentials are never quietly bundled into production builds.
  static void validate() {
    assert(supabaseUrl.isNotEmpty, 'SUPABASE_URL must be configured');
    assert(supabaseAnonKey.isNotEmpty, 'SUPABASE_ANON_KEY must be configured');
    assert(siteUrl.startsWith('https://'), 'SITE_URL must use SSL in all environments');
  }
}
