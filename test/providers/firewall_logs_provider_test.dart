import 'package:flutter_test/flutter_test.dart';
import 'package:cybersentinel/providers/firewall_logs_provider.dart';
import 'package:cybersentinel/models/firewall_log.dart';

void main() {
  group('FirewallLogsProvider', () {
    late FirewallLogsProvider provider;

    setUp(() {
      provider = FirewallLogsProvider();
    });

    test('initial state', () {
      expect(provider.autoFetch, true);
      expect(provider.logs, isEmpty);
      expect(provider.blockedCount, 0);
      expect(provider.allowedCount, 0);
    });

    test('toggleAutoFetch', () {
      expect(provider.autoFetch, true);
      provider.toggleAutoFetch();
      expect(provider.autoFetch, false);
      provider.toggleAutoFetch();
      expect(provider.autoFetch, true);
    });
  });
}
