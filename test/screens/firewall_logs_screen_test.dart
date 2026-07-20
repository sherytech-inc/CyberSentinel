import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cybersentinel/screens/firewall_logs_screen.dart';
import 'package:cybersentinel/providers/firewall_logs_provider.dart';
import 'package:cybersentinel/providers/firewall_actions_provider.dart';

void main() {
  late FirewallLogsProvider logsProvider;
  late FirewallActionsProvider actionsProvider;

  setUp(() {
    logsProvider = FirewallLogsProvider();
    actionsProvider = FirewallActionsProvider();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<FirewallLogsProvider>.value(value: logsProvider),
          ChangeNotifierProvider<FirewallActionsProvider>.value(value: actionsProvider),
        ],
        child: const Scaffold(
          body: FirewallLogsScreen(),
        ),
      ),
    );
  }

  testWidgets('renders upload button', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    expect(find.text('Import Logs'), findsOneWidget);
  });
}
