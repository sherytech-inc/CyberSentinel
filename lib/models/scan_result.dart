class ScanResult {
  final String target;
  final String scanType;
  final ScanStatus status;
  final String verdict;
  final String message;
  final ScanThreatLevel threatLevel;
  final int enginesDetected;
  final int totalEngines;
  final int malicious;
  final int suspicious;
  final int harmless;
  final int undetected;
  final String provider;
  final bool providerContacted;
  final String? analysisId;
  final DateTime? scannedAt;

  ScanResult({
    required this.target,
    required this.scanType,
    required this.status,
    required this.verdict,
    required this.message,
    required this.threatLevel,
    required this.enginesDetected,
    required this.totalEngines,
    required this.malicious,
    required this.suspicious,
    required this.harmless,
    required this.undetected,
    required this.provider,
    required this.providerContacted,
    this.analysisId,
    this.scannedAt,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toLowerCase() ?? 'unavailable';
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
      case 'file_too_large':
        parsedStatus = ScanStatus.fileTooLarge;
        break;
      case 'unsupported_file':
        parsedStatus = ScanStatus.unsupportedFile;
        break;
      default:
        parsedStatus = ScanStatus.unavailable;
    }

    final malicious = (json['malicious'] as num?)?.toInt() ?? 0;
    final suspicious = (json['suspicious'] as num?)?.toInt() ?? 0;
    final harmless = (json['harmless'] as num?)?.toInt() ?? 0;
    final undetected = (json['undetected'] as num?)?.toInt() ?? 0;
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
      verdict: json['verdict']?.toString() ?? 'unknown',
      message: json['message'] is String ? json['message'] as String : '',
      threatLevel: level,
      enginesDetected: malicious + suspicious,
      totalEngines: total,
      malicious: malicious,
      suspicious: suspicious,
      harmless: harmless,
      undetected: undetected,
      provider: json['provider']?.toString() ?? 'VIRUSTOTAL',
      providerContacted: json['provider_contacted'] == true,
      analysisId: json['analysis_id']?.toString(),
      scannedAt: DateTime.tryParse(json['scanned_at']?.toString() ?? ''),
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
  fileTooLarge,
  unsupportedFile,
}

enum ScanThreatLevel {
  clean,
  low,
  medium,
  high,
  critical,
}
