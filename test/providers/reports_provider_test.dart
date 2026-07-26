import 'dart:async';
import 'dart:typed_data';

import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'package:cybersentinel/providers/reports_provider.dart';
import 'package:cybersentinel/services/report_file_saver.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> reportSummary({
  bool partial = false,
  bool empty = false,
}) {
  return {
    'generated_at': '2026-07-26T10:00:00Z',
    'timeframe': 'last_session',
    'monitoring_state': 'stopped',
    'interface': 'en0',
    'session': {
      'captured': 10,
      'analyzed': empty ? 0 : 6,
      'pending': 0,
      'complete': empty ? 0 : 4,
      'partial': empty ? 0 : 2,
      'failed': 1,
      'deferred': 1,
      'not_analyzed': empty ? 8 : 2,
      'completion_percentage': empty ? 0.0 : 60.0,
      'threat_score': empty ? null : 42.5,
      'highest_severity': empty ? null : 'MEDIUM',
    },
    'classification_distribution': {
      'normal': empty ? 0 : 3,
      'suspicious': empty ? 0 : 2,
      'malicious': 0,
      'unknown': empty ? 0 : 1,
    },
    'severity_distribution': {
      'low': 0,
      'medium': 0,
      'high': empty ? 0 : 1,
      'critical': 0,
      'unknown': 0,
    },
    'top_threat_types': empty
        ? []
        : [
            {'threat_type': 'Port Scan', 'count': 1}
          ],
    'top_attackers': empty
        ? []
        : [
            {
              'source_ip': '203.0.113.5',
              'count': 1,
              'highest_severity': 'HIGH',
              'country': null,
            }
          ],
    'recent_alerts': [],
    'response_timeline': [],
    'model_availability': {
      'model1_evaluated': empty ? 0 : 6,
      'model2_evaluated': empty ? 0 : 6,
      'model3_available': null,
      'partial_analysis': empty ? 0 : 2,
      'failed_analysis': 1,
    },
    'source_status': {
      'capture': 'available',
      'alerts': partial ? 'unavailable' : 'available',
      'actions': 'available',
      'intelligence': 'available',
    },
    'messages':
        partial ? ['Recent alert data is temporarily unavailable.'] : [],
  };
}

class FakeSaver implements ReportFileSaver {
  final ReportSaveResult result;
  final Object? error;
  int calls = 0;
  Uint8List? bytes;

  FakeSaver(this.result, {this.error});

  @override
  Future<ReportSaveResult> save({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    calls++;
    this.bytes = bytes;
    if (error != null) throw error!;
    return result;
  }
}

AuthenticatedDownload download() => AuthenticatedDownload(
      bytes: Uint8List.fromList([1, 2, 3]),
      contentType: 'application/pdf',
      filename: 'cybersentinel-report.pdf',
    );

void main() {
  test('provider loads normalized summary from its local loader', () async {
    var calls = 0;
    final provider = ReportsProvider(
      summaryLoader: () async {
        calls++;
        return reportSummary();
      },
      exportLoader: (_) async => download(),
      fileSaver: FakeSaver(const ReportSaveResult.saved('/tmp/report.pdf')),
      listenToWebSocket: false,
    );

    await provider.refresh();

    expect(calls, 1);
    expect(provider.state, ReportLoadState.data);
    expect(provider.summary?.session.captured, 10);
    expect(provider.summary?.session.analyzed, 6);
    provider.dispose();
  });

  test('overlapping refresh calls are single-flight', () async {
    final release = Completer<Map<String, dynamic>>();
    var calls = 0;
    final provider = ReportsProvider(
      summaryLoader: () {
        calls++;
        return release.future;
      },
      exportLoader: (_) async => download(),
      fileSaver: FakeSaver(const ReportSaveResult.cancelled()),
      listenToWebSocket: false,
    );

    final first = provider.refresh();
    final second = provider.refresh();
    expect(calls, 1);
    release.complete(reportSummary());
    await Future.wait([first, second]);
    expect(provider.state, ReportLoadState.data);
    provider.dispose();
  });

  test('partial source differs from genuine zero data', () async {
    final partial = ReportsProvider(
      summaryLoader: () async => reportSummary(partial: true),
      exportLoader: (_) async => download(),
      fileSaver: FakeSaver(const ReportSaveResult.cancelled()),
      listenToWebSocket: false,
    );
    await partial.refresh();
    expect(partial.state, ReportLoadState.partial);
    expect(partial.summary?.sourceStatus.alerts, 'unavailable');

    final empty = ReportsProvider(
      summaryLoader: () async => reportSummary(empty: true),
      exportLoader: (_) async => download(),
      fileSaver: FakeSaver(const ReportSaveResult.cancelled()),
      listenToWebSocket: false,
    );
    await empty.refresh();
    expect(empty.state, ReportLoadState.data);
    expect(empty.summary?.severityDistribution.total, 0);
    partial.dispose();
    empty.dispose();
  });

  test('safe load error retains previous successful summary', () async {
    var fail = false;
    final provider = ReportsProvider(
      summaryLoader: () async => fail
          ? {
              'error': true,
              'status_code': 503,
              'message': 'raw backend body',
            }
          : reportSummary(),
      exportLoader: (_) async => download(),
      fileSaver: FakeSaver(const ReportSaveResult.cancelled()),
      listenToWebSocket: false,
    );
    await provider.refresh();
    fail = true;
    await provider.refresh(silent: true);

    expect(provider.summary?.session.captured, 10);
    expect(provider.state, ReportLoadState.partial);
    expect(provider.error, 'Report data is temporarily unavailable.');
    expect(provider.error, isNot(contains('raw backend')));
    provider.dispose();
  });

  test('each export uses its canonical local-sidecar type', () async {
    final requested = <String>[];
    final saver = FakeSaver(const ReportSaveResult.saved('/tmp/report.file'));
    final provider = ReportsProvider(
      summaryLoader: () async => reportSummary(),
      exportLoader: (type) async {
        requested.add(type);
        return download();
      },
      fileSaver: saver,
      listenToWebSocket: false,
    );

    for (final kind in ReportExportKind.values) {
      final outcome = await provider.export(kind);
      expect(outcome.status, ReportExportStatus.saved);
    }

    expect(requested, [
      'pdf',
      'json',
      'alerts_csv',
      'actions_csv',
    ]);
    expect(saver.calls, 4);
    provider.dispose();
  });

  test('duplicate export requests are prevented', () async {
    final release = Completer<AuthenticatedDownload>();
    var calls = 0;
    final provider = ReportsProvider(
      summaryLoader: () async => reportSummary(),
      exportLoader: (_) {
        calls++;
        return release.future;
      },
      fileSaver: FakeSaver(const ReportSaveResult.saved('/tmp/report.pdf')),
      listenToWebSocket: false,
    );

    final first = provider.export(ReportExportKind.pdf);
    final duplicate = await provider.export(ReportExportKind.pdf);
    expect(duplicate.status, ReportExportStatus.busy);
    expect(calls, 1);
    release.complete(download());
    expect((await first).status, ReportExportStatus.saved);
    provider.dispose();
  });

  test('save cancellation and failure remain safe', () async {
    final cancelled = ReportsProvider(
      summaryLoader: () async => reportSummary(),
      exportLoader: (_) async => download(),
      fileSaver: FakeSaver(const ReportSaveResult.cancelled()),
      listenToWebSocket: false,
    );
    final cancelledResult = await cancelled.export(ReportExportKind.pdf);
    expect(cancelledResult.status, ReportExportStatus.cancelled);
    expect(cancelledResult.message, 'Export was cancelled.');

    final failed = ReportsProvider(
      summaryLoader: () async => reportSummary(),
      exportLoader: (_) async => download(),
      fileSaver: FakeSaver(
        const ReportSaveResult.cancelled(),
        error: StateError('/secret/path raw failure'),
      ),
      listenToWebSocket: false,
    );
    final failedResult = await failed.export(ReportExportKind.pdf);
    expect(failedResult.status, ReportExportStatus.failed);
    expect(failedResult.message, 'The file could not be saved.');
    expect(failedResult.message, isNot(contains('/secret/path')));
    cancelled.dispose();
    failed.dispose();
  });
}
