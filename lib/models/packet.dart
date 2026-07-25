import '../utils/date_parser.dart';

class Packet {
  final String id;
  final String flowId;
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
  final String analysisStatus;
  final String? action;
  final Map<String, dynamic>? modelResults;

  String get stableId => id.isNotEmpty ? id : '$timestamp-$ip-$port-$protocol';

  String get mlClassification {
    if (analysisStatus == 'pending') return 'PENDING';
    if (analysisStatus == 'cancelled' || analysisStatus == 'not_analyzed') {
      return 'NOT ANALYZED';
    }
    if (analysisStatus == 'failed') return 'FAILED';
    if (analysisStatus == 'deferred') return 'DEFERRED';
    if (analysisStatus == 'partial') return 'PARTIAL';
    switch (status) {
      case PacketStatus.benign:
        return 'BENIGN';
      case PacketStatus.suspicious:
        return 'SUSPICIOUS';
      case PacketStatus.malicious:
        return 'MALICIOUS';
      case PacketStatus.unknown:
        return 'UNKNOWN';
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
    this.flowId = '',
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
    this.analysisStatus = 'pending',
    this.action,
    this.modelResults,
  });

  /// Construct a Packet from the backend JSON response.
  factory Packet.fromJson(Map<String, dynamic> json) {
    // Map backend ml_prediction string to PacketStatus enum
    final prediction =
        (json['ml_prediction'] as String? ?? 'Normal').toLowerCase();
    PacketStatus status;
    switch (prediction) {
      case 'normal':
      case 'benign':
      case 'safe':
        status = PacketStatus.benign;
        break;
      case 'malicious':
        status = PacketStatus.malicious;
        break;
      case 'suspicious':
        status = PacketStatus.suspicious;
        break;
      case 'pending':
      case 'unknown':
      case 'unavailable':
        status = PacketStatus.unknown;
        break;
      default:
        status = PacketStatus.unknown;
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
        timestamp =
            '${capturedAt.hour.toString().padLeft(2, '0')}:${capturedAt.minute.toString().padLeft(2, '0')}:${capturedAt.second.toString().padLeft(2, '0')}';
      } else {
        timestamp = 'Unknown time';
      }
    } else {
      timestamp = 'Unknown time';
    }

    return Packet(
      id: json['packet_id']?.toString() ?? json['id']?.toString() ?? '',
      flowId: json['flow_id']?.toString() ?? '',
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
      analysisStatus: json['analysis_status']?.toString() ?? 'pending',
      action: json['action']?.toString(),
      modelResults: json['model_results'] is Map
          ? Map<String, dynamic>.from(json['model_results'] as Map)
          : null,
    );
  }

  Packet withAnalysis(Map<String, dynamic> update) {
    final merged = <String, dynamic>{
      'id': id,
      'packet_id': id,
      'flow_id': flowId,
      'source_ip': ip,
      'destination_port': port,
      'protocol': protocol,
      'packet_size': _sizeBytes,
      'captured_at': capturedAt?.toIso8601String(),
      'ml_prediction': update['ml_prediction'] ?? mlClassification,
      'ml_confidence': update['ml_confidence'] ?? mlConfidence,
      'anomaly_score': update['anomaly_score'] ?? anomalyScore,
      'threat_score': update['threat_score'] ?? threatScore,
      'severity': update['severity'] ?? severity,
      'analysis_status': update['analysis_status'] ?? analysisStatus,
      'action': update['action'] ?? action,
      'model_results': update['model_results'] ?? modelResults,
      'flow_features': flowFeatures,
    };
    return Packet.fromJson(merged);
  }

  int get _sizeBytes {
    final value = double.tryParse(size.split(' ').first) ?? 0;
    return size.toUpperCase().endsWith('KB')
        ? (value * 1024).round()
        : value.round();
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
  unknown,
}
