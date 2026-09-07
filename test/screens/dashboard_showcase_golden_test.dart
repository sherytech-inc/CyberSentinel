import 'dart:io';

import 'package:cybersentinel/models/analyst_profile.dart';
import 'package:cybersentinel/providers/app_state_provider.dart';
import 'package:cybersentinel/providers/auth_provider.dart';
import 'package:cybersentinel/providers/dashboard_provider.dart';
import 'package:cybersentinel/providers/settings_provider.dart';
import 'package:cybersentinel/screens/dashboard_screen.dart';
import 'package:cybersentinel/screens/main_layout.dart';
import 'package:cybersentinel/widgets/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

/// Design-review goldens: the real shell around the real dashboard, rendered
/// at desktop size with the real fonts (loaded in [main]'s `setUpAll`, scoped
/// to this file so pure-Dart provider tests keep real-HTTP semantics).
/// Regenerate after intentional visual changes with:
///
/// ```sh
/// flutter test test/screens/dashboard_showcase_golden_test.dart --update-goldens
/// ```
///
/// The auth provider is stubbed with a signed-out idle state because that is
/// the branch that renders the shell; the dashboard provider is the real one,
/// driven through its `@visibleForTesting` hooks.
class _ShowcaseAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool get isLoading => false;

  @override
  User? get user => null;

  @override
  AnalystProfile? get profile => null;

  @override
  String? get error => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> retryProfileBootstrap() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DashboardProvider _stoppedSession() {
  final provider = DashboardProvider(initializeAuth: false);
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
  final provider = DashboardProvider(initializeAuth: false);
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

void main() {
  setUpAll(() async {
    // google_fonts names the ambient family 'Inter_regular', while explicit
    // CsTypography styles request 'Inter' — register the same file under both.
    ByteData bytes(String path) =>
        ByteData.view(File(path).readAsBytesSync().buffer);
    final inter = FontLoader('Inter')
      ..addFont(Future.value(bytes('test/fixtures/fonts/Inter.ttf')));
    final interRegular = FontLoader('Inter_regular')
      ..addFont(Future.value(bytes('test/fixtures/fonts/Inter.ttf')));
    final lucide = FontLoader('packages/lucide_icons_flutter/Lucide')
      ..addFont(Future.value(bytes('test/fixtures/fonts/lucide.ttf')));
    await inter.load();
    await interRegular.load();
    await lucide.load();
  });

  // Matches what app.dart achieves with GoogleFonts.interTextTheme, without
  // involving google_fonts' own asset/network pipeline: setUpAll registers
  // the real Inter file under this family name.
  ThemeData darkTheme() => CsTheme.dark(
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter'));
  ThemeData lightTheme() => CsTheme.light(
      textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Inter'));

  Future<void> pumpShowcase(
    WidgetTester tester, {
    required ThemeData theme,
    required DashboardProvider dashboard,
  }) async {
    SharedPreferences.setMockInitialValues({});
    // devicePixelRatio defaults to 3.0 in tests, which would make a 1440x900
    // physical surface only 480x300 logical and force the mobile layout.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(
            value: _ShowcaseAuthProvider(),
          ),
          ChangeNotifierProvider<AppStateProvider>(
            create: (_) => AppStateProvider(),
          ),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
          ),
          ChangeNotifierProvider<DashboardProvider>.value(value: dashboard),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: theme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('dark shell with a stopped session', (tester) async {
    await pumpShowcase(tester, theme: darkTheme(), dashboard: _stoppedSession());

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MainLayout),
      matchesGoldenFile('goldens/dashboard_shell_dark.png'),
    );
  });

  testWidgets('light shell with a stopped session', (tester) async {
    await pumpShowcase(tester,
        theme: lightTheme(), dashboard: _stoppedSession());

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MainLayout),
      matchesGoldenFile('goldens/dashboard_shell_light.png'),
    );
  });

  testWidgets('dark shell with a live session', (tester) async {
    await pumpShowcase(tester, theme: darkTheme(), dashboard: _liveSession());

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MainLayout),
      matchesGoldenFile('goldens/dashboard_shell_live.png'),
    );
  });
}
