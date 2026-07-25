import 'package:flutter_test/flutter_test.dart';
import 'package:cybersentinel/models/packet.dart';

void main() {
  Packet makePacket({
    PacketStatus status = PacketStatus.benign,
    String? severity,
    double? threatScore,
    String id = 'test-1',
  }) {
    return Packet(
      id: id,
      ip: '192.168.1.1',
      port: 80,
      protocol: 'TCP',
      size: '128 B',
      status: status,
      timestamp: '12:00:00',
      severity: severity,
      threatScore: threatScore,
    );
  }

  group('mlClassification', () {
    test('status benign returns BENIGN', () {
      final p = makePacket(status: PacketStatus.benign);
      expect(p.mlClassification, 'BENIGN');
    });

    test('status suspicious returns SUSPICIOUS', () {
      final p = makePacket(status: PacketStatus.suspicious);
      expect(p.mlClassification, 'SUSPICIOUS');
    });

    test('status malicious returns MALICIOUS', () {
      final p = makePacket(status: PacketStatus.malicious);
      expect(p.mlClassification, 'MALICIOUS');
    });

    test('status unknown returns PENDING', () {
      final p = makePacket(status: PacketStatus.unknown);
      expect(p.mlClassification, 'PENDING');
    });
  });

  test('pending live DTO is not classified as benign', () {
    final packet = Packet.fromJson({
      'id': 'live-1',
      'source_ip': '192.168.0.7',
      'destination_port': 443,
      'protocol': 'TCP',
      'packet_size': 128,
      'ml_prediction': 'Pending',
      'severity': 'Analysis pending',
      'captured_at': '2026-07-20T23:17:52Z',
    });

    expect(packet.status, PacketStatus.unknown);
    expect(packet.mlClassification, 'PENDING');
  });

  group('decisionSeverity', () {
    test('severity HIGH returns HIGH', () {
      final p = makePacket(severity: 'HIGH');
      expect(p.decisionSeverity, 'HIGH');
    });

    test('severity low returns LOW (uppercased)', () {
      final p = makePacket(severity: 'low');
      expect(p.decisionSeverity, 'LOW');
    });

    test('severity medium returns MEDIUM', () {
      final p = makePacket(severity: 'medium');
      expect(p.decisionSeverity, 'MEDIUM');
    });

    test('severity critical returns CRITICAL', () {
      final p = makePacket(severity: 'CRITICAL');
      expect(p.decisionSeverity, 'CRITICAL');
    });

    test('severity info returns INFO', () {
      final p = makePacket(severity: 'info');
      expect(p.decisionSeverity, 'INFO');
    });

    test('null severity returns INFO', () {
      final p = makePacket(severity: null);
      expect(p.decisionSeverity, 'INFO');
    });

    test('empty severity returns INFO', () {
      final p = makePacket(severity: '');
      expect(p.decisionSeverity, 'INFO');
    });
  });

  group('finalRiskScore', () {
    test('threat score 85.5 returns formatted string', () {
      final p = makePacket(threatScore: 85.5);
      expect(p.finalRiskScore, '85.5 / 100');
    });

    test('threat score 0.0 returns 0.0 / 100', () {
      final p = makePacket(threatScore: 0.0);
      expect(p.finalRiskScore, '0.0 / 100');
    });

    test('null threat score returns N/A not 0', () {
      final p = makePacket(threatScore: null);
      expect(p.finalRiskScore, 'N/A');
    });

    test('threat score 100.0 returns 100.0 / 100', () {
      final p = makePacket(threatScore: 100.0);
      expect(p.finalRiskScore, '100.0 / 100');
    });
  });

  group('stableId', () {
    test('uses id when non-empty', () {
      final p = makePacket();
      expect(p.stableId, 'test-1');
    });

    test('generates composite id when id is empty', () {
      final p = Packet(
        id: '',
        ip: '10.0.0.1',
        port: 443,
        protocol: 'HTTPS',
        size: '64 B',
        status: PacketStatus.benign,
        timestamp: '14:30:00',
      );
      expect(p.stableId, '14:30:00-10.0.0.1-443-HTTPS');
    });
  });
}
