import '../utils/date_parser.dart';

class FirewallActionModel {
  final String id;
  final String ip;
  final String action;
  final String? reason;
  final String source;
  final bool recorded;
  final bool enforced;
  final DateTime createdAt;

  FirewallActionModel({
    required this.id,
    required this.ip,
    required this.action,
    this.reason,
    required this.source,
    required this.recorded,
    required this.enforced,
    required this.createdAt,
  });

  factory FirewallActionModel.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('ip') || json['ip'] == null || json['ip'] == '') {
      throw FormatException('Missing or empty ip in FirewallActionModel');
    }

    final dt = DateParser.safeParse(json['created_at']) ?? DateTime.now();

    return FirewallActionModel(
      id: json['id']?.toString() ?? '',
      ip: json['ip'] as String,
      action: json['action'] as String? ?? 'UNKNOWN',
      reason: json['reason'] as String?,
      source: json['source'] as String? ?? 'UNKNOWN',
      recorded: json['recorded'] as bool? ?? true,
      enforced: json['enforced'] as bool? ?? false,
      createdAt: dt,
    );
  }
}
