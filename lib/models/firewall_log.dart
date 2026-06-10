class FirewallLog {
  final String id;
  final String ip;
  final int port;
  final FirewallAction action;
  final String timestamp;
  final String rule;

  FirewallLog({
    required this.id,
    required this.ip,
    required this.port,
    required this.action,
    required this.timestamp,
    required this.rule,
  });
}

enum FirewallAction {
  blocked,
  allowed,
}
