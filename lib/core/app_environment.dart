import 'package:flutter/foundation.dart';

class AppEnvironment {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const bool enableGoogleAuth = bool.fromEnvironment(
    'ENABLE_GOOGLE_AUTH',
    defaultValue: false,
  );

  static void validate() {
    if (supabaseUrl.isEmpty ||
        supabasePublishableKey.isEmpty ||
        supabaseUrl.contains('dummy.supabase.co')) {
      throw StateError(
        'CyberSentinel authentication configuration is missing.',
      );
    }
  }
}
