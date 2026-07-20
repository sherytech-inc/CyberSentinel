class ResponseAction {
  final String id;
  final String ip;
  final String action;
  final String? reason;
  final String source;
  final DateTime createdAt;
  final String? analystName;
  final bool? enforced;
  final String? note;

  ResponseAction({
    required this.id,
    required this.ip,
    required this.action,
    this.reason,
    required this.source,
    required this.createdAt,
    this.analystName,
    this.enforced,
    this.note,
  });

  factory ResponseAction.fromJson(Map<String, dynamic> json) {
    return ResponseAction(
      id: json['id'] as String? ?? '',
      ip: json['ip'] as String? ?? '',
      action: json['action'] as String? ?? '',
      reason: json['reason'] as String?,
      source: json['source'] as String? ?? 'USER',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      analystName: json['analyst_name'] as String?,
      enforced: json['enforced'] as bool?,
      note: json['note'] as String?,
    );
  }
}
