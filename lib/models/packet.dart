class Packet {
  final String id;
  final String ip;
  final int port;
  final String protocol;
  final String size;
  final PacketStatus status;
  final String timestamp;

  Packet({
    required this.id,
    required this.ip,
    required this.port,
    required this.protocol,
    required this.size,
    required this.status,
    required this.timestamp,
  });
}

enum PacketStatus {
  normal,
  suspicious,
  malicious,
}
