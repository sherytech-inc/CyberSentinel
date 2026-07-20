class IntegrationStatus {
  final String provider;
  final bool configured;
  final String state;
  final String? maskedHint;
  final String message;
  final DateTime? lastCheckedAt;

  IntegrationStatus({
    required this.provider,
    required this.configured,
    required this.state,
    this.maskedHint,
    required this.message,
    this.lastCheckedAt,
  });

  factory IntegrationStatus.fromJson(Map<String, dynamic> json) {
    return IntegrationStatus(
      provider: json['provider'] as String,
      configured: json['configured'] as bool,
      state: json['state'] as String,
      maskedHint: json['masked_hint'] as String?,
      message: json['message'] as String,
      lastCheckedAt: json['last_checked_at'] != null
          ? DateTime.parse(json['last_checked_at'] as String)
          : null,
    );
  }
}

class IntegrationsResponse {
  final IntegrationStatus virustotal;
  final IntegrationStatus abuseipdb;
  final IntegrationStatus groq;

  IntegrationsResponse({
    required this.virustotal,
    required this.abuseipdb,
    required this.groq,
  });

  factory IntegrationsResponse.fromJson(Map<String, dynamic> json) {
    return IntegrationsResponse(
      virustotal: json['virustotal'] != null 
          ? IntegrationStatus.fromJson(json['virustotal'] as Map<String, dynamic>)
          : _createFallbackStatus('virustotal'),
      abuseipdb: json['abuseipdb'] != null
          ? IntegrationStatus.fromJson(json['abuseipdb'] as Map<String, dynamic>)
          : _createFallbackStatus('abuseipdb'),
      groq: json['groq'] != null
          ? IntegrationStatus.fromJson(json['groq'] as Map<String, dynamic>)
          : _createFallbackStatus('groq'),
    );
  }

  static IntegrationStatus _createFallbackStatus(String provider) {
    return IntegrationStatus(
      provider: provider,
      configured: false,
      state: 'not_configured',
      message: 'Integration status unavailable from backend.',
    );
  }
}

class IntegrationTestResponse {
  final String provider;
  final bool configured;
  final String state;
  final String message;
  final DateTime testedAt;

  IntegrationTestResponse({
    required this.provider,
    required this.configured,
    required this.state,
    required this.message,
    required this.testedAt,
  });

  factory IntegrationTestResponse.fromJson(Map<String, dynamic> json) {
    return IntegrationTestResponse(
      provider: json['provider'] as String,
      configured: json['configured'] as bool,
      state: json['state'] as String,
      message: json['message'] as String,
      testedAt: DateTime.parse(json['tested_at'] as String),
    );
  }
}
