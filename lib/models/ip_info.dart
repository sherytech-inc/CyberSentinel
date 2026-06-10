class IPInfo {
  final String ip;
  final String location;
  final String country;
  final String isp;
  final int reputation;
  final ThreatLevel threatLevel;

  IPInfo({
    required this.ip,
    required this.location,
    required this.country,
    required this.isp,
    required this.reputation,
    required this.threatLevel,
  });
}

enum ThreatLevel {
  clean,
  suspicious,
  malicious,
}
