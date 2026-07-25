import 'package:flutter_test/flutter_test.dart';
import 'package:cybersentinel/models/firewall_log.dart';
import 'package:cybersentinel/models/firewall_action_model.dart';

void main() {
  group('FirewallLogModel Tests', () {
    test('Parses valid OS log JSON correctly', () {
      final json = {
        'id': 'log-123',
        'source_ip': '192.168.1.5',
        'destination_port': 443,
        'action': 'allowed',
        'rule_name': 'allow-https',
        'logged_at': '2026-07-19T00:00:00Z'
      };

      final model = FirewallLog.fromJson(json);

      expect(model.id, 'log-123');
      expect(model.sourceIp, '192.168.1.5');
      expect(model.destinationPort, 443);
      expect(model.action, FirewallAction.allowed);
      expect(model.ruleName, 'allow-https');
      expect(model.loggedAt.toIso8601String(), '2026-07-19T00:00:00.000Z');
    });

    test('Throws Error/Exception when given SOC Action JSON', () {
      final json = {
        'id': 'action-123',
        'ip': '10.0.0.5',
        'action': 'block',
        'reason': 'Malicious traffic',
        'source': 'analyst',
        'recorded': true,
        'enforced': false,
        'created_at': '2026-07-19T00:00:00Z'
      };

      // Since source_ip and logged_at are required, this should throw an exception.
      expect(() => FirewallLog.fromJson(json), throwsA(isA<FormatException>()));
    });
  });

  group('FirewallActionModel Tests', () {
    test('Parses valid SOC action JSON correctly', () {
      final json = {
        'id': 'action-456',
        'ip': '10.1.1.2',
        'action': 'block',
        'reason': 'Manual block by SOC',
        'source': 'soc_analyst',
        'recorded': true,
        'enforced': true,
        'created_at': '2026-07-19T00:00:00Z'
      };

      final model = FirewallActionModel.fromJson(json);

      expect(model.id, 'action-456');
      expect(model.ip, '10.1.1.2');
      expect(model.action, 'block');
      expect(model.reason, 'Manual block by SOC');
      expect(model.source, 'soc_analyst');
      expect(model.recorded, true);
      expect(model.enforced, true);
      expect(model.createdAt.toIso8601String(), '2026-07-19T00:00:00.000Z');
    });

    test('Throws Error/Exception when given OS Log JSON', () {
      final json = {
        'id': 'log-456',
        'source_ip': '192.168.1.10',
        'destination_port': 80,
        'action': 'blocked',
        'rule_name': 'block-http',
        'logged_at': '2026-07-19T00:00:00Z'
      };

      // Since ip and created_at are required but missing, this should throw
      expect(() => FirewallActionModel.fromJson(json), throwsA(isA<FormatException>()));
    });
  });
}
