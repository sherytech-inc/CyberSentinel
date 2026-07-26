import 'package:cybersentinel/providers/dashboard_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DashboardProvider provider;

  setUp(() => provider = DashboardProvider(initializeAuth: false));
  tearDown(() => provider.dispose());

  void capture(String id) {
    provider.applyPacketBatchForTesting({
      'packets': [
        {'packet_id': id, 'analysis_status': 'pending'}
      ]
    });
  }

  test('reliable session score remains after monitoring stops', () {
    provider.applyCaptureDiagnosticsForTesting({'state': 'running'});
    capture('p1');
    provider.applyAnalysisUpdateForTesting({
      'packet_ids': ['p1'],
      'analysis_status': 'complete',
      'threat_score': 31,
    });
    provider.applyCaptureDiagnosticsForTesting({'state': 'stopped'});

    expect(provider.isMonitoringActive, isFalse);
    expect(provider.lastSessionThreatScore, 31);
    expect(provider.hasReliableThreatScore, isTrue);
  });

  test('session without reliable analysis stops with N/A', () {
    provider.applyCaptureDiagnosticsForTesting({'state': 'running'});
    capture('p1');
    provider.applyCaptureDiagnosticsForTesting({'state': 'stopped'});

    expect(provider.lastSessionThreatScore, isNull);
    expect(provider.hasReliableThreatScore, isFalse);
  });

  test('new session does not inherit historical score as live evidence', () {
    provider.applyCaptureDiagnosticsForTesting({'state': 'running'});
    capture('p1');
    provider.applyAnalysisUpdateForTesting({
      'packet_ids': ['p1'],
      'analysis_status': 'partial',
      'threat_score': 22,
    });
    provider.applyCaptureDiagnosticsForTesting({'state': 'stopped'});
    provider.applyCaptureDiagnosticsForTesting({'state': 'running'});

    expect(provider.lastSessionThreatScore, 22);
    expect(provider.currentSessionThreatScore, isNull);
    expect(provider.hasReliableThreatScore, isFalse);
  });

  test('repeated stopped diagnostics cannot overwrite retained session score',
      () {
    provider.applyCaptureDiagnosticsForTesting({'state': 'running'});
    capture('p1');
    provider.applyAnalysisUpdateForTesting({
      'packet_ids': ['p1'],
      'analysis_status': 'complete',
      'threat_score': 47,
    });
    provider.applyCaptureDiagnosticsForTesting({'state': 'stopped'});
    provider.applyCaptureDiagnosticsForTesting({
      'state': 'stopped',
      'threat_score': 3,
    });

    expect(provider.lastSessionThreatScore, 47);
  });

  test('in-memory last-session summary exposes inactive dashboard values', () {
    provider.applyLastSessionForTesting({
      'session_id': 'session-1',
      'status': 'completed',
      'capture_mode': 'live',
      'captured_count': 523,
      'analyzed_count': 73,
      'pending_count': 0,
      'complete_count': 60,
      'partial_count': 13,
      'failed_count': 20,
      'deferred_count': 34,
      'not_analyzed_count': 396,
      'normal_count': 60,
      'suspicious_count': 0,
      'malicious_count': 0,
      'unknown_count': 13,
      'last_reliable_score': 31,
      'highest_severity': 'MEDIUM',
    });

    expect(provider.isMonitoringActive, isFalse);
    expect(provider.capturedPacketsCount, 523);
    expect(provider.analyzedPacketsCount, 73);
    expect(provider.pendingPacketsCount, 0);
    expect(provider.analysisCompletion, closeTo(73 / 523, 0.0001));
    expect(provider.lastSessionThreatScore, 31);
    expect(
        provider.normalCount +
            provider.suspiciousCount +
            provider.maliciousCount +
            provider.unknownCount,
        73);
  });

  test('unique session counters preserve the partition invariant', () {
    provider.applyCaptureDiagnosticsForTesting({'state': 'running'});
    capture('p1');
    capture('p2');
    capture('p2');
    capture('p3');
    provider.applyAnalysisUpdateForTesting({
      'packet_ids': ['p1', 'p2'],
      'analysis_status': 'complete',
      'ml_prediction': 'Normal',
      'threat_score': 8,
    });
    provider.applyAnalysisUpdateForTesting({
      'packet_ids': ['p1', 'p2'],
      'analysis_status': 'complete',
      'ml_prediction': 'Normal',
      'threat_score': 8,
    });

    expect(provider.capturedPacketsCount, 3);
    expect(provider.analyzedPacketsCount, 2);
    expect(provider.pendingPacketsCount, 1);
    expect(
        provider.analyzedPacketsCount <= provider.capturedPacketsCount, isTrue);
    expect(
      provider.analyzedPacketsCount +
          provider.pendingPacketsCount +
          provider.failedPacketsCount +
          provider.deferredPacketsCount +
          provider.notAnalyzedPacketsCount,
      provider.capturedPacketsCount,
    );

    provider.applyCaptureDiagnosticsForTesting({'state': 'stopped'});
    expect(provider.pendingPacketsCount, 0);
    expect(provider.notAnalyzedPacketsCount, 1);
    expect(provider.completePacketsCount, 2);
    expect(provider.partialPacketsCount, 0);
    expect(
      provider.completePacketsCount +
          provider.partialPacketsCount +
          provider.failedPacketsCount +
          provider.deferredPacketsCount +
          provider.notAnalyzedPacketsCount +
          provider.pendingPacketsCount,
      provider.capturedPacketsCount,
    );
    expect(provider.trafficData, hasLength(2));
    expect(provider.trafficData.last.pending, 1);
  });

  test('new capture gets empty live counters while retaining old snapshot', () {
    provider.applyCaptureDiagnosticsForTesting({'state': 'running'});
    capture('p1');
    provider.applyAnalysisUpdateForTesting({
      'packet_ids': ['p1'],
      'analysis_status': 'complete',
      'ml_prediction': 'malicious',
      'threat_score': 81,
    });
    provider.applyCaptureDiagnosticsForTesting({'state': 'stopped'});

    expect(provider.lastSessionThreatScore, 81);
    expect(provider.capturedPacketsCount, 1);

    provider.applyCaptureDiagnosticsForTesting({'state': 'running'});

    expect(provider.currentSessionThreatScore, isNull);
    expect(provider.lastSessionThreatScore, 81);
    expect(provider.capturedPacketsCount, 0);
    expect(provider.analyzedPacketsCount, 0);
    expect(provider.pendingPacketsCount, 0);
    expect(provider.trafficData, isEmpty);
  });

  test('stopping retains current values until terminal diagnostics arrive', () {
    provider.applyCaptureDiagnosticsForTesting({
      'state': 'running',
      'session_id': 'session-a',
      'packets_captured': 4,
      'analysis': {
        'completed_packets': 1,
        'partial_packets': 1,
        'failed_packets': 0,
        'deferred_packets': 0,
        'cancelled_packets': 0,
      },
    });
    provider.applyAnalysisUpdateForTesting({
      'packet_ids': ['p1'],
      'analysis_status': 'complete',
      'ml_prediction': 'normal',
      'threat_score': 19,
    });
    provider.applyCaptureDiagnosticsForTesting({
      'state': 'stopping',
      'session_id': 'session-a',
      'packets_captured': 4,
      'analysis': {
        'completed_packets': 1,
        'partial_packets': 1,
        'failed_packets': 0,
        'deferred_packets': 0,
        'cancelled_packets': 0,
      },
    });

    expect(provider.isMonitoringActive, isFalse);
    expect(provider.isCurrentSessionVisible, isTrue);
    expect(provider.capturedPacketsCount, 4);
    expect(provider.analyzedPacketsCount, 2);
    expect(provider.pendingPacketsCount, 2);
    expect(provider.currentSessionThreatScore, 19);
    expect(provider.lastSession, isNull);
  });

  test('terminal diagnostics finalize authoritative counts atomically', () {
    provider.applyCaptureDiagnosticsForTesting({
      'state': 'running',
      'session_id': 'session-a',
      'packets_captured': 523,
      'analysis': {
        'completed_packets': 60,
        'partial_packets': 13,
        'failed_packets': 20,
        'deferred_packets': 34,
        'cancelled_packets': 0,
      },
    });
    provider.applyAnalysisUpdateForTesting({
      'packet_ids': ['known-packet'],
      'analysis_status': 'complete',
      'ml_prediction': 'normal',
      'threat_score': 31,
    });
    provider.applyCaptureDiagnosticsForTesting({
      'state': 'stopped',
      'session_id': 'session-a',
      'packets_captured': 523,
      'analysis': {
        'completed_packets': 60,
        'partial_packets': 13,
        'failed_packets': 20,
        'deferred_packets': 34,
        'cancelled_packets': 396,
      },
    });

    expect(provider.isCurrentSessionVisible, isFalse);
    expect(provider.capturedPacketsCount, 523);
    expect(provider.completePacketsCount, 60);
    expect(provider.partialPacketsCount, 13);
    expect(provider.analyzedPacketsCount, 73);
    expect(provider.failedPacketsCount, 20);
    expect(provider.deferredPacketsCount, 34);
    expect(provider.notAnalyzedPacketsCount, 396);
    expect(provider.pendingPacketsCount, 0);
    expect(
      provider.completePacketsCount +
          provider.partialPacketsCount +
          provider.failedPacketsCount +
          provider.deferredPacketsCount +
          provider.notAnalyzedPacketsCount +
          provider.pendingPacketsCount,
      provider.capturedPacketsCount,
    );
    expect(
      provider.normalCount +
          provider.suspiciousCount +
          provider.maliciousCount +
          provider.unknownCount,
      provider.analyzedPacketsCount,
    );
  });

  test('empty stopped polling cannot clear a finalized snapshot', () {
    provider.applyCaptureDiagnosticsForTesting({
      'state': 'running',
      'session_id': 'session-a',
    });
    capture('p1');
    provider.applyAnalysisUpdateForTesting({
      'packet_ids': ['p1'],
      'analysis_status': 'complete',
      'ml_prediction': 'normal',
      'threat_score': 27,
    });
    provider.applyCaptureDiagnosticsForTesting({
      'state': 'stopped',
      'session_id': 'session-a',
      'packets_captured': 1,
      'analysis': {
        'completed_packets': 1,
      },
    });

    for (var i = 0; i < 3; i++) {
      provider.applyCaptureDiagnosticsForTesting({
        'state': 'stopped',
        'packets_captured': 0,
        'analysis': const {},
      });
    }

    expect(provider.capturedPacketsCount, 1);
    expect(provider.analyzedPacketsCount, 1);
    expect(provider.lastSessionThreatScore, 27);
  });

  test('terminal status from another session cannot finalize the new session',
      () {
    provider.applyCaptureDiagnosticsForTesting({
      'state': 'running',
      'session_id': 'new-session',
      'packets_captured': 2,
    });
    provider.applyCaptureDiagnosticsForTesting({
      'state': 'stopped',
      'session_id': 'old-session',
      'packets_captured': 0,
    });

    expect(provider.isCurrentSessionVisible, isTrue);
    expect(provider.capturedPacketsCount, 2);
    expect(provider.lastSession, isNull);
  });

  test('analysis updates for unseen raw IDs remain unique and classified once',
      () {
    provider.applyCaptureDiagnosticsForTesting({
      'state': 'running',
      'packets_captured': 2,
    });
    final update = {
      'packet_ids': ['p1', 'p2', 'p2'],
      'analysis_status': 'complete',
      'ml_prediction': 'normal',
      'threat_score': 11,
    };
    provider.applyAnalysisUpdateForTesting(update);
    provider.applyAnalysisUpdateForTesting(update);

    expect(provider.capturedPacketsCount, 2);
    expect(provider.analyzedPacketsCount, 2);
    expect(provider.normalCount, 2);
    expect(provider.unknownCount, 0);
  });
}
