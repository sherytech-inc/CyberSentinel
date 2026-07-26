import 'dart:convert';
import 'dart:io';

import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses canonical authenticated multipart firewall analysis request',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    LocalAgentClient.setBaseUrl(
        'http://${server.address.address}:${server.port}');

    late String requestPath;
    late String requestMethod;
    late String contentType;
    late List<int> body;
    final received = server.first.then((request) async {
      requestPath = request.uri.path;
      requestMethod = request.method;
      contentType = request.headers.contentType?.mimeType ?? '';
      body = await request
          .fold<List<int>>(<int>[], (all, chunk) => all..addAll(chunk));
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'status': 'complete',
        'filename': 'sample.log',
        'events_truncated': false,
        'summary': {
          'detected_format': 'ufw',
          'total_lines': 0,
          'parsed_events': 0,
          'complete_events': 0,
          'partial_events': 0,
          'failed_lines': 0,
          'allowed_count': 0,
          'denied_dropped_count': 0,
          'inbound_count': 0,
          'outbound_count': 0,
          'protocol_distribution': [],
          'top_source_ips': [],
          'top_destination_ips': [],
          'top_destination_ports': [],
          'first_timestamp': null,
          'last_timestamp': null,
          'malformed_line_count': 0,
          'warnings': [],
        },
        'events': [],
        'limits': {},
      }));
      await request.response.close();
    });

    final response =
        await LocalAgentClient.analyzeFirewallLogs('../sample.log', [1, 2, 3]);
    await received;

    expect(response['status'], 'complete');
    expect(requestMethod, 'POST');
    expect(requestPath, '/api/v1/firewall-logs/analyze');
    expect(contentType, 'multipart/form-data');
    final multipartText = latin1.decode(body);
    expect(multipartText, contains('name="file"'));
    expect(multipartText, contains('filename="sample.log"'));
    expect(multipartText, isNot(contains('../sample.log')));
  });
}
