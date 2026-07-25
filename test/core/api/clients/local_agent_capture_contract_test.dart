import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('start capture body matches backend schema', () {
    expect(LocalAgentClient.buildStartCaptureBody('en0'), {'interface': 'en0'});
  });

  test('packet history page size is capped at backend maximum', () {
    expect(LocalAgentClient.normalizePageSize(500), 200);
    expect(LocalAgentClient.normalizePageSize(50), 50);
  });
}
