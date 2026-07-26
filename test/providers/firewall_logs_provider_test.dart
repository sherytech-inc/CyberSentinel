import 'dart:async';

import 'package:cybersentinel/providers/firewall_logs_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> analysisResponse({String status = 'complete'}) => {
      'status': status,
      'filename': 'sample.log',
      'events_truncated': false,
      'summary': {
        'detected_format': 'ufw',
        'total_lines': 2,
        'parsed_events': 2,
        'complete_events': status == 'complete' ? 2 : 1,
        'partial_events': status == 'complete' ? 0 : 1,
        'failed_lines': 0,
        'allowed_count': 1,
        'denied_dropped_count': 1,
        'inbound_count': 2,
        'outbound_count': 0,
        'protocol_distribution': [
          {'value': 'tcp', 'count': 1},
          {'value': 'udp', 'count': 1}
        ],
        'top_source_ips': [
          {'value': '10.0.0.2', 'count': 1}
        ],
        'top_destination_ips': [
          {'value': '1.1.1.1', 'count': 1}
        ],
        'top_destination_ports': [
          {'port': 443, 'count': 1}
        ],
        'first_timestamp': '2026-07-27T12:00:00Z',
        'last_timestamp': '2026-07-27T12:00:01Z',
        'warnings': status == 'partial' ? ['Line 2 could not be parsed.'] : [],
      },
      'events': [
        {
          'event_id': 'one',
          'timestamp': '2026-07-27T12:00:00Z',
          'action': 'allow',
          'direction': 'inbound',
          'interface': 'en0',
          'protocol': 'tcp',
          'source_ip': '10.0.0.2',
          'destination_ip': '1.1.1.1',
          'source_port': 50000,
          'destination_port': 443,
          'packet_size': 60,
          'flags': 'SYN',
          'rule': null,
          'raw_line_number': 1,
          'parse_status': 'complete',
          'messages': [],
        },
        {
          'event_id': 'two',
          'timestamp': null,
          'action': 'drop',
          'direction': 'inbound',
          'interface': 'en0',
          'protocol': 'udp',
          'source_ip': '10.0.0.3',
          'destination_ip': '8.8.8.8',
          'source_port': 50001,
          'destination_port': 53,
          'packet_size': null,
          'flags': null,
          'rule': null,
          'raw_line_number': 2,
          'parse_status': status == 'partial' ? 'partial' : 'complete',
          'messages': [],
        }
      ],
    };

void main() {
  test('file selection and duplicate-submit prevention', () async {
    final gate = Completer<Map<String, dynamic>>();
    var calls = 0;
    final provider = FirewallLogsProvider(analyzeRequest: (_, __) {
      calls++;
      return gate.future;
    });
    provider.selectFile('../sample.log', [1, 2, 3]);
    expect(provider.filename, 'sample.log');
    final first = provider.analyze();
    await Future<void>.delayed(Duration.zero);
    final second = provider.analyze();
    expect(calls, 1);
    gate.complete(analysisResponse());
    await Future.wait([first, second]);
    expect(provider.state, FirewallAnalysisState.complete);
  });

  test('partial parsing and filters preserve stable selected event', () async {
    final provider = FirewallLogsProvider(
        analyzeRequest: (_, __) async => analysisResponse(status: 'partial'));
    provider.selectFile('sample.log', [1]);
    await provider.analyze();
    expect(provider.state, FirewallAnalysisState.partial);
    final selected = provider.logs.first;
    provider.selectEvent(selected);
    provider.setFilters(action: 'allow', protocol: 'tcp');
    expect(provider.filteredLogs, hasLength(1));
    expect(provider.selectedEvent?.id, selected.id);
  });

  test('unsupported, timeout and unauthorized failures are safe', () async {
    final responses = [
      {
        'error': true,
        'status': 'unsupported_format',
        'status_code': 422,
        'message': 'raw backend detail'
      },
      {'error': true, 'message': 'Request timed out'},
      {'error': true, 'status_code': 401, 'message': 'jwt raw detail'},
    ];
    final provider = FirewallLogsProvider(
        analyzeRequest: (_, __) async => responses.removeAt(0));
    provider.selectFile('sample.log', [1]);
    await provider.analyze();
    expect(provider.state, FirewallAnalysisState.unsupportedFormat);
    expect(
        provider.message, 'Unsupported or unrecognized firewall log format.');
    await provider.analyze();
    expect(provider.state, FirewallAnalysisState.timedOut);
    await provider.analyze();
    expect(provider.state, FirewallAnalysisState.unauthorized);
    expect(provider.message, isNot(contains('jwt')));
  });

  test('cancellation prevents stale result replacement', () async {
    final gate = Completer<Map<String, dynamic>>();
    final provider =
        FirewallLogsProvider(analyzeRequest: (_, __) => gate.future);
    provider.selectFile('first.log', [1]);
    final pending = provider.analyze();
    await Future<void>.delayed(Duration.zero);
    provider.cancel();
    provider.selectFile('second.log', [2]);
    gate.complete(analysisResponse());
    await pending;
    expect(provider.filename, 'second.log');
    expect(provider.result, isNull);
    expect(provider.state, FirewallAnalysisState.fileSelected);
  });
}
