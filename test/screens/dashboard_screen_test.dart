import 'dart:io';

import 'package:cybersentinel/providers/dashboard_provider.dart';
import 'package:cybersentinel/screens/dashboard_screen.dart';
import 'package:cybersentinel/widgets/common/common.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// `initializeAuth: false` keeps the provider off Supabase and off the local
/// agent, so no real IO is started under `tester.pump`. State is then driven
/// through the provider's own `@visibleForTesting` hooks, which means these
/// tests exercise the real getters the widgets read rather than a hand-rolled
/// stub that can drift from them.
DashboardProvider _idle() => DashboardProvider(initializeAuth: false);

DashboardProvider _stoppedSession() {
  final provider = _idle();
  provider.applyLastSessionForTesting({
    'session_id': 'session-1',
    'status': 'stopped',
    'captured_count': 1200,
    'analyzed_count': 1080,
    'pending_count': 0,
    'complete_count': 900,
    'partial_count': 180,
    'failed_count': 40,
    'deferred_count': 20,
    'not_analyzed_count': 60,
    'normal_count': 900,
    'suspicious_count': 120,
    'malicious_count': 30,
    'unknown_count': 30,
    'last_reliable_score': 82,
    'highest_severity': 'critical',
  });
  return provider;
}

DashboardProvider _liveSession() {
  final provider = _idle();
  provider.applyCaptureDiagnosticsForTesting({'state': 'running'});
  provider.applyPacketBatchForTesting({
    'packets': [
      {'packet_id': 'p1', 'analysis_status': 'pending'},
      {'packet_id': 'p2', 'analysis_status': 'pending'},
      {'packet_id': 'p3', 'analysis_status': 'pending'},
    ],
  });
  provider.applyAnalysisUpdateForTesting({
    'packet_ids': ['p1'],
    'analysis_status': 'complete',
    'ml_prediction': 'normal',
    'threat_score': 18,
  });
  return provider;
}

Widget _app(ThemeData theme, DashboardProvider provider) {
  return ChangeNotifierProvider<DashboardProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: theme,
      home: const Scaffold(body: DashboardScreen()),
    ),
  );
}

/// The migrated files. `capture_diagnostics_card.dart` is deliberately absent:
/// nothing in the app references it, so it was left on the legacy palette
/// rather than migrated speculatively.
const List<String> _migratedSources = [
  'lib/screens/dashboard_screen.dart',
  'lib/widgets/dashboard/alerts_panel.dart',
  'lib/widgets/dashboard/malicious_ips_table.dart',
  'lib/widgets/dashboard/packet_classification.dart',
  'lib/widgets/dashboard/threat_score_card.dart',
  'lib/widgets/dashboard/traffic_chart.dart',
];

void main() {
  Future<void> pump(
    WidgetTester tester,
    ThemeData theme,
    DashboardProvider provider, {
    double width = 1400,
  }) async {
    addTearDown(provider.dispose);
    await tester.binding.setSurfaceSize(Size(width, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(theme, provider));
    await tester.pump();
  }

  for (final entry in {'dark': CsTheme.dark(), 'light': CsTheme.light()}.entries) {
    group('Dashboard in the ${entry.key} theme', () {
      testWidgets('renders every panel without throwing', (tester) async {
        await pump(tester, entry.value, _idle());

        expect(tester.takeException(), isNull);
        expect(find.text('Risk Level'), findsOneWidget);
        expect(find.text('Recent Alerts'), findsOneWidget);
        expect(find.text('Analyzed Packet Distribution'), findsOneWidget);
        expect(find.text('Top Malicious IPs'), findsOneWidget);
        expect(find.text('Last Session Overview'), findsOneWidget);
      });

      testWidgets(
          'panel titles sit on the opposite end of the scale from the page',
          (tester) async {
        await pump(tester, entry.value, _idle());
        final context = tester.element(find.text('Recent Alerts'));
        final colors = CsColors.of(context);

        // The regression this guards: a widget left on the frozen dark palette
        // renders white panel titles on a white card in light mode.
        final title = tester.widget<Text>(find.text('Recent Alerts'));
        expect(title.style?.color, colors.textPrimary);
        expect(
          title.style!.color!.computeLuminance() > 0.5,
          colors.backgroundPrimary.computeLuminance() < 0.5,
        );
      });

      testWidgets('an idle dashboard never reports a healthy score',
          (tester) async {
        await pump(tester, entry.value, _idle());
        final context = tester.element(find.byType(DashboardScreen));
        final colors = CsColors.of(context);

        expect(find.text('Monitoring inactive'), findsOneWidget);
        expect(find.text('Unknown'), findsWidgets);
        expect(find.text('Low Risk'), findsNothing);
        expect(find.text('Low'), findsNothing);

        // Text alone is not enough: the risk indicator and its progress bar are
        // tinted from the resolved severity, so a null score that fell through
        // to "low" would still paint the card green without printing a word.
        final indicator = tester.widget<Icon>(find.byIcon(LucideIcons.shield));
        expect(indicator.color, colors.textTertiary);
        expect(indicator.color, isNot(colors.severityNormal));
        expect(indicator.color, isNot(colors.success));
      });

      testWidgets('an unavailable rate is muted, while real counts are not',
          (tester) async {
        await pump(tester, entry.value, _idle());
        final context = tester.element(find.byType(DashboardScreen));
        final colors = CsColors.of(context);

        // No session has run, so there is no completion rate. It must not be
        // drawn with the same weight and colour as a measured value.
        final unavailable = tester.widget<Text>(find.descendant(
          of: find.byType(MetricCard).at(2),
          matching: find.text('N/A'),
        ));
        expect(unavailable.style?.color, colors.textTertiary);

        final measured = tester.widget<Text>(find.descendant(
          of: find.byType(MetricCard).at(0),
          matching: find.text('0'),
        ));
        expect(measured.style?.color, colors.textPrimary);
      });

      testWidgets('a stopped session reports its final score and distribution',
          (tester) async {
        await pump(tester, entry.value, _stoppedSession());

        expect(tester.takeException(), isNull);
        expect(find.text('82 / 100'), findsOneWidget);
        expect(find.text('Last Session Threat Score'), findsOneWidget);
        expect(
          find.text('High Risk Detected — Last completed session'),
          findsOneWidget,
        );
        expect(find.text('Critical'), findsWidgets);

        // 900 of 1080 classified normal.
        expect(find.byType(PieChart), findsOneWidget);
        expect(find.text('83.3%'), findsOneWidget);
        expect(find.text('Normal Traffic'), findsOneWidget);
        expect(find.text('No packets classified yet'), findsNothing);
        expect(find.text('Complete'), findsOneWidget);
        expect(find.text('Not analyzed'), findsWidgets);
      });

      testWidgets('a live session uses current-session wording',
          (tester) async {
        await pump(tester, entry.value, _liveSession());

        expect(tester.takeException(), isNull);
        expect(find.text('Threat Score'), findsOneWidget);
        expect(find.text('Last Session Threat Score'), findsNothing);
        expect(find.text('Real-Time Network Traffic'), findsOneWidget);
        expect(find.text('Current Session Captured'), findsOneWidget);
        expect(find.text('Last Session Overview'), findsNothing);
      });

      testWidgets('no overflow at 360px', (tester) async {
        await pump(tester, entry.value, _idle(), width: 360);

        expect(tester.takeException(), isNull);
      });

      testWidgets('no overflow at 360px with a populated session',
          (tester) async {
        await pump(tester, entry.value, _stoppedSession(), width: 360);

        expect(tester.takeException(), isNull);
      });
    });
  }

  group('migration completeness', () {
    test('only the frozen breakpoint helper is still read from AppTheme', () {
      final source =
          File('lib/screens/dashboard_screen.dart').readAsStringSync();

      // `AppTheme.isMobile` is a layout helper whose 1024px threshold the
      // dashboard has always used. Every colour, spacing and radius reference
      // must come from the token layer, or light mode stays unreadable.
      final references =
          RegExp(r'AppTheme\.\w+').allMatches(source).map((m) => m.group(0));
      expect(references.toSet(), {'AppTheme.isMobile'});
    });

    test('the dashboard widgets no longer read the frozen legacy palette', () {
      for (final path in _migratedSources.skip(1)) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains('AppTheme.')), reason: path);
        expect(source, isNot(contains('Colors.white')), reason: path);
        expect(source, isNot(contains('Colors.orange')), reason: path);
        expect(source, isNot(contains('withOpacity')), reason: path);
      }
    });

    test('no Material glyph is left in the dashboard widgets', () {
      // `\bIcons.` does not match `LucideIcons.` — there is no word boundary
      // between the "e" and the "I".
      final materialGlyph = RegExp(r'\bIcons\.');
      for (final path in _migratedSources) {
        final source = File(path).readAsStringSync();
        expect(materialGlyph.hasMatch(source), isFalse, reason: path);
      }
    });
  });
}
