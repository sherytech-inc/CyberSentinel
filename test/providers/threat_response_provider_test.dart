import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'package:cybersentinel/providers/threat_response_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late Map<String, Map<String, dynamic>> responses;
  var blockDelay = Duration.zero;

  setUp(() async {
    responses = {
      '/api/v1/response/overview': {
        'active_threats': 1,
        'blocked_ips': 0,
        'total_actions': 1,
      },
      '/api/v1/response/threats?page=1&page_size=50': {
        'items': [
          {
            'alert_id': 'alert-1',
            'source_ip': '198.51.100.8',
            'severity': 'HIGH',
            'status': 'OPEN',
            'threat_score': 82.0,
            'summary': 'Suspicious flow',
            'explanation': ['High-confidence suspicious classification'],
            'created_at': '2026-07-26T00:00:00Z',
            'updated_at': '2026-07-26T00:00:00Z',
          },
        ],
        'total': 1,
      },
      '/api/v1/threats/history?page=1&page_size=100': {
        'items': [
          {
            'alert_id': 'alert-1',
            'source_ip': '198.51.100.8',
            'severity': 'HIGH',
            'status': 'OPEN',
            'threat_score': 82.0,
            'summary': 'Suspicious flow',
          },
          {
            'alert_id': 'alert-2',
            'source_ip': '203.0.113.9',
            'severity': 'CRITICAL',
            'status': 'RESOLVED',
            'threat_score': 94.0,
            'summary': 'Resolved alert',
          },
        ],
        'total': 2,
      },
      '/api/v1/response/history?page=1&page_size=50': {
        'items': [
          {
            'id': 'action-1',
            'ip': '198.51.100.8',
            'action': 'BLOCK',
            'status': 'RECORDED_ONLY',
            'recorded': true,
            'enforced': false,
            'message': 'Recorded only.',
            'created_at': '2026-07-26T00:01:00Z',
          },
        ],
        'total': 1,
      },
    };
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    LocalAgentClient.setBaseUrl(
      'http://${server.address.address}:${server.port}',
    );
    unawaited(
      server.forEach((request) async {
        final key = '${request.uri.path}'
            '${request.uri.hasQuery ? '?${request.uri.query}' : ''}';
        final configured = responses[key];
        if (configured != null) {
          request.response
            ..statusCode = (configured['status_code'] as num?)?.toInt() ?? 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(configured));
        } else if (request.uri.path == '/api/v1/response/block') {
          if (blockDelay > Duration.zero) {
            await Future<void>.delayed(blockDelay);
          }
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({
                'id': 'action-2',
                'ip': '198.51.100.8',
                'action': 'BLOCK',
                'status': 'RECORDED_ONLY',
                'recorded': true,
                'enforced': false,
                'message':
                    'Block request recorded. No operating-system firewall change was made.',
                'created_at': '2026-07-26T00:02:00Z',
              }),
            );
        } else if (request.uri.path.contains('/resolve')) {
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({
                'status': 'success',
                'alert': {
                  'alert_id': 'alert-1',
                  'source_ip': '198.51.100.8',
                  'severity': 'HIGH',
                  'status': 'RESOLVED',
                  'threat_score': 82.0,
                  'summary': 'Suspicious flow',
                },
              }),
            );
        } else {
          request.response
            ..statusCode = 404
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'detail': 'not_found'}));
        }
        await request.response.close();
      }),
    );
  });

  tearDown(() async {
    await server.close(force: true);
    LocalAgentClient.setBaseUrl('http://127.0.0.1:8000');
  });

  test('loads active alerts, retained history, and truthful action state',
      () async {
    final provider = ThreatResponseProvider(listenToWebSocket: false);
    await provider.ensureLoaded();

    expect(provider.error, isNull);
    expect(provider.activeThreats, 1);
    expect(provider.alertHistory, hasLength(2));
    expect(provider.actionHistory.single.enforced, isFalse);
    expect(provider.blockedIPsCount, 0);

    provider.setAlertFilter(ThreatAlertFilter.resolved);
    expect(provider.filteredAlertHistory, hasLength(1));
    expect(provider.filteredAlertHistory.single['alert_id'], 'alert-2');
    provider.dispose();
  });

  test('duplicate block clicks are prevented and alert remains active',
      () async {
    final provider = ThreatResponseProvider(listenToWebSocket: false);
    await provider.ensureLoaded();
    blockDelay = const Duration(milliseconds: 150);

    final first = provider.blockIP(
      '198.51.100.8',
      'Review',
      'alert-1',
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final duplicate = await provider.blockIP(
      '198.51.100.8',
      'Review',
      'alert-1',
    );
    final result = await first;

    expect(duplicate['success'], isFalse);
    expect(duplicate['message'], contains('already in progress'));
    expect(result['success'], isTrue);
    expect(result['enforced'], isFalse);
    expect(provider.threatQueue.single['alert_id'], 'alert-1');
    provider.dispose();
  });

  test('resolve updates in place and retains the alert in history', () async {
    final provider = ThreatResponseProvider(listenToWebSocket: false);
    await provider.ensureLoaded();
    final result = await provider.resolveThreat('alert-1');

    expect(result['success'], isTrue);
    expect(provider.threatQueue, isEmpty);
    final retained = provider.alertHistory.firstWhere(
      (alert) => alert['alert_id'] == 'alert-1',
    );
    expect(retained['status'], 'RESOLVED');
    provider.dispose();
  });

  test('failed action retains the active alert and exposes a safe error',
      () async {
    final provider = ThreatResponseProvider(listenToWebSocket: false);
    await provider.ensureLoaded();
    responses['/api/v1/response/threats/alert-1/resolve'] = {
      'error': true,
      'status_code': 503,
    };

    final result = await provider.resolveThreat('alert-1');
    expect(result['success'], isFalse);
    expect(result['message'], 'The requested action could not be completed.');
    expect(provider.threatQueue.single['alert_id'], 'alert-1');
    expect(provider.error, isNot(contains('detail')));
    provider.dispose();
  });
}
