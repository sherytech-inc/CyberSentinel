import 'dart:async';
import 'dart:convert';

import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'package:cybersentinel/core/sidecar/sidecar_manager_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/analyst_profile.dart';
import '../services/websocket_service.dart';
import 'session_cleanup_coordinator.dart';

typedef RefreshBootstrapSession = Future<Session?> Function();
typedef BootstrapWithAccessToken = Future<void> Function(String accessToken);

class AuthSessionExpiredException implements Exception {
  const AuthSessionExpiredException();
}

class AuthBootstrapCoordinator {
  Future<void>? _inFlight;

  bool get isInFlight => _inFlight != null;

  Future<void> run(
    Session session, {
    required RefreshBootstrapSession refreshSession,
    required BootstrapWithAccessToken bootstrap,
  }) {
    final active = _inFlight;
    if (active != null) return active;

    final operation = _run(
      session,
      refreshSession: refreshSession,
      bootstrap: bootstrap,
    );
    _inFlight = operation;
    return operation.whenComplete(() {
      if (identical(_inFlight, operation)) {
        _inFlight = null;
      }
    });
  }

  Future<void> _run(
    Session session, {
    required RefreshBootstrapSession refreshSession,
    required BootstrapWithAccessToken bootstrap,
  }) async {
    var activeSession = session;
    if (activeSession.isExpired) {
      final refreshedSession = await refreshSession();
      if (refreshedSession == null || refreshedSession.isExpired) {
        throw const AuthSessionExpiredException();
      }
      activeSession = refreshedSession;
    }
    await bootstrap(activeSession.accessToken);
  }
}

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthBootstrapCoordinator _bootstrapCoordinator =
      AuthBootstrapCoordinator();
  User? _user;
  AnalystProfile? _profile;
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  AnalystProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    LocalAgentClient.onForceLogout = signOut;
    _initAuthListener();
  }

  void _initAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      _user = session?.user;

      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        if (_user != null) {
          await _bootstrapProfileForSession(session!);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _profile = null;
        _user = null;
        _error = null;
        SessionCleanupCoordinator.performCleanup();
      }

      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      if (kDebugMode) {
        debugPrint('Authentication stream error: $error');
      }

      _error = 'The authentication session could not be restored.';
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _bootstrapProfileForSession(Session session) async {
    try {
      await _bootstrapCoordinator.run(
        session,
        refreshSession: () async {
          try {
            return (await _supabase.auth.refreshSession()).session;
          } catch (_) {
            return null;
          }
        },
        bootstrap: _bootstrapProfile,
      );
    } on AuthSessionExpiredException {
      _profile = null;
      _error = 'Your session has expired. Please sign in again.';
    }
  }

  Future<void> _bootstrapProfile(String accessToken) async {
    _error = null;
    _profile = null;

    try {
      final uri = Uri.parse(
        '${LocalAgentClient.baseUrl}/api/v1/auth/bootstrap-profile',
      );

      final headers = <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final localToken = SidecarManager().localToken;
      if (localToken != null && localToken.isNotEmpty) {
        headers['X-CyberSentinel-Local-Token'] = localToken;
      }

      final response = await http
          .post(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      final responseData = _tryDecodeJsonObject(response.body);

      if (response.statusCode == 200) {
        final profileData = responseData?['profile'];

        if (profileData is! Map) {
          throw const FormatException('Profile response is missing.');
        }

        _profile = AnalystProfile.fromJson(
          Map<String, dynamic>.from(profileData),
        );
        _error = null;
        return;
      }

      _error = _profileBootstrapMessage(
        statusCode: response.statusCode,
        responseData: responseData,
      );
    } on TimeoutException {
      _error =
          'The profile service took too long to respond. Please try again.';
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Profile bootstrap failed: $error');
      }

      _error =
          'The profile service is temporarily unavailable. Please try again.';
    }
  }

  Future<void> retryProfileBootstrap() async {
    final session = _supabase.auth.currentSession;

    if (session == null) {
      _error = 'Your session has expired. Please sign in again.';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      await _bootstrapProfileForSession(session);
    } finally {
      _setLoading(false);
    }
  }

  Map<String, dynamic>? _tryDecodeJsonObject(String body) {
    final trimmed = body.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(trimmed);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // The backend may return a plain-text 500 response.
      // Never expose a JSON FormatException to the user.
    }

    return null;
  }

  String _profileBootstrapMessage({
    required int statusCode,
    required Map<String, dynamic>? responseData,
  }) {
    final detail = responseData?['detail'];

    if (statusCode == 401) {
      if (detail == 'authenticated_email_missing') {
        return 'The signed-in account does not provide a valid email address.';
      }
      return 'Your session has expired. Please sign in again.';
    }

    if (statusCode == 403) {
      if (detail == 'account_disabled') {
        return 'Your CyberSentinel account is currently disabled.';
      }

      return 'This account is not authorized to access CyberSentinel.';
    }

    if (statusCode == 503) {
      return 'The profile service is temporarily unavailable. Please try again.';
    }

    return 'Your CyberSentinel profile could not be loaded. Please try again.';
  }

  String _mapAuthenticationError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'The email or password is incorrect. (If you just registered, you may need to confirm your email).';
    }
    if (message.contains('rate limit') ||
        message.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (message.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('dummy.supabase.co') ||
        message.contains('authentication configuration')) {
      return 'The authentication service is not configured.';
    }
    if (message.contains('failed to fetch') ||
        message.contains('clientexception') ||
        message.contains('network')) {
      return 'Unable to connect to the authentication service.';
    }
    if (message.contains('not authorized')) {
      return 'This account is not authorized to access CyberSentinel.';
    }

    return 'Authentication failed: ${error.toString().replaceAll("AuthApiException(message: ", "").replaceAll(")", "")}';
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) {
        _error = null;
        return true;
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Authentication failed: $error');
      }
      _error = _mapAuthenticationError(error);
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> signUp(String email, String password,
      {String? displayName}) async {
    _setLoading(true);
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
      if (res.user != null) {
        _error = null;
        return true;
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Registration failed: $error');
      }
      _error = _mapAuthenticationError(error);
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin,
      );
      // OAuth flow redirects the browser, so this function might not return
      // in the same way on Web.
      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Authentication failed: $error');
      }
      _error = _mapAuthenticationError(error);
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      _error = null;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'An unexpected error occurred.';
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _supabase.auth.signOut();
      _profile = null;
      _user = null;
      _error = null;
      WebSocketService().disconnect();
      SessionCleanupCoordinator.performCleanup();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
