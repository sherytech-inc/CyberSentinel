import '../utils/date_parser.dart';

class FirewallLog {
  final String id;
  final String sourceIp;
  final int? destinationPort;
  final FirewallAction action;
  final DateTime loggedAt;
  final String? ruleName;

  FirewallLog({
    required this.id,
    required this.sourceIp,
    this.destinationPort,
    required this.action,
    required this.loggedAt,
    this.ruleName,
  });

  /// Construct a FirewallLog from the backend JSON response.
  factory FirewallLog.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('source_ip') || json['source_ip'] == null || json['source_ip'] == '') {
      throw FormatException('Missing or empty source_ip in FirewallLog');
    }

    // Map backend action string to FirewallAction enum
    final actionStr = (json['action'] as String? ?? 'ALLOW').toUpperCase();
    final action = actionStr == 'BLOCK' || actionStr == 'DROP'
        ? FirewallAction.blocked
        : FirewallAction.allowed;

    // Parse logged_at reliably
    final dt = DateParser.safeParse(json['logged_at']) ?? DateTime.now();

    return FirewallLog(
      id: json['id']?.toString() ?? '',
      sourceIp: json['source_ip'] as String,
      destinationPort: json['destination_port'] as int?,
      action: action,
      loggedAt: dt,
      ruleName: json['rule_name'] as String?,
    );
  }
}

enum FirewallAction {
  blocked,
  allowed,
}
