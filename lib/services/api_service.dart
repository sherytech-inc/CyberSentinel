import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_environment.dart';

/// Centralized HTTP client for all CyberSentinel backend API calls.
/// Configurable base URL, 15-second timeout, and structured error handling.
class ApiService {
  static String _baseUrl = AppEnvironment.apiBaseUrl;
  static final Duration _timeout = const Duration(seconds: 15);
  static const _uuid = Uuid();

  /// Update the base URL (e.g. from Settings screen).
  static void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get baseUrl => _baseUrl;

  // ── Dashboard ─────────────────────────────────────────────────────────────

  /// Fetch aggregated dashboard statistics.
  static Future<Map<String, dynamic>> getDashboardStats() async {
    return await _get('/api/v1/dashboard/stats');
  }

  // ── Packets ───────────────────────────────────────────────────────────────

  /// Fetch paginated packet history.
  static Future<Map<String, dynamic>> getPackets({
    int page = 1,
    int pageSize = 50,
  }) async {
    return await _get('/api/v1/packets?page=$page&page_size=$pageSize');
  }

  // ── Firewall Logs ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> fetchFirewallLogs(
      {int page = 1, int pageSize = 50}) async {
    return await _get('/api/v1/operations/firewall?page=$page&page_size=$pageSize');
  }

  static Future<Map<String, dynamic>> fetchFirewallActions(
      {int page = 1, int pageSize = 50}) async {
    return await _get('/api/v1/firewall-action/actions?page=$page&page_size=$pageSize');
  }

  // ── Threats ───────────────────────────────────────────────────────────────

  /// Fetch paginated threat scores.
  static Future<Map<String, dynamic>> getThreats({
    int page = 1,
    int pageSize = 50,
  }) async {
    return await _get('/api/v1/threats?page=$page&page_size=$pageSize');
  }

  /// Fetch threat statistics (counts).
  static Future<Map<String, dynamic>> getThreatStats() async {
    return await _get('/api/v1/threats/stats');
  }

  /// Fetch high-severity threats (score 71-90).
  static Future<Map<String, dynamic>> getHighThreats({
    int page = 1,
    int pageSize = 50,
  }) async {
    return await _get('/api/v1/threats/high?page=$page&page_size=$pageSize');
  }

  /// Fetch critical threats (score > 90).
  static Future<Map<String, dynamic>> getCriticalThreats({
    int page = 1,
    int pageSize = 50,
  }) async {
    return await _get(
        '/api/v1/threats/critical?page=$page&page_size=$pageSize');
  }

  /// Fetch full threat history.
  static Future<Map<String, dynamic>> getThreatHistory({
    int page = 1,
    int pageSize = 100,
  }) async {
    return await _get('/api/v1/threats/history?page=$page&page_size=$pageSize');
  }

  // ── IP Analysis (Unified Analyze API) ─────────────────────────────────────

  /// Run unified multi-model analysis on an IP address.
  static Future<Map<String, dynamic>> analyzeIP(String ip) async {
    return await _post('/api/v1/analyze', body: {
      'ip': ip,
      'flow_features': {
        'flow_duration': 0.0,
        'total_fwd_packets': 0,
        'total_backward_packets': 0,
        'flow_bytes_per_second': 0.0,
        'flow_packets_per_second': 0.0,
        'packet_length_mean': 0.0,
        'packet_length_std': 0.0,
        'flow_iat_mean': 0.0,
        'flow_iat_std': 0.0,
        'destination_port': 0,
        'protocol': 'TCP',
      },
    });
  }

  // ── Firewall Actions ──────────────────────────────────────────────────────

  /// Block an IP address.
  static Future<Map<String, dynamic>> blockIP(String ip,
      {String? reason}) async {
    return await _post('/api/v1/firewall/block', body: {
      'ip': ip,
      'reason': reason,
    });
  }

  /// Unblock an IP address.
  static Future<Map<String, dynamic>> unblockIP(String ip) async {
    return await _post('/api/v1/firewall/unblock', body: {'ip': ip});
  }

  /// Whitelist an IP address.
  static Future<Map<String, dynamic>> whitelistIP(String ip) async {
    return await _post('/api/v1/firewall/whitelist', body: {'ip': ip});
  }

  // ── Capture Control ───────────────────────────────────────────────────────

  /// Get current capture service status.
  static Future<Map<String, dynamic>> getCaptureStatus() async {
    return await _get('/api/v1/capture/status');
  }

  /// Start live packet capture.
  static Future<Map<String, dynamic>> startCapture({
    String interfaceName = 'en0',
    String? bpfFilter,
  }) async {
    final body = <String, dynamic>{'interface': interfaceName};
    if (bpfFilter != null) body['bpf_filter'] = bpfFilter;
    return await _post('/api/v1/capture/start', body: body);
  }

  /// Stop live packet capture.
  static Future<Map<String, dynamic>> stopCapture() async {
    return await _post('/api/v1/capture/stop');
  }

  // ── Copilot Context ───────────────────────────────────────────────────────

  /// Get AI copilot context summary.
  static Future<Map<String, dynamic>> getCopilotContext() async {
    return await _get('/api/v1/copilot/context');
  }

  /// Send a chat message to the AI analyst.
  static Future<Map<String, dynamic>> sendChatMessage(
      String sessionId, String message) async {
    return await _post('/api/v1/copilot/chat', body: {
      'session_id': sessionId,
      'message': message,
    });
  }

  static Future<Map<String, dynamic>> uploadFirewallLogs(
      String fileName, List<int> bytes) async {
    try {
      final response = await _sendAuthenticated((headers) async {
        final request = http.MultipartRequest(
            'POST', Uri.parse('$_baseUrl/api/v1/operations/firewall/upload'));
        request.headers.addAll(headers);
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
          ),
        );
        final streamedResponse = await request.send().timeout(_timeout);
        return http.Response.fromStream(streamedResponse);
      }, allowRefreshRetry: true);
      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Scan a target (file or URL) for viruses.
  static Future<Map<String, dynamic>> scanVirus(
      String target, String type) async {
    return await _post(
        '/api/v1/virus/scan?target=${Uri.encodeQueryComponent(target)}&type=$type');
  }

  /// Scan a file using multipart upload to backend (backend hashes it).
  static Future<Map<String, dynamic>> scanVirusFile(
      String fileName, List<int> bytes) async {
    try {
      final response = await _sendAuthenticated((headers) async {
        final request = http.MultipartRequest(
            'POST', Uri.parse('$_baseUrl/api/v1/virus/scan-file'));
        request.headers.addAll(headers);
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
          ),
        );
        final streamedResponse = await request.send().timeout(_timeout);
        return http.Response.fromStream(streamedResponse);
      }, allowRefreshRetry: true);
      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  // ── Threat Response Center ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getResponseOverview() async {
    return await _get('/api/v1/response/overview');
  }

  static Future<Map<String, dynamic>> getResponseThreats(
      {int page = 1, int pageSize = 50}) async {
    return await _get(
        '/api/v1/response/threats?page=$page&page_size=$pageSize');
  }

  static Future<Map<String, dynamic>> investigateThreat(String alertId) async {
    return await _post('/api/v1/response/threats/$alertId/investigate');
  }

  static Future<Map<String, dynamic>> getThreatExplanation(String alertId) async {
    return await _get('/api/v1/response/threats/$alertId/explanation');
  }

  // ── Settings & Integrations ────────────────────────────────────────────────
  
  static Future<Map<String, dynamic>> getIntegrations() async {
    return await _get('/api/v1/settings/integrations');
  }
  
  static Future<Map<String, dynamic>> testIntegration(String provider) async {
    return await _post('/api/v1/settings/integrations/$provider/test');
  }

  // ── Helper Methods ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDemoStatus() async {
    return await _get('/api/v1/demo/status');
  }

  static Future<Map<String, dynamic>> triggerDemoMode(String scenario) async {
    return await _post('/api/v1/demo/load?scenario=$scenario');
  }

  static Future<Map<String, dynamic>> resetDemoMode(String runId) async {
    return await _delete('/api/v1/demo/reset?run_id=$runId');
  }

  static Future<List<dynamic>> getThreatNotes(String alertId) async {
    try {
      final res = await _get('/api/v1/response/threats/$alertId/notes');
      return res['items'] ?? res['notes'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> addThreatNote(String alertId, String note, {String author = 'Analyst'}) async {
    return await _post('/api/v1/response/threats/$alertId/notes', body: {
      'note': note,
      'author': author,
    });
  }

  static Future<Map<String, dynamic>> resolveThreat(String alertId,
      {String? notes}) async {
    return await _post('/api/v1/response/threats/$alertId/resolve',
        body: notes != null ? {'notes': notes} : {});
  }

  static Future<Map<String, dynamic>> ignoreThreat(String alertId,
      {String? notes}) async {
    return await _post('/api/v1/response/threats/$alertId/ignore',
        body: notes != null ? {'notes': notes} : {});
  }

  static Future<Map<String, dynamic>> responseBlockIP(String ip,
      {String? reason}) async {
    return await _post('/api/v1/response/block',
        body: {'ip': ip, 'reason': reason});
  }

  static Future<Map<String, dynamic>> responseUnblockIP(String ip,
      {String? reason}) async {
    return await _post('/api/v1/response/unblock',
        body: {'ip': ip, 'reason': reason});
  }

  static Future<Map<String, dynamic>> getResponseHistory(
      {int page = 1, int pageSize = 50}) async {
    return await _get(
        '/api/v1/response/history?page=$page&page_size=$pageSize');
  }

  static Future<Map<String, dynamic>> getResponseAuditLog(
      {int page = 1, int pageSize = 50}) async {
    return await _get(
        '/api/v1/response/audit-log?page=$page&page_size=$pageSize');
  }

  // ── Reporting & Intelligence (Phase 9) ────────────────────────────────────

  static Future<Map<String, dynamic>> getReportingDashboard(
      String timeRange) async {
    return await _get('/api/v1/reporting/dashboard?time_range=$timeRange');
  }

  static Future<Map<String, dynamic>> createReportSnapshot(
      String timeRange) async {
    return await _post('/api/v1/reporting/snapshots?time_range=$timeRange');
  }

  static Future<Map<String, dynamic>> getReportSnapshots() async {
    return await _get('/api/v1/reporting/snapshots');
  }

  /// Returns the full absolute URL to download a specific report file.
  /// Type can be 'pdf', 'csv_alerts', 'csv_actions', 'json'
  static String getReportingDownloadUrl(String type, String timeRange) {
    if (type == 'pdf') {
      return '$_baseUrl/api/v1/reporting/export/pdf?time_range=$timeRange';
    } else if (type == 'json') {
      return '$_baseUrl/api/v1/reporting/export/json?time_range=$timeRange';
    } else if (type == 'csv_alerts') {
      return '$_baseUrl/api/v1/reporting/export/csv?type=alerts&time_range=$timeRange';
    } else if (type == 'csv_actions') {
      return '$_baseUrl/api/v1/reporting/export/csv?type=actions&time_range=$timeRange';
    }
    return '$_baseUrl/api/v1/reporting/dashboard';
  }

  // ── Internal HTTP Methods ─────────────────────────────────────────────────

  static Future<Session?>? _refreshFuture;
  static void Function()? onForceLogout;

  static void _triggerLogout() {
    if (onForceLogout != null) {
      onForceLogout!();
    }
  }

  static Future<Session?> _refreshSessionSingleFlight() {
    final active = _refreshFuture;
    if (active != null) return active;

    Future<Session?> operation;
    try {
      operation = Supabase.instance.client.auth.refreshSession().then((res) => res.session).catchError((_) => null);
    } catch (_) {
      operation = Future.value(null);
    }
    
    _refreshFuture = operation;

    return operation.whenComplete(() {
      if (identical(_refreshFuture, operation)) {
        _refreshFuture = null;
      }
    });
  }

  static Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    String? token;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      token = session?.accessToken;
    } catch (_) {
      // Supabase not initialized, ignore
    }
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<http.Response> _sendAuthenticated(
    Future<http.Response> Function(Map<String, String> headers) request, {
    required bool allowRefreshRetry,
  }) async {
    final headers = await _getHeaders();
    headers['X-Request-ID'] = _uuid.v4();

    final response = await request(headers);

    if (response.statusCode == 401 && allowRefreshRetry) {
      final refreshedSession = await _refreshSessionSingleFlight();
      if (refreshedSession != null) {
        // Retry once with new token
        headers['Authorization'] = 'Bearer ${refreshedSession.accessToken}';
        final retryResponse = await request(headers);
        if (retryResponse.statusCode == 401) {
          // Double 401 triggers logout
          _triggerLogout();
        }
        return retryResponse;
      } else {
        _triggerLogout();
      }
    }
    
    // Note: 403 never triggers refresh or logout
    return response;
  }

  static Map<String, dynamic> _handleException(dynamic e) {
    if (e.toString() == 'Exception: Authentication required.') return {'error': true, 'message': 'Authentication required.', 'status_code': 401};
    if (e is TimeoutException) return {'error': true, 'message': 'Request timed out'};
    final msg = e.toString();
    if (msg.contains('Failed host lookup') || msg.contains('Connection refused') || msg.contains('SocketException') || msg.contains('ClientException')) {
      return {'error': true, 'message': 'Network connection failed'};
    }
    return {'error': true, 'message': 'Transport error: $msg'};
  }

  static Future<Map<String, dynamic>> _get(String path, {int maxRetries = 3}) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      attempt++;
      try {
        final response = await _sendAuthenticated(
          (headers) => http.get(Uri.parse('$_baseUrl$path'), headers: headers).timeout(_timeout),
          allowRefreshRetry: attempt == 1,
        );
        
        final bool isRetryableStatusCode = response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504;
        
        if (isRetryableStatusCode && attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
          continue;
        }
        
        return _handleResponse(response);
      } on TimeoutException {
        if (attempt >= maxRetries) return {'error': true, 'message': 'Request timed out after $maxRetries attempts'};
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      } catch (e) {
        if (e.toString() == 'Exception: Authentication required.') return {'error': true, 'message': 'Authentication required.', 'status_code': 401};
        final msg = e.toString();
        if (msg.contains('Failed host lookup') || msg.contains('Connection refused') || msg.contains('SocketException') || msg.contains('ClientException')) {
          if (attempt >= maxRetries) return {'error': true, 'message': 'Network connection failed'};
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        } else {
          return {'error': true, 'message': 'Transport error: $msg'};
        }
      }
    }
    return {'error': true, 'message': 'Unknown error in GET request'};
  }

  static Future<Map<String, dynamic>> _post(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _sendAuthenticated(
        (headers) => http.post(Uri.parse('$_baseUrl$path'), headers: headers, body: body != null ? jsonEncode(body) : null).timeout(_timeout),
        allowRefreshRetry: true,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  static Future<Map<String, dynamic>> _delete(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _sendAuthenticated(
        (headers) => http.delete(Uri.parse('$_baseUrl$path'), headers: headers, body: body != null ? jsonEncode(body) : null).timeout(_timeout),
        allowRefreshRetry: true,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  static Future<Map<String, dynamic>> _patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _sendAuthenticated(
        (headers) => http.patch(Uri.parse('$_baseUrl$path'), headers: headers, body: body != null ? jsonEncode(body) : null).timeout(_timeout),
        allowRefreshRetry: true,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  static Future<Map<String, dynamic>> _put(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _sendAuthenticated(
        (headers) => http.put(Uri.parse('$_baseUrl$path'), headers: headers, body: body != null ? jsonEncode(body) : null).timeout(_timeout),
        allowRefreshRetry: true,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('text/html')) {
      return {
        'error': true,
        'status_code': response.statusCode,
        'message': 'Received HTML response (expected JSON). Endpoint may not exist or gateway error.',
      };
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {'success': true};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['success'] == false || 
              decoded['status'] == 'failed' || 
              decoded['status'] == 'error') {
            return {
              'error': true,
              'message': decoded['message'] ?? decoded['detail'] ?? 'Operation failed',
              'data': decoded
            };
          }
          return decoded;
        }
        return {'success': true, 'data': decoded};
      } catch (e) {
        return {'error': true, 'message': 'Invalid server response. Please retry or contact the administrator.'};
      }
    } else {
      String errorMessage = 'Server error (${response.statusCode})';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('detail')) {
          final detail = errorData['detail'];
          if (detail is List && detail.isNotEmpty && detail[0] is Map) {
            if (response.statusCode == 422) {
              errorMessage = 'Unable to process request. Please check the data provided.';
            } else {
              errorMessage = 'Validation error occurred. Please try again.';
            }
          } else if (detail is String) {
            errorMessage = detail;
          } else if (detail is Map) {
            final mapDetail = Map<String, dynamic>.from(detail);
            mapDetail['error'] = true;
            mapDetail['status_code'] = response.statusCode;
            return mapDetail;
          }
        } else if (errorData is Map && errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        }
      } catch (_) {
        switch (response.statusCode) {
          case 400: errorMessage = 'Bad Request'; break;
          case 401: errorMessage = 'Unauthorized'; break;
          case 403: errorMessage = 'Forbidden'; break;
          case 404: errorMessage = 'Resource Not Found'; break;
          case 409: errorMessage = 'Conflict - Resource already in this state'; break;
          case 422: errorMessage = 'Unprocessable Entity - Invalid data format'; break;
          case 429: errorMessage = 'Too Many Requests'; break;
          case 500: errorMessage = 'Internal Server Error'; break;
          case 503: errorMessage = 'Service Unavailable'; break;
        }
      }

      return {
        'error': true,
        'status_code': response.statusCode,
        'message': errorMessage,
      };
    }
  }
}
