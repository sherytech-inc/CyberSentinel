import 'package:cybersentinel/models/global_metrics.dart';
import 'package:cybersentinel/models/capture_session.dart';
import 'package:cybersentinel/providers/dashboard_provider.dart';
import 'package:cybersentinel/providers/metrics_provider.dart';
import 'package:cybersentinel/widgets/dashboard/alerts_panel.dart';
import 'package:cybersentinel/widgets/dashboard/threat_score_card.dart';
import 'package:cybersentinel/widgets/dashboard/traffic_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class _InactiveDashboardProvider extends ChangeNotifier
    implements DashboardProvider {
  @override
  bool get isWsConnected => false;

  @override
  bool get isMonitoringActive => false;

  @override
  bool get isCurrentSessionVisible => false;

  @override
  bool get isStopping => false;

  @override
  int get threatScore => 0;

  @override
  int? get currentSessionThreatScore => null;

  @override
  int? get lastSessionThreatScore => null;

  @override
  bool get hasReliableThreatScore => false;

  @override
  CaptureSessionSummary? get lastSession => null;

  @override
  List<TrafficData> get trafficData => const [];

  @override
  List<Alert> get alerts => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyMetricsProvider extends ChangeNotifier implements MetricsProvider {
  @override
  GlobalSecurityMetrics get metrics => GlobalSecurityMetrics.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ActivePendingDashboardProvider extends _InactiveDashboardProvider {
  @override
  bool get isMonitoringActive => true;

  @override
  bool get isCurrentSessionVisible => true;
}

class _StoppedScoredDashboardProvider extends _InactiveDashboardProvider {
  @override
  int? get lastSessionThreatScore => 28;

  @override
  bool get hasReliableThreatScore => true;
}

class _RecentAlertDashboardProvider extends _InactiveDashboardProvider {
  @override
  List<Alert> get alerts => [
        Alert(
          id: 'alert-1',
          title: 'Suspicious',
          description: 'Source: 198.51.100.8',
          time: 'Just now',
          severity: AlertSeverity.high,
          status: 'RESOLVED',
        ),
      ];
}

void main() {
  late DashboardProvider dashboardProvider;
  late MetricsProvider metricsProvider;

  setUp(() {
    dashboardProvider = _InactiveDashboardProvider();
    metricsProvider = _EmptyMetricsProvider();
  });

  tearDown(() {
    dashboardProvider.dispose();
    metricsProvider.dispose();
  });

  Widget testApp(Widget child, {double width = 800}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DashboardProvider>.value(
          value: dashboardProvider,
        ),
        ChangeNotifierProvider<MetricsProvider>.value(
          value: metricsProvider,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  testWidgets('inactive dashboard uses unavailable wording', (tester) async {
    await tester.pumpWidget(testApp(const SingleChildScrollView(
      child: Column(
        children: [
          ThreatScoreCard(),
          AlertsPanel(),
        ],
      ),
    )));

    expect(find.text('N/A'), findsOneWidget);
    expect(find.text('Monitoring inactive'), findsOneWidget);
    expect(find.textContaining('No alert data available'), findsOneWidget);
    expect(
        find.textContaining('Waiting for live packet capture'), findsOneWidget);
    expect(find.text('Safe'), findsNothing);
    expect(find.text('No Threats Detected'), findsNothing);
    expect(find.textContaining('currently secure'), findsNothing);
    expect(find.byIcon(LucideIcons.shieldOff), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsNothing);
    expect(find.text('🛡'), findsNothing);
  });

  testWidgets('traffic chart does not overflow at 462 pixels', (tester) async {
    await tester.binding.setSurfaceSize(const Size(462, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(testApp(const TrafficChart(), width: 462));

    expect(find.text('No completed session data available'), findsOneWidget);
    expect(find.textContaining('Demo Mode'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recent alerts visibly reflect lifecycle status', (tester) async {
    final recent = _RecentAlertDashboardProvider();
    addTearDown(recent.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DashboardProvider>.value(
          value: recent,
          child: const Scaffold(body: AlertsPanel()),
        ),
      ),
    );

    expect(find.text('RESOLVED'), findsOneWidget);
    expect(find.text('Suspicious'), findsOneWidget);
  });

  testWidgets('active monitoring with no analysis never shows Low Risk',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DashboardProvider>.value(
          value: _ActivePendingDashboardProvider(),
          child: const Scaffold(body: ThreatScoreCard()),
        ),
      ),
    );

    expect(find.text('N/A'), findsOneWidget);
    expect(find.text('Monitoring active — analysis pending'), findsOneWidget);
    expect(find.text('Low Risk'), findsNothing);
  });

  testWidgets('reliable score is labelled as last-session data after stop',
      (tester) async {
    final stopped = _StoppedScoredDashboardProvider();
    addTearDown(stopped.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DashboardProvider>.value(
          value: stopped,
          child: const Scaffold(body: ThreatScoreCard()),
        ),
      ),
    );

    expect(find.text('28 / 100'), findsOneWidget);
    expect(find.text('Last Session Threat Score'), findsOneWidget);
    expect(find.text('Monitoring inactive'), findsOneWidget);
    expect(find.text('Low Risk — Last completed session'), findsOneWidget);
  });

  testWidgets('stopped session keeps a labelled final distribution chart',
      (tester) async {
    final provider = DashboardProvider(initializeAuth: false);
    addTearDown(provider.dispose);
    provider.applyCaptureDiagnosticsForTesting({'state': 'running'});
    provider.applyPacketBatchForTesting({
      'packets': [
        {'packet_id': 'p1', 'analysis_status': 'pending'},
        {'packet_id': 'p2', 'analysis_status': 'pending'},
      ],
    });
    provider.applyAnalysisUpdateForTesting({
      'packet_ids': ['p1'],
      'analysis_status': 'complete',
      'ml_prediction': 'normal',
      'threat_score': 18,
    });
    provider.applyCaptureDiagnosticsForTesting({'state': 'stopped'});

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DashboardProvider>.value(
          value: provider,
          child: const Scaffold(
            body: SingleChildScrollView(child: TrafficChart()),
          ),
        ),
      ),
    );

    expect(find.text('Last Session Overview'), findsOneWidget);
    expect(find.text('Not analyzed'), findsOneWidget);
    expect(find.text('No completed session data available'), findsNothing);
    expect(provider.pendingPacketsCount, 0);
    expect(provider.trafficData, hasLength(2));
  });
}
