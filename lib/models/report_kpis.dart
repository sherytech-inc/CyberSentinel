class ReportKpis {
  final int totalThreats;
  final int criticalThreats;
  final int responseActions;
  final int recordedBlocks;
  final int osEnforcedBlocks;

  ReportKpis({
    required this.totalThreats,
    required this.criticalThreats,
    required this.responseActions,
    required this.recordedBlocks,
    required this.osEnforcedBlocks,
  });

  factory ReportKpis.fromJson(Map<String, dynamic> json) {
    return ReportKpis(
      totalThreats: json['total_threats'] ?? 0,
      criticalThreats: json['critical_threats'] ?? 0,
      responseActions: json['response_actions'] ?? 0,
      recordedBlocks: json['recorded_blocks'] ?? json['block_actions'] ?? 0,
      osEnforcedBlocks: json['os_enforced_blocks'] ?? 0,
    );
  }
}
