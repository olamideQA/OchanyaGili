import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/core/config/env_config.dart';
import 'package:ochanya_gili/core/services/push_notification_service.dart';

void main() {
  group('Loop 17: Environment & Production Deployment Tests', () {
    test('EnvConfig parses environments accurately', () {
      expect(AppEnvironment.fromString('production'), AppEnvironment.production);
      expect(AppEnvironment.fromString('prod'), AppEnvironment.production);
      expect(AppEnvironment.fromString('staging'), AppEnvironment.staging);
      expect(AppEnvironment.fromString('stage'), AppEnvironment.staging);
      expect(AppEnvironment.fromString('development'), AppEnvironment.development);
      expect(AppEnvironment.fromString('dev'), AppEnvironment.development);
      expect(AppEnvironment.fromString('unknown'), AppEnvironment.production); // Safe default
    });

    test('EnvConfig default configuration satisfies production requirements', () {
      expect(EnvConfig.supabaseUrl, isNotEmpty);
      expect(EnvConfig.supabaseAnonKey, isNotEmpty);
      expect(EnvConfig.siteUrl, 'https://ochanyagili.com');
      expect(EnvConfig.cdnUrl, 'https://cdn.ochanyagili.com');
      expect(EnvConfig.deepLinkScheme, 'ochanyagili');
      expect(EnvConfig.deepLinkHost, 'ochanyagili.com');
      expect(EnvConfig.paystackWebhookUrl, contains('paystack-webhook'));
    });

    test('EnvConfig.validate passes for valid configuration', () {
      expect(() => EnvConfig.validate(), returnsNormally);
    });

    test('PushNotificationService platform returns valid platform identifier', () {
      final platform = PushNotificationService.currentPlatform;
      expect(['web', 'android', 'ios'].contains(platform), isTrue);
    });
  });

  group('Loop 17: Mobile Configuration Integrity Tests', () {
    test('AndroidManifest.xml contains required permissions, brand label, and deep links', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue, reason: 'AndroidManifest.xml must exist');

      final content = manifestFile.readAsStringSync();
      expect(content, contains('android:label="Ochanya Gili"'));
      expect(content, contains('android.permission.INTERNET'));
      expect(content, contains('android.permission.CAMERA'));
      expect(content, contains('android.permission.POST_NOTIFICATIONS'));
      expect(content, contains('android:scheme="ochanyagili"'));
      expect(content, contains('android:host="ochanyagili.com"'));
      expect(content, contains('flutter_deeplinking_enabled'));
    });

    test('iOS Info.plist contains brand name, camera/photo usage, and URL scheme', () {
      final plistFile = File('ios/Runner/Info.plist');
      expect(plistFile.existsSync(), isTrue, reason: 'Info.plist must exist');

      final content = plistFile.readAsStringSync();
      expect(content, contains('<string>Ochanya Gili</string>'));
      expect(content, contains('NSCameraUsageDescription'));
      expect(content, contains('NSPhotoLibraryUsageDescription'));
      expect(content, contains('<string>ochanyagili</string>'));
      expect(content, contains('FlutterDeepLinkingEnabled'));
    });

    test('Web hosting artifacts are configured for SPA routing', () {
      final vercelFile = File('vercel.json');
      expect(vercelFile.existsSync(), isTrue);
      expect(vercelFile.readAsStringSync(), contains('/index.html'));

      final redirectsFile = File('web/_redirects');
      expect(redirectsFile.existsSync(), isTrue);
      expect(redirectsFile.readAsStringSync(), contains('/index.html'));

      final manifestFile = File('web/manifest.json');
      expect(manifestFile.existsSync(), isTrue);
      expect(manifestFile.readAsStringSync(), contains('Ochanya Gili'));
    });

    test('.gitignore excludes secret keys and credentials', () {
      final gitignore = File('.gitignore');
      expect(gitignore.existsSync(), isTrue);
      final content = gitignore.readAsStringSync();
      expect(content, contains('*.keystore'));
      expect(content, contains('*.jks'));
      expect(content, contains('*secret*'));
      expect(content, contains('google-services.json'));
    });
  });
}
