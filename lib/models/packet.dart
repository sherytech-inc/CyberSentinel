import '../utils/date_parser.dart';

class Packet {
  final String id;
  final String ip;
  final int port;
  final String protocol;
  final String size;
  final PacketStatus status;
  final String timestamp;
  final DateTime? capturedAt;
  // Extended fields from backend
  final double? mlConfidence;
  final double? anomalyScore;
  final double? threatScore;
  final String? severity;
  final Map<String, dynamic>? flowFeatures;

  String get stableId => id.isNotEmpty ? id : '$timestamp-$ip-$port-$protocol';

  String get mlClassification {
    switch (status) {
      case PacketStatus.benign:
        return 'BENIGN';
      case PacketStatus.suspicious:
        return 'SUSPICIOUS';
      case PacketStatus.malicious:
        return 'MALICIOUS';
    }
  }

  String get decisionSeverity {
    if (severity == null || severity!.isEmpty) return 'INFO';
    return severity!.toUpperCase();
  }

  String get finalRiskScore {
    if (threatScore == null) return 'N/A';
    return '${threatScore!.toStringAsFixed(1)} / 100';
  }

  Packet({
    required this.id,
    required this.ip,
    required this.port,
    required this.protocol,
    required this.size,
    required this.status,
    required this.timestamp,
    this.capturedAt,
    this.mlConfidence,
    this.anomalyScore,
    this.threatScore,
    this.severity,
    this.flowFeatures,
  });

  /// Construct a Packet from the backend JSON response.
  factory Packet.fromJson(Map<String, dynamic> json) {
    // Map backend ml_prediction string to PacketStatus enum
    final prediction = (json['ml_prediction'] as String? ?? 'Normal').toLowerCase();
    PacketStatus status;
    switch (prediction) {
      case 'malicious':
        status = PacketStatus.malicious;
        break;
      case 'suspicious':
        status = PacketStatus.suspicious;
        break;
      default:
        status = PacketStatus.benign;
    }

    // Format packet size for display
    final sizeBytes = (json['packet_size'] as num?)?.toInt() ?? 0;
    String sizeStr;
    if (sizeBytes >= 1024) {
      sizeStr = '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      sizeStr = '$sizeBytes B';
    }

    // Format timestamp for display
    String timestamp;
    DateTime? capturedAt;
    if (json['captured_at'] != null) {
      capturedAt = DateParser.safeParse(json['captured_at']);
      if (capturedAt != null) {
        timestamp = '${capturedAt.hour.toString().padLeft(2, '0')}:${capturedAt.minute.toString().padLeft(2, '0')}:${capturedAt.second.toString().padLeft(2, '0')}';
      } else {
        timestamp = 'Unknown time';
      }
    } else {
      timestamp = 'Unknown time';
    }

    return Packet(
      id: json['id']?.toString() ?? '',
      ip: json['source_ip']?.toString() ?? '',
      port: (json['destination_port'] as num?)?.toInt() ?? 0,
      protocol: _parseProtocol(json['protocol']),
      size: sizeStr,
      status: status,
      timestamp: timestamp,
      capturedAt: capturedAt,
      mlConfidence: (json['ml_confidence'] as num?)?.toDouble(),
      anomalyScore: (json['anomaly_score'] as num?)?.toDouble(),
      threatScore: (json['threat_score'] as num?)?.toDouble(),
      severity: json['severity']?.toString(),
      flowFeatures: json['flow_features'] != null
          ? Map<String, dynamic>.from(json['flow_features'] as Map)
          : null,
    );
  }

  static String _parseProtocol(dynamic raw) {
    if (raw == null) return 'TCP';
    if (raw is int) {
      if (raw == 6) return 'TCP';
      if (raw == 17) return 'UDP';
      if (raw == 1) return 'ICMP';
      return 'PROTO-$raw';
    }
    return raw.toString().toUpperCase();
  }
}

enum PacketStatus {
  benign,
  suspicious,
  malicious,
}
