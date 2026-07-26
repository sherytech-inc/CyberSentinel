import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_environment.dart';
import '../../sidecar/sidecar_manager_interface.dart';

class AuthenticatedDownload {
  final Uint8List bytes;
  final String contentType;
  final String filename;

  const AuthenticatedDownload({
    required this.bytes,
    required this.contentType,
    required this.filename,
  });
}

class ReportDownloadException implements Exception {
  final String code;
  const ReportDownloadException(this.code);
}

/// Centralized HTTP client for the Local Native Sidecar (FastAPI).
/// Handles traffic to localhost for packet capture, ML inference, and firewall actions.
class LocalAgentClient {
  static String _baseUrl = AppEnvironment.apiBaseUrl;
  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _scannerTimeout = Duration(seconds: 30);
  static const _uuid = Uuid();

  static void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get baseUrl => _baseUrl;

  // ── Dashboard ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboardStats() async {
    return await _get('/api/v1/dashboard/stats');
  }

  // ── AI Analyst ────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendCopilotMessage(
      String sessionId, String message) async {
    return await _post('/api/v1/copilot/chat',
        body: {
          'session_id': sessionId,
          'message': message,
        },
        timeout: const Duration(seconds: 25));
  }

  // ── Capture Capabilities ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getCapabilities() async {
    return await _get('/api/v1/capture/capabilities');
  }

  static Future<Map<String, dynamic>> refreshCapabilities() async {
    return await _post('/api/v1/capture/capabilities/refresh');
  }

  static Future<Map<String, dynamic>> runCaptureProbe(
      String interfaceId) async {
    return await _post('/api/v1/capture/probe',
        body: {'interface_id': interfaceId});
  }

  static Future<Map<String, dynamic>> executeRemediation() async {
    return await _post('/api/v1/capture/remediation/status');
  }

  // ── Capture ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getPackets(
      {int page = 1, int pageSize = 50}) async {
    final safePageSize = normalizePageSize(pageSize);
    return await _get('/api/v1/packets?page=$page&page_size=$safePageSize');
  }

  static int normalizePageSize(int pageSize) => pageSize.clamp(1, 200);

  // ── Firewall Logs ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchFirewallLogs(
      {int page = 1, int pageSize = 50}) async {
    return await _get(
        '/api/v1/operations/firewall?page=$page&page_size=$pageSize');
  }

  static Future<Map<String, dynamic>> fetchFirewallActions(
      {int page = 1, int pageSize = 50}) async {
    return await _get(
        '/api/v1/firewall-action/actions?page=$page&page_size=$pageSize');
  }

  static Future<Map<String, dynamic>> uploadFirewallLogs(
      String fileName, List<int> bytes) async {
    try {
      final response = await _sendAuthenticated((headers) async {
        final request = http.MultipartRequest(
            'POST', Uri.parse('$_baseUrl/api/v1/operations/firewall/upload'));
        request.headers.addAll(headers);
        request.files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName));
        final streamedResponse = await request.send().timeout(_scannerTimeout);
        return http.Response.fromStream(streamedResponse);
      }, allowRefreshRetry: true);
      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  static Future<Map<String, dynamic>> analyzeFirewallLogs(
      String fileName, List<int> bytes) async {
    try {
      final response = await _sendAuthenticated((headers) async {
        final request = http.MultipartRequest(
            'POST', Uri.parse('$_baseUrl/api/v1/firewall-logs/analyze'));
        request.headers.addAll(headers);
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName.split(RegExp(r'[/\\]')).last,
        ));
        final streamedResponse = await request.send().timeout(_scannerTimeout);
        return http.Response.fromStream(streamedResponse);
      }, allowRefreshRetry: true);
      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  // ── Threats ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> scanVirusFile(
      String fileName, List<int> bytes) async {
    try {
      final response = await _sendAuthenticated((headers) async {
        final request = http.MultipartRequest(
            'POST', Uri.parse('$_baseUrl/api/v1/scanner/file'));
        request.headers.addAll(headers);
        request.files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName));
        final streamedResponse = await request.send().timeout(_timeout);
        return http.Response.fromStream(streamedResponse);
      }, allowRefreshRetry: true);
      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  static Future<Map<String, dynamic>> scanVirusUrl(String url) async =>
      _post('/api/v1/scanner/url',
          body: {'url': url}, timeout: _scannerTimeout);

  static Future<Map<String, dynamic>> scanVirusHash(String hash) async =>
      _post('/api/v1/scanner/hash',
          body: {'hash': hash}, timeout: _scannerTimeout);

  static Future<Map<String, dynamic>> lookupThreatIntelligence(
          String ip) async =>
      _post('/api/v1/intelligence/lookup', body: {'ip': ip});

  static Future<Map<String, dynamic>> getThreats(
      {int page = 1, int pageSize = 50}) async {
    return await _get('/api/v1/threats?page=$page&page_size=$pageSize');
  }

  static Future<Map<String, dynamic>> getThreatStats() async {
    return await _get('/api/v1/threats/stats');
  }

  static Future<Map<String, dynamic>> getHighThreats(
      {int page = 1, int pageSize = 50}) async {
    return await _get('/api/v1/threats/high?page=$page&page_size=$pageSize');
  }

  static Future<Map<String, dynamic>> getCriticalThreats(
      {int page = 1, int pageSize = 50}) async {
    return await _get(
        '/api/v1/threats/critical?page=$page&page_size=$pageSize');
  }

  static Future<Map<String, dynamic>> getThreatHistory(
      {int page = 1, int pageSize = 100}) async {
    return await _get('/api/v1/threats/history?page=$page&page_size=$pageSize');
  }

  // ── Firewall Actions ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> blockIP(String ip,
      {String? reason}) async {
    return await _post('/api/v1/firewall/block',
        body: {'ip': ip, 'reason': reason});
  }

  static Future<Map<String, dynamic>> unblockIP(String ip) async {
    return await _post('/api/v1/firewall/unblock', body: {'ip': ip});
  }

  static Future<Map<String, dynamic>> whitelistIP(String ip) async {
    return await _post('/api/v1/firewall/whitelist', body: {'ip': ip});
  }

  // ── Capture Control ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getCaptureStatus() async {
    return await _get('/api/v1/capture/status');
  }

  static Future<Map<String, dynamic>> startCapture(
      {String interfaceName = 'en0', String? bpfFilter}) async {
    final body = buildStartCaptureBody(interfaceName, bpfFilter: bpfFilter);
    return await _post('/api/v1/capture/start', body: body);
  }

  static Map<String, dynamic> buildStartCaptureBody(
    String interfaceName, {
    String? bpfFilter,
  }) {
    final body = <String, dynamic>{'interface': interfaceName};
    if (bpfFilter != null) body['bpf_filter'] = bpfFilter;
    return body;
  }

  static Future<Map<String, dynamic>> stopCapture() async {
    return await _post('/api/v1/capture/stop');
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

  static Future<Map<String, dynamic>> getResponseThreatHistory({
    int page = 1,
    int pageSize = 100,
    String? status,
  }) async {
    final queryStatus =
        status == null || status == 'ALL' ? '' : '&status=$status';
    return await _get(
      '/api/v1/threats/history?page=$page&page_size=$pageSize$queryStatus',
    );
  }

  static Future<Map<String, dynamic>> investigateThreat(String alertId) async {
    return await _post('/api/v1/response/threats/$alertId/investigate');
  }

  static Future<Map<String, dynamic>> getThreatExplanation(
      String alertId) async {
    return await _get('/api/v1/response/threats/$alertId/explanation');
  }

  static Future<List<dynamic>> getThreatNotes(String alertId) async {
    try {
      final res = await _get('/api/v1/response/threats/$alertId/notes');
      return res['items'] ?? res['notes'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> addThreatNote(String alertId, String note,
      {String author = 'Analyst'}) async {
    return await _post('/api/v1/response/threats/$alertId/notes',
        body: {'note': note, 'author': author});
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

  static Future<Map<String, dynamic>> responseBlockIP(
    String ip, {
    String? reason,
    String? alertId,
  }) async {
    return await _post('/api/v1/response/block', body: {
      'ip': ip,
      'reason': reason,
      'alert_id': alertId,
    });
  }

  static Future<Map<String, dynamic>> responseUnblockIP(
    String ip, {
    String? reason,
    String? alertId,
  }) async {
    return await _post('/api/v1/response/unblock', body: {
      'ip': ip,
      'reason': reason,
      'alert_id': alertId,
    });
  }

  static Future<Map<String, dynamic>> responseWhitelistIP(
    String ip, {
    String? reason,
    String? alertId,
  }) async {
    return await _post('/api/v1/response/whitelist', body: {
      'ip': ip,
      'reason': reason,
      'alert_id': alertId,
    });
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

  // ── Reports & Intelligence ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getReportSummary() async {
    return await _get('/api/v1/reporting/summary');
  }

  static String reportExportPath(String type) {
    switch (type) {
      case 'pdf':
        return '/api/v1/reporting/export/pdf';
      case 'json':
        return '/api/v1/reporting/export/json';
      case 'alerts_csv':
        return '/api/v1/reporting/export/alerts.csv';
      case 'actions_csv':
        return '/api/v1/reporting/export/actions.csv';
      default:
        throw const ReportDownloadException('unsupported_export');
    }
  }

  static Future<AuthenticatedDownload> downloadReport(String type) async {
    final path = reportExportPath(type);
    try {
      final response = await _sendAuthenticated(
        (headers) => http
            .get(Uri.parse('$_baseUrl$path'), headers: headers)
            .timeout(_timeout),
        allowRefreshRetry: true,
      );
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const ReportDownloadException('not_authorized');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ReportDownloadException('report_unavailable');
      }
      if (response.bodyBytes.isEmpty) {
        throw const ReportDownloadException('empty_export');
      }
      final contentType =
          response.headers['content-type'] ?? 'application/octet-stream';
      final filename = _downloadFilename(
        response.headers['content-disposition'],
        fallback: _fallbackReportFilename(type),
      );
      return AuthenticatedDownload(
        bytes: response.bodyBytes,
        contentType: contentType,
        filename: filename,
      );
    } on TimeoutException {
      throw const ReportDownloadException('timeout');
    } on ReportDownloadException {
      rethrow;
    } catch (_) {
      throw const ReportDownloadException('report_unavailable');
    }
  }

  static String _fallbackReportFilename(String type) {
    final extension =
        type == 'alerts_csv' || type == 'actions_csv' ? 'csv' : type;
    return 'cybersentinel-report.$extension';
  }

  static String _downloadFilename(
    String? contentDisposition, {
    required String fallback,
  }) {
    if (contentDisposition == null || contentDisposition.isEmpty) {
      return fallback;
    }
    final encoded = RegExp(
      r'''filename\*=UTF-8''([^;]+)''',
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    if (encoded != null) {
      return Uri.decodeComponent(encoded.group(1)!).split('/').last;
    }
    final plain = RegExp(
      r'''filename\s*=\s*"?([^";]+)"?''',
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    return plain?.group(1)?.trim().split('/').last ?? fallback;
  }

  static Future<Map<String, dynamic>> getDemoStatus() async {
    return await _get('/api/v1/demo/status');
  }

  static Future<Map<String, dynamic>> triggerDemoMode(String scenario) async {
    return await _post('/api/v1/demo/load?scenario=$scenario');
  }

  static Future<Map<String, dynamic>> resetDemoMode(String runId) async {
    return await _delete('/api/v1/demo/reset?run_id=$runId');
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
      operation = Supabase.instance.client.auth
          .refreshSession()
          .then((res) => res.session)
          .catchError((_) => null);
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

    final localToken = SidecarManager().localToken;
    if (localToken != null) {
      headers['X-CyberSentinel-Local-Token'] = localToken;
    }

    return headers;
  }

  static Future<http.Response> _sendAuthenticated(
    Future<http.Response> Function(Map<String, String> headers) request, {
    required bool allowRefreshRetry,
  }) async {
    final headers = await _getHeaders();
    headers['X-Request-ID'] = _uuid.v4();
    final hadAuthHeader = headers.containsKey('Authorization');

    final response = await request(headers);

    if (response.statusCode == 401 && allowRefreshRetry) {
      if (!hadAuthHeader) {
        return response;
      }

      final refreshedSession = await _refreshSessionSingleFlight();
      if (refreshedSession != null) {
        headers['Authorization'] = 'Bearer ${refreshedSession.accessToken}';
        final retryResponse = await request(headers);
        if (retryResponse.statusCode == 401) {
          _triggerLogout();
        }
        return retryResponse;
      } else {
        if (hadAuthHeader) {
          _triggerLogout();
        }
      }
    }
    return response;
  }

  static Map<String, dynamic> _handleException(dynamic e) {
    if (e.toString() == 'Exception: Authentication required.')
      return {
        'error': true,
        'message': 'Authentication required.',
        'status_code': 401
      };
    if (e is TimeoutException)
      return {'error': true, 'message': 'Request timed out'};
    final msg = e.toString();
    if (msg.contains('Failed host lookup') ||
        msg.contains('Connection refused') ||
        msg.contains('SocketException') ||
        msg.contains('ClientException')) {
      return {'error': true, 'message': 'Network connection failed'};
    }
    return {'error': true, 'message': 'Transport error: $msg'};
  }

  static Future<Map<String, dynamic>> _get(String path,
      {int maxRetries = 3}) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      attempt++;
      try {
        final response = await _sendAuthenticated(
          (headers) => http
              .get(Uri.parse('$_baseUrl$path'), headers: headers)
              .timeout(_timeout),
          allowRefreshRetry: attempt == 1,
        );

        final bool isRetryableStatusCode = response.statusCode == 502 ||
            response.statusCode == 503 ||
            response.statusCode == 504;

        if (isRetryableStatusCode && attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
          continue;
        }

        return _handleResponse(response);
      } on TimeoutException {
        if (attempt >= maxRetries)
          return {
            'error': true,
            'message': 'Request timed out after $maxRetries attempts'
          };
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      } catch (e) {
        if (e.toString() == 'Exception: Authentication required.')
          return {
            'error': true,
            'message': 'Authentication required.',
            'status_code': 401
          };
        final msg = e.toString();
        if (msg.contains('Failed host lookup') ||
            msg.contains('Connection refused') ||
            msg.contains('SocketException') ||
            msg.contains('ClientException')) {
          if (attempt >= maxRetries)
            return {'error': true, 'message': 'Network connection failed'};
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        } else {
          return {'error': true, 'message': 'Transport error: $msg'};
        }
      }
    }
    return {'error': true, 'message': 'Unknown error in GET request'};
  }

  static Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    try {
      final response = await _sendAuthenticated(
        (headers) => http
            .post(Uri.parse('$_baseUrl$path'),
                headers: headers, body: body != null ? jsonEncode(body) : null)
            .timeout(timeout ?? _timeout),
        allowRefreshRetry: true,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  static Future<Map<String, dynamic>> _delete(String path,
      {Map<String, dynamic>? body}) async {
    try {
      final response = await _sendAuthenticated(
        (headers) => http
            .delete(Uri.parse('$_baseUrl$path'),
                headers: headers, body: body != null ? jsonEncode(body) : null)
            .timeout(_timeout),
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
        'message':
            'Received HTML response (expected JSON). Endpoint may not exist or gateway error.',
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
              'message':
                  decoded['message'] ?? decoded['detail'] ?? 'Operation failed',
              'data': decoded
            };
          }
          return decoded;
        }
        return {'success': true, 'data': decoded};
      } catch (e) {
        return {
          'error': true,
          'message':
              'Invalid server response. Please retry or contact the administrator.'
        };
      }
    } else {
      String errorMessage = 'Server error (${response.statusCode})';
      Map<String, dynamic>? structuredError;
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map) {
          structuredError = Map<String, dynamic>.from(errorData);
          final detail = errorData['detail'];
          if (errorData['message'] is String) {
            errorMessage = errorData['message'];
          } else if (detail is String) {
            errorMessage = detail;
          } else if (detail is Map) {
            final safeMessage = detail['message'];
            if (safeMessage is String) {
              errorMessage = safeMessage;
            }
          } else if (detail is List && detail.isNotEmpty) {
            final first = detail.first;
            if (first is Map) {
              final message = first['msg']?.toString();
              final location = first['loc'];
              final field = location is List ? location.join('.') : null;
              if (message != null) {
                errorMessage = field == null ? message : '$message ($field)';
              }
            }
          }
        }
      } catch (_) {}
      return {
        'error': true,
        'status_code': response.statusCode,
        'message': errorMessage,
        if (structuredError?['detail'] is Map &&
            (structuredError!['detail'] as Map)['status'] is String)
          'status': (structuredError['detail'] as Map)['status'],
        if (structuredError
            case {
              'ip': _,
              'status': _,
              'virustotal': _,
              'abuseipdb': _,
              'geoip': _,
            })
          'data': structuredError,
      };
    }
  }
}
