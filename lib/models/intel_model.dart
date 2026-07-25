enum IntelStatus {
  completed,
  partial,
  notConfigured,
  notFound,
  quotaExceeded,
  unavailable,
  invalidTarget,
  failed;

  static IntelStatus fromString(String value) {
    switch (value) {
      case 'completed':
        return IntelStatus.completed;
      case 'partial':
        return IntelStatus.partial;
      case 'not_configured':
        return IntelStatus.notConfigured;
      case 'not_found':
        return IntelStatus.notFound;
      case 'quota_exceeded':
        return IntelStatus.quotaExceeded;
      case 'invalid_target':
        return IntelStatus.invalidTarget;
      case 'failed':
        return IntelStatus.failed;
      default:
        return IntelStatus.unavailable;
    }
  }
}

enum IntelProviderStatus {
  completed,
  notConfigured,
  notFound,
  quotaExceeded,
  unavailable;

  static IntelProviderStatus fromString(String value) {
    switch (value) {
      case 'completed':
        return IntelProviderStatus.completed;
      case 'not_configured':
        return IntelProviderStatus.notConfigured;
      case 'not_found':
        return IntelProviderStatus.notFound;
      case 'quota_exceeded':
        return IntelProviderStatus.quotaExceeded;
      default:
        return IntelProviderStatus.unavailable;
    }
  }
}

class VirusTotalIntelResult {
  final IntelProviderStatus status;
  final String? message;
  final int? malicious;
  final int? suspicious;
  final int? harmless;
  final int? undetected;
  final int? totalEngines;
  final String? lastAnalysisDate;

  VirusTotalIntelResult({
    required this.status,
    this.message,
    this.malicious,
    this.suspicious,
    this.harmless,
    this.undetected,
    this.totalEngines,
    this.lastAnalysisDate,
  });

  factory VirusTotalIntelResult.fromJson(Map<String, dynamic> json) {
    return VirusTotalIntelResult(
      status: IntelProviderStatus.fromString(json['status'] ?? 'unavailable'),
      message: json['message'] is String ? json['message'] as String : null,
      malicious: (json['malicious'] as num?)?.toInt(),
      suspicious: (json['suspicious'] as num?)?.toInt(),
      harmless: (json['harmless'] as num?)?.toInt(),
      undetected: (json['undetected'] as num?)?.toInt(),
      totalEngines: (json['total_engines'] as num?)?.toInt(),
      lastAnalysisDate: json['last_analysis_date']?.toString(),
    );
  }
}

class AbuseIpDbIntelResult {
  final IntelProviderStatus status;
  final String? message;
  final int? abuseConfidenceScore;
  final int? totalReports;
  final int? numDistinctUsers;
  final bool? isWhitelisted;
  final bool? isTor;

  AbuseIpDbIntelResult({
    required this.status,
    this.message,
    this.abuseConfidenceScore,
    this.totalReports,
    this.numDistinctUsers,
    this.isWhitelisted,
    this.isTor,
  });

  factory AbuseIpDbIntelResult.fromJson(Map<String, dynamic> json) {
    return AbuseIpDbIntelResult(
      status: IntelProviderStatus.fromString(json['status'] ?? 'unavailable'),
      message: json['message'] is String ? json['message'] as String : null,
      abuseConfidenceScore: (json['abuse_confidence_score'] as num?)?.toInt(),
      totalReports: (json['total_reports'] as num?)?.toInt(),
      numDistinctUsers: (json['num_distinct_users'] as num?)?.toInt(),
      isWhitelisted: json['is_whitelisted'] as bool?,
      isTor: json['is_tor'] as bool?,
    );
  }
}

class GeoIpIntelResult {
  final IntelProviderStatus status;
  final String? message;
  final String? country;
  final String? countryCode;
  final String? city;
  final String? asn;
  final String? organization;
  final String? isp;
  final bool? isProxy;
  final bool? isHosting;

  GeoIpIntelResult({
    required this.status,
    this.message,
    this.country,
    this.countryCode,
    this.city,
    this.asn,
    this.organization,
    this.isp,
    this.isProxy,
    this.isHosting,
  });

  factory GeoIpIntelResult.fromJson(Map<String, dynamic> json) {
    return GeoIpIntelResult(
      status: IntelProviderStatus.fromString(json['status'] ?? 'unavailable'),
      message: json['message'] is String ? json['message'] as String : null,
      country: json['country']?.toString(),
      countryCode: json['country_code']?.toString(),
      city: json['city']?.toString(),
      asn: json['asn']?.toString(),
      organization: json['organization']?.toString(),
      isp: json['isp']?.toString(),
      isProxy: json['is_proxy'] as bool?,
      isHosting: json['is_hosting'] as bool?,
    );
  }
}

class IntelligenceResponse {
  final String ip;
  final IntelStatus status;
  final int? intelScore;
  final String? severity;
  final String? scoreConfidence;
  final List<String> providersUsed;
  final VirusTotalIntelResult virustotal;
  final AbuseIpDbIntelResult abuseipdb;
  final GeoIpIntelResult geoip;
  final String message;
  final String lookedUpAt;
  final bool cached;

  IntelligenceResponse({
    required this.ip,
    required this.status,
    this.intelScore,
    this.severity,
    this.scoreConfidence,
    required this.providersUsed,
    required this.virustotal,
    required this.abuseipdb,
    required this.geoip,
    required this.message,
    required this.lookedUpAt,
    required this.cached,
  });

  factory IntelligenceResponse.fromJson(Map<String, dynamic> json) {
    return IntelligenceResponse(
      ip: json['ip'] as String? ?? '0.0.0.0',
      status: IntelStatus.fromString(json['status'] ?? 'unavailable'),
      intelScore: (json['intel_score'] as num?)?.toInt(),
      severity: json['severity']?.toString(),
      scoreConfidence: json['score_confidence']?.toString(),
      providersUsed: (json['providers_used'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      virustotal: VirusTotalIntelResult.fromJson(json['virustotal'] is Map
          ? Map<String, dynamic>.from(json['virustotal'])
          : {}),
      abuseipdb: AbuseIpDbIntelResult.fromJson(json['abuseipdb'] is Map
          ? Map<String, dynamic>.from(json['abuseipdb'])
          : {}),
      geoip: GeoIpIntelResult.fromJson(
          json['geoip'] is Map ? Map<String, dynamic>.from(json['geoip']) : {}),
      message: json['message'] is String ? json['message'] as String : '',
      lookedUpAt: json['looked_up_at']?.toString() ?? '',
      cached: json['cached'] as bool? ?? false,
    );
  }
}
