class ReportSessionSummary {
  final int captured;
  final int analyzed;
  final int pending;
  final int complete;
  final int partial;
  final int failed;
  final int deferred;
  final int notAnalyzed;
  final double completionPercentage;
  final double? threatScore;
  final String? highestSeverity;

  const ReportSessionSummary({
    required this.captured,
    required this.analyzed,
    required this.pending,
    required this.complete,
    required this.partial,
    required this.failed,
    required this.deferred,
    required this.notAnalyzed,
    required this.completionPercentage,
    required this.threatScore,
    required this.highestSeverity,
  });

  factory ReportSessionSummary.fromJson(Map<String, dynamic> json) {
    return ReportSessionSummary(
      captured: _int(json['captured']),
      analyzed: _int(json['analyzed']),
      pending: _int(json['pending']),
      complete: _int(json['complete']),
      partial: _int(json['partial']),
      failed: _int(json['failed']),
      deferred: _int(json['deferred']),
      notAnalyzed: _int(json['not_analyzed']),
      completionPercentage: _double(json['completion_percentage']),
      threatScore: json['threat_score'] is num
          ? (json['threat_score'] as num).toDouble()
          : null,
      highestSeverity: json['highest_severity']?.toString(),
    );
  }
}

class ReportDistribution {
  final Map<String, int> values;

  const ReportDistribution(this.values);

  factory ReportDistribution.fromJson(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    return ReportDistribution({
      for (final key in keys) key: _int(json[key]),
    });
  }

  int operator [](String key) => values[key] ?? 0;
  int get total => values.values.fold(0, (sum, value) => sum + value);
}

class ReportThreatType {
  final String threatType;
  final int count;

  const ReportThreatType({required this.threatType, required this.count});

  factory ReportThreatType.fromJson(Map<String, dynamic> json) {
    return ReportThreatType(
      threatType: json['threat_type']?.toString() ?? 'Unclassified',
      count: _int(json['count']),
    );
  }
}

class ReportAttacker {
  final String sourceIp;
  final int count;
  final String? highestSeverity;
  final String? country;

  const ReportAttacker({
    required this.sourceIp,
    required this.count,
    this.highestSeverity,
    this.country,
  });

  factory ReportAttacker.fromJson(Map<String, dynamic> json) {
    return ReportAttacker(
      sourceIp: json['source_ip']?.toString() ?? 'Unknown',
      count: _int(json['count']),
      highestSeverity: json['highest_severity']?.toString(),
      country: json['country']?.toString(),
    );
  }
}

class ReportAlert {
  final String alertId;
  final String? timestamp;
  final String? sourceIp;
  final String? threatType;
  final String? severity;
  final double? score;
  final String? status;
  final String? action;

  const ReportAlert({
    required this.alertId,
    this.timestamp,
    this.sourceIp,
    this.threatType,
    this.severity,
    this.score,
    this.status,
    this.action,
  });

  factory ReportAlert.fromJson(Map<String, dynamic> json) {
    return ReportAlert(
      alertId: json['alert_id']?.toString() ?? '',
      timestamp: json['timestamp']?.toString(),
      sourceIp: json['source_ip']?.toString(),
      threatType: json['threat_type']?.toString(),
      severity: json['severity']?.toString(),
      score: json['score'] is num ? (json['score'] as num).toDouble() : null,
      status: json['status']?.toString(),
      action: json['action']?.toString(),
    );
  }
}

class ReportResponseAction {
  final String actionId;
  final String? timestamp;
  final String? target;
  final String action;
  final String? status;
  final String? analyst;

  const ReportResponseAction({
    required this.actionId,
    required this.action,
    this.timestamp,
    this.target,
    this.status,
    this.analyst,
  });

  factory ReportResponseAction.fromJson(Map<String, dynamic> json) {
    return ReportResponseAction(
      actionId: json['action_id']?.toString() ?? '',
      timestamp: json['timestamp']?.toString(),
      target: json['target']?.toString(),
      action: json['action']?.toString() ?? 'Unknown',
      status: json['status']?.toString(),
      analyst: json['analyst']?.toString(),
    );
  }
}

class ReportSourceStatus {
  final String capture;
  final String alerts;
  final String actions;
  final String intelligence;

  const ReportSourceStatus({
    required this.capture,
    required this.alerts,
    required this.actions,
    required this.intelligence,
  });

  factory ReportSourceStatus.fromJson(Map<String, dynamic> json) {
    return ReportSourceStatus(
      capture: json['capture']?.toString() ?? 'unavailable',
      alerts: json['alerts']?.toString() ?? 'unavailable',
      actions: json['actions']?.toString() ?? 'unavailable',
      intelligence: json['intelligence']?.toString() ?? 'unavailable',
    );
  }

  bool get hasUnavailable =>
      capture == 'unavailable' ||
      alerts == 'unavailable' ||
      actions == 'unavailable' ||
      intelligence == 'unavailable';
}

class ReportSummary {
  final String generatedAt;
  final String timeframe;
  final String monitoringState;
  final String? interfaceName;
  final ReportSessionSummary session;
  final ReportDistribution classificationDistribution;
  final ReportDistribution severityDistribution;
  final List<ReportThreatType> topThreatTypes;
  final List<ReportAttacker> topAttackers;
  final List<ReportAlert> recentAlerts;
  final List<ReportResponseAction> responseTimeline;
  final Map<String, int?> modelAvailability;
  final ReportSourceStatus sourceStatus;
  final List<String> messages;

  const ReportSummary({
    required this.generatedAt,
    required this.timeframe,
    required this.monitoringState,
    required this.interfaceName,
    required this.session,
    required this.classificationDistribution,
    required this.severityDistribution,
    required this.topThreatTypes,
    required this.topAttackers,
    required this.recentAlerts,
    required this.responseTimeline,
    required this.modelAvailability,
    required this.sourceStatus,
    required this.messages,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      generatedAt: json['generated_at']?.toString() ?? '',
      timeframe: json['timeframe']?.toString() ?? 'unavailable',
      monitoringState: json['monitoring_state']?.toString() ?? 'inactive',
      interfaceName: json['interface']?.toString(),
      session: ReportSessionSummary.fromJson(_map(json['session'])),
      classificationDistribution: ReportDistribution.fromJson(
        _map(json['classification_distribution']),
        const ['normal', 'suspicious', 'malicious', 'unknown'],
      ),
      severityDistribution: ReportDistribution.fromJson(
        _map(json['severity_distribution']),
        const ['low', 'medium', 'high', 'critical', 'unknown'],
      ),
      topThreatTypes: _list(json['top_threat_types'])
          .map((item) => ReportThreatType.fromJson(_map(item)))
          .toList(),
      topAttackers: _list(json['top_attackers'])
          .map((item) => ReportAttacker.fromJson(_map(item)))
          .toList(),
      recentAlerts: _list(json['recent_alerts'])
          .map((item) => ReportAlert.fromJson(_map(item)))
          .toList(),
      responseTimeline: _list(json['response_timeline'])
          .map((item) => ReportResponseAction.fromJson(_map(item)))
          .toList(),
      modelAvailability: {
        for (final entry in _map(json['model_availability']).entries)
          entry.key: entry.value is num ? (entry.value as num).toInt() : null,
      },
      sourceStatus: ReportSourceStatus.fromJson(_map(json['source_status'])),
      messages:
          _list(json['messages']).map((message) => message.toString()).toList(),
    );
  }

  String get timeframeLabel {
    switch (timeframe) {
      case 'current_session':
        return 'Current Session';
      case 'last_session':
        return 'Last Session';
      case 'recent_history':
        return 'Recent Historical Data';
      default:
        return 'No session data available';
    }
  }

  bool get hasPartialSources => sourceStatus.hasUnavailable;
}

int _int(dynamic value) => value is num ? value.toInt() : 0;
double _double(dynamic value) => value is num ? value.toDouble() : 0;
Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<dynamic> _list(dynamic value) => value is List ? value : const <dynamic>[];
