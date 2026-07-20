import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/analyst_profile.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import 'session_cleanup_coordinator.dart';
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  AnalystProfile? _profile;
  bool _isLoading = true;
  String? _error;
  String _apiBaseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000');

  User? get user => _user;
  AnalystProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    ApiService.onForceLogout = signOut;
    _initAuthListener();
  }

  void _initAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      _user = session?.user;
      
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        if (_user != null) {
          await _bootstrapProfile(session!.accessToken);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _profile = null;
        _user = null;
        SessionCleanupCoordinator.performCleanup();
      }

      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _error = 'Authentication stream error: $error';
      notifyListeners();
    });
  }

  Future<void> _bootstrapProfile(String accessToken) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/api/v1/auth/bootstrap-profile');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _profile = AnalystProfile.fromJson(data['profile']);
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['detail'] ?? 'Failed to authorize profile';
        // If the backend refuses authorization, we should sign them out
        if (response.statusCode == 403) {
           await signOut();
        }
      }
    } catch (e) {
      _error = 'Network error during profile bootstrap: $e';
    }
  }

  String _mapAuthenticationError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'The email or password is incorrect.';
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

    return 'Sign-in could not be completed. Please try again.';
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
