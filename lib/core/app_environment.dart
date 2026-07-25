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

  // Sidecar explicitly requested configurations
  static const desktopBackendMode = String.fromEnvironment(
    'DESKTOP_BACKEND_MODE',
    defaultValue: 'external',
  );

  static const desktopBackendPython = String.fromEnvironment(
    'DESKTOP_BACKEND_PYTHON',
    defaultValue: '',
  );

  static const desktopBackendWorkdir = String.fromEnvironment(
    'DESKTOP_BACKEND_WORKDIR',
    defaultValue: '',
  );

  static const bundledBackendRelativePath = String.fromEnvironment(
    'BUNDLED_BACKEND_RELATIVE_PATH',
    defaultValue: 'cybersentinel_backend/cybersentinel_backend',
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
