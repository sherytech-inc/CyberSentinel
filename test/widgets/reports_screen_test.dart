import 'dart:typed_data';

import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'package:cybersentinel/providers/reports_provider.dart';
import 'package:cybersentinel/screens/reports_screen.dart';
import 'package:cybersentinel/services/report_file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../providers/reports_provider_test.dart' show reportSummary;

class _Saver implements ReportFileSaver {
  @override
  Future<ReportSaveResult> save({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    return const ReportSaveResult.cancelled();
  }
}

ReportsProvider providerFor(Map<String, dynamic> data) {
  return ReportsProvider(
    summaryLoader: () async => data,
    exportLoader: (_) async => AuthenticatedDownload(
      bytes: Uint8List.fromList([1]),
      contentType: 'application/pdf',
      filename: 'report.pdf',
    ),
    fileSaver: _Saver(),
    listenToWebSocket: false,
  );
}

Future<void> pumpReports(
  WidgetTester tester,
  ReportsProvider provider, {
  Size size = const Size(1180, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: Scaffold(body: ReportsScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('summary and real severity values render', (tester) async {
    final provider = providerFor(reportSummary());
    await pumpReports(tester, provider);

    expect(find.textContaining('Last Session'), findsWidgets);
    expect(find.text('10'), findsWidgets);
    expect(find.text('Port Scan'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.textContaining('Monitoring is inactive'), findsOneWidget);
    provider.dispose();
  });

  testWidgets('empty evidence uses a neutral truthful state', (tester) async {
    final provider = providerFor(reportSummary(empty: true));
    await pumpReports(tester, provider);

    expect(
      find.text('No analyzed threat data is available for this session.'),
      findsOneWidget,
    );
    expect(find.textContaining('network is safe'), findsNothing);
    expect(find.textContaining('actively monitoring'), findsNothing);
    provider.dispose();
  });

  testWidgets('source-unavailable message differs from empty data',
      (tester) async {
    final provider = providerFor(reportSummary(partial: true));
    await pumpReports(tester, provider);

    expect(
      find.textContaining('Unavailable sources: alerts'),
      findsOneWidget,
    );
    expect(
      find.text('Alert severity data is temporarily unavailable.'),
      findsOneWidget,
    );
    provider.dispose();
  });

  testWidgets('narrow Reports layout does not overflow', (tester) async {
    final provider = providerFor(reportSummary());
    await pumpReports(
      tester,
      provider,
      size: const Size(460, 900),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Export & Downloads'), findsOneWidget);
    provider.dispose();
  });
}
