class ResponseAction {
  final String id;
  final String ip;
  final String action;
  final String? reason;
  final String source;
  final DateTime createdAt;
  final String? analystName;
  final String status;
  final bool recorded;
  final bool? enforced;
  final String? note;
  final String? message;
  final String? relatedAlert;

  ResponseAction({
    required this.id,
    required this.ip,
    required this.action,
    this.reason,
    required this.source,
    required this.createdAt,
    this.analystName,
    this.status = 'RECORDED',
    this.recorded = true,
    this.enforced,
    this.note,
    this.message,
    this.relatedAlert,
  });

  factory ResponseAction.fromJson(Map<String, dynamic> json) {
    return ResponseAction(
      id: json['id'] as String? ?? '',
      ip: json['ip'] as String? ?? '',
      action: json['action'] as String? ?? '',
      reason: json['reason'] as String?,
      source: json['source'] as String? ?? 'USER',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      analystName: json['analyst_name'] as String?,
      status: json['status'] as String? ?? 'RECORDED',
      recorded: json['recorded'] as bool? ?? true,
      enforced: json['enforced'] as bool?,
      note: json['note'] as String?,
      message: json['message'] as String?,
      relatedAlert: json['related_alert'] as String?,
    );
  }
}
