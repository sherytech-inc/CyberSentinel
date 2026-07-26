import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('report export types map to canonical reporting routes', () {
    expect(
      LocalAgentClient.reportExportPath('pdf'),
      '/api/v1/reporting/export/pdf',
    );
    expect(
      LocalAgentClient.reportExportPath('json'),
      '/api/v1/reporting/export/json',
    );
    expect(
      LocalAgentClient.reportExportPath('alerts_csv'),
      '/api/v1/reporting/export/alerts.csv',
    );
    expect(
      LocalAgentClient.reportExportPath('actions_csv'),
      '/api/v1/reporting/export/actions.csv',
    );
  });
}
