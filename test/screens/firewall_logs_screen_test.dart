import 'package:cybersentinel/providers/firewall_actions_provider.dart';
import 'package:cybersentinel/providers/firewall_logs_provider.dart';
import 'package:cybersentinel/screens/firewall_logs_screen.dart';
import 'package:cybersentinel/models/firewall_action_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../providers/firewall_logs_provider_test.dart';

class _FakeFirewallActionsProvider extends ChangeNotifier
    implements FirewallActionsProvider {
  @override
  List<FirewallActionModel> get actions => const [];

  @override
  bool get isLoading => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildScreen(FirewallLogsProvider logs, {double width = 1200}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: logs),
            ChangeNotifierProvider<FirewallActionsProvider>.value(
                value: _FakeFirewallActionsProvider()),
          ],
          child: const Scaffold(body: FirewallLogsScreen()),
        ),
      ),
    );
  }

  testWidgets('neutral empty state is read-only', (tester) async {
    final provider = FirewallLogsProvider(
        analyzeRequest: (_, __) async => analysisResponse());
    await tester.pumpWidget(buildScreen(provider));
    expect(find.text('No firewall log selected'), findsOneWidget);
    expect(find.text('Select log file'), findsOneWidget);
    expect(find.text('Block IP'), findsNothing);
    expect(find.text('Allow IP'), findsNothing);
    expect(find.text('Whitelist IP'), findsNothing);
    expect(find.text('Export'), findsNothing);
  });

  testWidgets('successful summary, filtering and event details render',
      (tester) async {
    final provider = FirewallLogsProvider(
        analyzeRequest: (_, __) async => analysisResponse());
    provider.selectFile('sample.log', [1]);
    await provider.analyze();
    await tester.pumpWidget(buildScreen(provider));
    expect(find.text('Detected format: UFW'), findsOneWidget);
    expect(find.text('Parsed events'), findsOneWidget);
    provider.setFilters(action: 'allow');
    await tester.pump();
    expect(find.text('1 visible event'), findsOneWidget);
    provider.selectEvent(provider.filteredLogs.single);
    await tester.pump();
    expect(find.text('Event details'), findsOneWidget);
    expect(find.text('one'), findsOneWidget);
  });

  testWidgets('partial result and narrow layout have no overflow',
      (tester) async {
    final provider = FirewallLogsProvider(
        analyzeRequest: (_, __) async => analysisResponse(status: 'partial'));
    provider.selectFile('sample.log', [1]);
    await provider.analyze();
    await tester.pumpWidget(buildScreen(provider, width: 440));
    expect(
        find.textContaining('Some lines could not be parsed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
