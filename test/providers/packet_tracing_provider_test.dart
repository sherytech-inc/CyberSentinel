import 'package:flutter_test/flutter_test.dart';
import 'package:cybersentinel/providers/packet_tracing_provider.dart';
import 'package:cybersentinel/models/packet.dart';

void main() {
  PacketTracingProvider createProvider() =>
      PacketTracingProvider(initializeAuth: false);

  test('start does not optimistically set running', () {
    final provider = createProvider();
    provider.applyCaptureStatus({'state': 'starting'});
    expect(provider.captureState, CaptureState.starting);
    expect(provider.isCapturing, false);
  });

  test('start waits for backend running state', () {
    final provider = createProvider();
    provider.applyCaptureStatus({'state': 'starting'});
    provider.applyCaptureStatus({'state': 'running'});
    expect(provider.captureState, CaptureState.running);
  });

  test('stop waits for backend stopped state', () {
    final provider = createProvider();
    provider.applyCaptureStatus({'state': 'running'});
    provider.applyCaptureStatus({'state': 'stopping'});
    expect(provider.captureState, CaptureState.stopping);
    provider.applyCaptureStatus({'state': 'stopped'});
    expect(provider.captureState, CaptureState.stopped);
  });

  test('daemon error maps to error state', () {
    final provider = createProvider();
    provider.applyCaptureStatus({'state': 'error', 'error': 'Daemon failed'});
    expect(provider.captureState, CaptureState.error);
    expect(provider.captureError, 'Daemon failed');
  });

  test('temporary status failure preserves last authoritative state', () {
    final provider = createProvider();
    provider.applyCaptureStatus({
      'error': true,
      'message': 'Network unavailable',
    });
    expect(provider.captureState, CaptureState.stopped);
    expect(provider.captureError, 'Network unavailable');
  });

  test('polling recovers after temporary failure', () {
    final provider = createProvider();
    provider.applyCaptureStatus({
      'error': true,
      'message': 'Network unavailable',
    });
    provider.applyCaptureStatus({'state': 'running'});
    expect(provider.captureState, CaptureState.running);
  });

  test('status updates are ignored after dispose', () {
    final provider = createProvider();
    provider.applyCaptureStatus({'state': 'running'});
    provider.dispose();
    provider.applyCaptureStatus({'state': 'stopped'});
    expect(provider.captureState, CaptureState.running);
  });

  test('422 start failure restores idle state and exposes validation detail',
      () async {
    final provider = createProvider();
    provider.startCaptureRequest = (_) async => {
          'error': true,
          'status_code': 422,
          'message': 'Field required (body.interface_id)',
        };

    await provider.toggleCapturing(interfaceName: 'en0');

    expect(provider.captureState, CaptureState.stopped);
    expect(provider.isTransitioning, false);
    expect(provider.captureError, 'Field required (body.interface_id)');
  });

  test('successful start reaches running state', () async {
    final provider = createProvider();
    provider.startCaptureRequest = (_) async => {'status': 'started'};
    provider.captureStatusRequest = () async => {'state': 'running'};
    provider.onCaptureStarted = () async {};

    await provider.toggleCapturing(interfaceName: 'en0');

    expect(provider.captureState, CaptureState.running);
    expect(provider.isCapturing, true);
  });

  test('successful stop reaches stopped state', () async {
    final provider = createProvider();
    provider.injectMockPackets([
      Packet(
        id: 'retained-packet',
        ip: '192.168.1.10',
        port: 443,
        protocol: 'HTTPS',
        size: '128 B',
        status: PacketStatus.benign,
        timestamp: '10:00:00',
      ),
    ]);
    provider.applyCaptureStatus({'state': 'running'});
    provider.stopCaptureRequest = () async => {'status': 'stopped'};
    provider.captureStatusRequest = () async => {'state': 'stopped'};

    await provider.toggleCapturing();

    expect(provider.captureState, CaptureState.stopped);
    expect(provider.packets.single.id, 'retained-packet');
  });

  test('optional packet history failure is suppressed for live capture',
      () async {
    final provider = createProvider();
    provider.packetHistoryRequest = (_) async => {
          'error': true,
          'status_code': 500,
          'message': 'History temporarily unavailable',
        };
    await provider.fetchPackets();
    expect(provider.error, isNull);

    provider.startCaptureRequest = (_) async => {'status': 'started'};
    provider.captureStatusRequest = () async => {'state': 'running'};
    provider.onCaptureStarted = () async {};
    await provider.toggleCapturing(interfaceName: 'en0');

    expect(provider.captureState, CaptureState.running);
    expect(provider.captureError, isNull);
    expect(provider.error, isNull);
  });

  test('historical rows never enter the current live packet table', () async {
    final provider = createProvider();
    provider.injectMockPackets([
      Packet(
        id: 'live-only',
        ip: '192.168.1.2',
        port: 443,
        protocol: 'TCP',
        size: '64 B',
        status: PacketStatus.unknown,
        timestamp: '12:00:00',
      ),
    ]);
    provider.packetHistoryRequest = (_) async => {
          'items': [
            {'id': 'historical-row', 'source_ip': '10.0.0.1'}
          ],
          'total': 1,
        };

    await provider.fetchPackets();

    expect(provider.packets.map((packet) => packet.id), ['live-only']);
  });

  test('authenticated packet batch increments count and supports selection',
      () {
    final provider = createProvider();
    provider.applyPacketBatch({
      'packets': [
        {
          'id': 'live-1',
          'source_ip': '192.168.0.7',
          'destination_port': 443,
          'protocol': 'TCP',
          'packet_size': 128,
          'ml_prediction': 'Pending',
          'severity': 'Analysis pending',
          'captured_at': '2026-07-20T23:17:52Z',
        }
      ]
    });

    expect(provider.totalPacketsReceived, 1);
    expect(provider.packets.single.id, 'live-1');
    provider.selectPacketById('live-1');
    expect(provider.selectedPacket?.id, 'live-1');
  });

  test('analysis update replaces pending row without appending a duplicate',
      () {
    final provider = createProvider();
    provider.applyPacketBatch({
      'packets': [
        {
          'id': 'live-1',
          'source_ip': '192.168.0.7',
          'destination_port': 443,
          'protocol': 'TCP',
          'packet_size': 128,
          'ml_prediction': 'Pending',
          'analysis_status': 'pending',
          'captured_at': '2026-07-20T23:17:52Z',
        }
      ]
    });

    provider.applyPacketAnalysisUpdate({
      'packet_ids': ['live-1'],
      'analysis_status': 'complete',
      'ml_prediction': 'Malicious',
      'threat_score': 87.5,
      'severity': 'High',
    });

    expect(provider.packets, hasLength(1));
    expect(provider.packets.single.status, PacketStatus.malicious);
    expect(provider.packets.single.analysisStatus, 'complete');
    expect(provider.packets.single.threatScore, 87.5);
  });

  test('flow update reaches every related packet and notifications coalesce',
      () async {
    final provider = createProvider();
    var notifications = 0;
    provider.addListener(() => notifications++);
    for (var batch = 0; batch < 5; batch++) {
      provider.applyPacketBatch({
        'packets': [
          {
            'packet_id': 'packet-$batch',
            'flow_id': 'flow-1',
            'source_ip': '192.168.0.7',
            'destination_port': 443,
            'protocol': 'TCP',
            'packet_size': 128,
            'ml_prediction': 'Pending',
            'analysis_status': 'pending',
          }
        ]
      });
    }
    provider.applyPacketAnalysisUpdate({
      'flow_id': 'flow-1',
      'packet_ids': const <String>[],
      'analysis_status': 'complete',
      'ml_prediction': 'Normal',
      'threat_score': 4.0,
    });

    expect(
        provider.packets.every((packet) => packet.analysisStatus == 'complete'),
        isTrue);
    await Future<void>.delayed(
        PacketTracingProvider.packetNotificationInterval +
            const Duration(milliseconds: 20));
    expect(notifications, 1);
  });

  test('stopping terminalizes every visible pending packet', () {
    final provider = createProvider();
    provider.applyPacketBatch({
      'packets': [
        {
          'packet_id': 'pending-1',
          'flow_id': 'flow-1',
          'source_ip': '192.168.0.7',
          'destination_port': 443,
          'protocol': 'TCP',
          'packet_size': 128,
          'ml_prediction': 'Pending',
          'analysis_status': 'pending',
        }
      ]
    });
    provider.applyCaptureStatus({'state': 'stopped'});

    expect(provider.pendingCount, 0);
    expect(provider.packets.single.analysisStatus, 'not_analyzed');
    expect(provider.packets.single.mlClassification, 'NOT ANALYZED');
  });
}
