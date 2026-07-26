import 'package:cybersentinel/providers/threat_response_provider.dart';
import 'package:cybersentinel/screens/threat_response_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeThreatResponseProvider extends ThreatResponseProvider {
  FakeThreatResponseProvider({
    this.active = const [],
    this.history = const [],
  }) : super(listenToWebSocket: false);

  final List<Map<String, dynamic>> active;
  final List<Map<String, dynamic>> history;

  @override
  Future<void> ensureLoaded() async {}

  @override
  bool get isLoading => false;

  @override
  bool get hasLoaded => true;

  @override
  List<Map<String, dynamic>> get threatQueue => active;

  @override
  List<Map<String, dynamic>> get alertHistory => history;

  @override
  List<Map<String, dynamic>> get filteredAlertHistory => history;
}

Widget app(ThreatResponseProvider provider) {
  return ChangeNotifierProvider<ThreatResponseProvider>.value(
    value: provider,
    child: const MaterialApp(
      home: Scaffold(body: ThreatResponseScreen()),
    ),
  );
}

void main() {
  testWidgets('empty alert state is neutral and truthful', (tester) async {
    final provider = FakeThreatResponseProvider();
    await tester.pumpWidget(app(provider));
    await tester.pump();

    expect(find.text('No open alert records'), findsOneWidget);
    expect(
      find.text('No alerts is not proof that the network is safe.'),
      findsOneWidget,
    );
    expect(find.text('No active threats detected'), findsNothing);
  });

  testWidgets('narrow threat response layout has no overflow', (tester) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = FakeThreatResponseProvider(
      active: [
        {
          'alert_id': 'alert-1',
          'source_ip': '198.51.100.8',
          'severity': 'HIGH',
          'status': 'OPEN',
          'threat_score': 82.0,
          'summary': 'Suspicious high-confidence flow',
          'explanation': ['Model evidence requires review'],
          'created_at': '2026-07-26T00:00:00Z',
        },
      ],
      history: [
        {
          'alert_id': 'alert-2',
          'source_ip': '203.0.113.9',
          'severity': 'CRITICAL',
          'status': 'RESOLVED',
          'threat_score': 94.0,
          'summary': 'Resolved alert retained as evidence',
          'updated_at': '2026-07-26T00:01:00Z',
        },
      ],
    );
    await tester.pumpWidget(app(provider));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Resolved'), findsOneWidget);
    expect(find.byKey(const ValueKey('active-alert-alert-1')), findsOneWidget);
  });
}
