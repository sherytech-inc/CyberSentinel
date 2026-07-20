class GlobalSecurityMetrics {
  final int activeThreats;
  final int criticalThreats;
  final int blockedIps;
  final int responseActions;
  final int totalPackets;
  final int suspiciousIps;
  final int threatScore;

  GlobalSecurityMetrics({
    this.activeThreats = 0,
    this.criticalThreats = 0,
    this.blockedIps = 0,
    this.responseActions = 0,
    this.totalPackets = 0,
    this.suspiciousIps = 0,
    this.threatScore = 0,
  });

  factory GlobalSecurityMetrics.empty() {
    return GlobalSecurityMetrics();
  }

  factory GlobalSecurityMetrics.fromApi({
    required Map<String, dynamic> dashboardStats,
  }) {
    final snapshot = dashboardStats['snapshot'] as Map<String, dynamic>? ?? {};
    final period = dashboardStats['period'] as Map<String, dynamic>? ?? {};
    
    return GlobalSecurityMetrics(
      activeThreats: snapshot['active_threats'] ?? 0,
      criticalThreats: period['critical_threats'] ?? 0,
      blockedIps: snapshot['currently_blocked_ips'] ?? 0,
      responseActions: period['response_actions'] ?? 0,
      totalPackets: dashboardStats['total_packets_count'] ?? 0,
      suspiciousIps: dashboardStats['suspicious_ips_count'] ?? 0,
      threatScore: dashboardStats['threat_score'] ?? 0,
    );
  }

  GlobalSecurityMetrics copyWith({
    int? activeThreats,
    int? criticalThreats,
    int? blockedIps,
    int? responseActions,
    int? totalPackets,
    int? suspiciousIps,
    int? threatScore,
  }) {
    return GlobalSecurityMetrics(
      activeThreats: activeThreats ?? this.activeThreats,
      criticalThreats: criticalThreats ?? this.criticalThreats,
      blockedIps: blockedIps ?? this.blockedIps,
      responseActions: responseActions ?? this.responseActions,
      totalPackets: totalPackets ?? this.totalPackets,
      suspiciousIps: suspiciousIps ?? this.suspiciousIps,
      threatScore: threatScore ?? this.threatScore,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GlobalSecurityMetrics &&
            activeThreats == other.activeThreats &&
            criticalThreats == other.criticalThreats &&
            blockedIps == other.blockedIps &&
            responseActions == other.responseActions &&
            totalPackets == other.totalPackets &&
            suspiciousIps == other.suspiciousIps &&
            threatScore == other.threatScore;
  }

  @override
  int get hashCode => Object.hash(
        activeThreats,
        criticalThreats,
        blockedIps,
        responseActions,
        totalPackets,
        suspiciousIps,
        threatScore,
      );
}
