import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized HTTP client for the Cloud Control Plane (Supabase Edge Functions).
/// Handles traffic to the cloud for reporting, third-party integrations, LLMs.
class CloudControlPlaneClient {
  static Future<Map<String, dynamic>> _invokeFunction(String functionName,
      {Map<String, dynamic>? body}) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        functionName,
        body: body,
      );
      if (response.status >= 200 && response.status < 300) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
        return {'success': true, 'data': response.data};
      } else {
        return {
          'error': true,
          'status_code': response.status,
          'message': 'Cloud function error: ${response.status}'
        };
      }
    } on FunctionException catch (e) {
      return {
        'error': true,
        'status_code': e.status,
        'message': e.details ?? e.reasonPhrase ?? 'Function execution failed',
      };
    } catch (e) {
      return {
        'error': true,
        'message': 'Failed to execute cloud function: $e',
      };
    }
  }

  // ── Threat Intel & Analysis ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> analyzeIP(String ip) async {
    return await _invokeFunction('threat-intel',
        body: {'action': 'analyze', 'ip': ip});
  }

  static Future<Map<String, dynamic>> scanVirus(
      String target, String type) async {
    return await _invokeFunction('threat-intel',
        body: {'action': 'scan', 'target': target, 'type': type});
  }

  // ── Copilot & Chat ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getCopilotContext() async {
    return await _invokeFunction('copilot-chat',
        body: {'action': 'get_context'});
  }

  static Future<Map<String, dynamic>> sendChatMessage(
      String sessionId, String message) async {
    return await _invokeFunction('copilot-chat', body: {
      'action': 'send_message',
      'session_id': sessionId,
      'message': message,
    });
  }

  // ── Integrations ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getIntegrations() async {
    return await _invokeFunction('threat-intel',
        body: {'action': 'get_integrations'});
  }

  static Future<Map<String, dynamic>> testIntegration(String provider) async {
    return await _invokeFunction('threat-intel',
        body: {'action': 'test_integration', 'provider': provider});
  }

}
