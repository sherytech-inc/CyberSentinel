class ScanResult {
  final String target;
  final String scanType;
  final ScanStatus status;
  final String message;
  final ScanThreatLevel threatLevel;
  final int enginesDetected;
  final int totalEngines;

  ScanResult({
    required this.target,
    required this.scanType,
    required this.status,
    required this.message,
    required this.threatLevel,
    required this.enginesDetected,
    required this.totalEngines,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'unavailable').toLowerCase();
    ScanStatus parsedStatus;
    switch (statusStr) {
      case 'completed':
        parsedStatus = ScanStatus.completed;
        break;
      case 'pending':
        parsedStatus = ScanStatus.pending;
        break;
      case 'not_found':
        parsedStatus = ScanStatus.notFound;
        break;
      case 'not_configured':
        parsedStatus = ScanStatus.notConfigured;
        break;
      case 'quota_exceeded':
        parsedStatus = ScanStatus.quotaExceeded;
        break;
      case 'invalid_target':
        parsedStatus = ScanStatus.invalidTarget;
        break;
      default:
        parsedStatus = ScanStatus.unavailable;
    }

    final malicious = json['malicious'] as int? ?? 0;
    final suspicious = json['suspicious'] as int? ?? 0;
    final harmless = json['harmless'] as int? ?? 0;
    final undetected = json['undetected'] as int? ?? 0;
    final total = malicious + suspicious + harmless + undetected;

    ScanThreatLevel level = ScanThreatLevel.clean;
    if (parsedStatus == ScanStatus.completed) {
      if (malicious >= 5) {
        level = ScanThreatLevel.critical;
      } else if (malicious > 0) {
        level = ScanThreatLevel.high;
      } else if (suspicious > 0) {
        level = ScanThreatLevel.medium;
      } else if (total == 0) {
        level = ScanThreatLevel.low; // No engines scanned
      }
    }

    return ScanResult(
      target: json['target'] as String? ?? 'Unknown',
      scanType: json['scan_type'] as String? ?? 'url',
      status: parsedStatus,
      message: json['message'] as String? ?? '',
      threatLevel: level,
      enginesDetected: malicious + suspicious,
      totalEngines: total,
    );
  }
}

enum ScanStatus {
  completed,
  pending,
  notFound,
  notConfigured,
  quotaExceeded,
  unavailable,
  invalidTarget,
}

enum ScanThreatLevel {
  clean,
  low,
  medium,
  high,
  critical,
}
