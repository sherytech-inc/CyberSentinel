class CaptureSessionSummary {
  const CaptureSessionSummary({
    required this.sessionId,
    required this.status,
    required this.captureMode,
    required this.captured,
    required this.analyzed,
    required this.pending,
    required this.complete,
    required this.partial,
    required this.failed,
    required this.deferred,
    required this.notAnalyzed,
    required this.normal,
    required this.suspicious,
    required this.malicious,
    required this.unknown,
    this.interfaceName,
    this.startedAt,
    this.stoppedAt,
    this.lastReliableScore,
    this.highestSeverity,
  });

  final String sessionId;
  final String status;
  final String captureMode;
  final String? interfaceName;
  final DateTime? startedAt;
  final DateTime? stoppedAt;
  final int captured;
  final int analyzed;
  final int pending;
  final int complete;
  final int partial;
  final int failed;
  final int deferred;
  final int notAnalyzed;
  final int normal;
  final int suspicious;
  final int malicious;
  final int unknown;
  final double? lastReliableScore;
  final String? highestSeverity;

  double get analysisCompletion => captured == 0 ? 0 : analyzed / captured;

  factory CaptureSessionSummary.fromJson(Map<String, dynamic> json) =>
      CaptureSessionSummary(
        sessionId: json['session_id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'stopped',
        captureMode: json['capture_mode']?.toString() ?? 'live',
        interfaceName: json['interface']?.toString(),
        startedAt: DateTime.tryParse(json['started_at']?.toString() ?? ''),
        stoppedAt: DateTime.tryParse(json['stopped_at']?.toString() ?? ''),
        captured: (json['captured_count'] as num?)?.toInt() ?? 0,
        analyzed: (json['analyzed_count'] as num?)?.toInt() ?? 0,
        pending: (json['pending_count'] as num?)?.toInt() ?? 0,
        complete: (json['complete_count'] as num?)?.toInt() ?? 0,
        partial: (json['partial_count'] as num?)?.toInt() ?? 0,
        failed: (json['failed_count'] as num?)?.toInt() ?? 0,
        deferred: (json['deferred_count'] as num?)?.toInt() ?? 0,
        notAnalyzed: (json['not_analyzed_count'] as num?)?.toInt() ?? 0,
        normal: (json['normal_count'] as num?)?.toInt() ?? 0,
        suspicious: (json['suspicious_count'] as num?)?.toInt() ?? 0,
        malicious: (json['malicious_count'] as num?)?.toInt() ?? 0,
        unknown: (json['unknown_count'] as num?)?.toInt() ?? 0,
        lastReliableScore: (json['last_reliable_score'] as num?)?.toDouble(),
        highestSeverity: json['highest_severity']?.toString(),
      );
}
