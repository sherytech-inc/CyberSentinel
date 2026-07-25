import 'dart:async';

import 'package:cybersentinel/core/theme/app_theme.dart';
import 'package:cybersentinel/models/scan_result.dart';
import 'package:cybersentinel/providers/virus_scanner_provider.dart';
import 'package:cybersentinel/screens/virus_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Map<String, dynamic> scanJson({
  String type = 'url',
  String target = 'https://example.com',
  String status = 'completed',
  String verdict = 'clean',
  int malicious = 0,
  int suspicious = 0,
}) =>
    {
      'scan_type': type,
      'target': target,
      'status': status,
      'verdict': verdict,
      'malicious': malicious,
      'suspicious': suspicious,
      'harmless': 63,
      'undetected': 7,
      'provider': 'VIRUSTOTAL',
      'provider_contacted': true,
      'analysis_id': 'analysis-1',
      'scanned_at': '2026-07-21T10:00:00Z',
      'message': 'Scan completed.',
    };

Widget app(VirusScannerProvider provider, {Size size = const Size(1200, 850)}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppTheme.bgPrimary,
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
        ),
        home: const Scaffold(
            body: Padding(
                padding: EdgeInsets.all(20), child: VirusScannerScreen())),
      ),
    ),
  );
}

void main() {
  testWidgets('shows polished empty state and remains responsive at 462px',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(462, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester
        .pumpWidget(app(VirusScannerProvider(), size: const Size(462, 850)));
    expect(find.text('No scan result yet'), findsOneWidget);
    expect(find.text('Scan workspace'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('URL validation is inline and duplicate submission is prevented',
      (tester) async {
    final pending = Completer<Map<String, dynamic>>();
    var calls = 0;
    final provider = VirusScannerProvider(urlRequest: (_) {
      calls++;
      return pending.future;
    });
    await tester.pumpWidget(app(provider));
    await tester.enterText(
        find.byKey(const ValueKey('url-input')), 'not-a-url');
    await tester.tap(find.text('Scan URL'));
    await tester.pump();
    expect(find.text('Enter a valid HTTP or HTTPS URL.'), findsOneWidget);
    expect(calls, 0);

    await tester.enterText(
        find.byKey(const ValueKey('url-input')), 'https://example.com');
    await tester.tap(find.text('Scan URL'));
    await tester.pump();
    expect(find.text('Analyzing URL'), findsOneWidget);
    expect(calls, 1);
    pending.complete(scanJson());
    await tester.pumpAndSettle();
    expect(find.text('Clean'), findsOneWidget);
  });

  testWidgets('tab switching preserves URL input and detects hash type',
      (tester) async {
    await tester.pumpWidget(app(VirusScannerProvider()));
    await tester.enterText(
        find.byKey(const ValueKey('url-input')), 'https://kept.example');
    await tester.tap(find.byKey(const ValueKey('scanner-tab-hash')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('hash-input')), List.filled(64, 'a').join());
    await tester.pump();
    expect(find.text('Detected: SHA-256'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scanner-tab-url')));
    await tester.pumpAndSettle();
    expect(find.text('https://kept.example'), findsOneWidget);
  });

  testWidgets('selected file shows metadata and can be removed',
      (tester) async {
    final provider = VirusScannerProvider()
      ..selectFile('sample.bin', List.filled(2048, 1));
    await tester.pumpWidget(app(provider));
    await tester.tap(find.byKey(const ValueKey('scanner-tab-file')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('selected-file-card')), findsOneWidget);
    expect(find.text('sample.bin'), findsOneWidget);
    expect(find.text('2.0 KB · BIN'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove file'));
    await tester.pump();
    expect(find.byKey(const ValueKey('file-drop-zone')), findsOneWidget);
  });

  for (final testCase in [
    ('clean', 0, 0, 'Clean'),
    ('suspicious', 0, 1, 'Suspicious'),
    ('malicious', 2, 0, 'Malicious'),
  ]) {
    testWidgets('renders ${testCase.$1} verdict with detection statistics',
        (tester) async {
      final result = ScanResult.fromJson(scanJson(
        verdict: testCase.$1,
        malicious: testCase.$2,
        suspicious: testCase.$3,
      ));
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child:
                  SizedBox(width: 600, child: ScanResultPanel(result: result)),
            ),
          )));
      expect(find.text(testCase.$4), findsWidgets);
      expect(find.text('Malicious'), findsWidgets);
      expect(find.text('Suspicious'), findsWidgets);
      expect(find.text('Harmless'), findsOneWidget);
      expect(find.text('Undetected'), findsOneWidget);
    });
  }

  testWidgets('pending, not-found and unavailable states are safe',
      (tester) async {
    for (final entry in [
      ('pending', 'Analysis pending'),
      ('not_found', 'No existing report found'),
      ('unavailable', 'Scan temporarily unavailable'),
    ]) {
      final result =
          ScanResult.fromJson(scanJson(status: entry.$1, verdict: 'unknown'));
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SizedBox(width: 600, child: ScanResultPanel(result: result)),
          )));
      expect(find.text(entry.$2), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
    }
  });
}
