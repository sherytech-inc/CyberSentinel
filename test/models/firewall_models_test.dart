import 'package:cybersentinel/models/firewall_action_model.dart';
import 'package:cybersentinel/models/firewall_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirewallLog analysis models', () {
    test('parses normalized nullable event without inventing values', () {
      final model = FirewallLog.fromJson({
        'event_id': 'event-123',
        'timestamp': null,
        'action': 'unknown',
        'direction': 'unknown',
        'interface': null,
        'protocol': null,
        'source_ip': null,
        'destination_ip': '1.1.1.1',
        'source_port': null,
        'destination_port': 443,
        'packet_size': null,
        'flags': null,
        'rule': null,
        'raw_line_number': 8,
        'parse_status': 'partial',
        'messages': ['Some fields were unavailable.'],
      });

      expect(model.id, 'event-123');
      expect(model.timestamp, isNull);
      expect(model.sourceIp, isNull);
      expect(model.action, 'unknown');
      expect(model.parseStatus, 'partial');
    });

    test('rejects event without stable identity', () {
      expect(
        () => FirewallLog.fromJson({'action': 'allow'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('FirewallActionModel Tests', () {
    test('Parses valid SOC action JSON correctly', () {
      final model = FirewallActionModel.fromJson({
        'id': 'action-456',
        'ip': '10.1.1.2',
        'action': 'block',
        'reason': 'Manual block by SOC',
        'source': 'soc_analyst',
        'recorded': true,
        'enforced': true,
        'created_at': '2026-07-19T00:00:00Z'
      });
      expect(model.ip, '10.1.1.2');
      expect(model.enforced, true);
    });
  });
}
