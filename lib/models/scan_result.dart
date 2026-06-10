class ScanResult {
  final String fileName;
  final ScanThreatLevel threatLevel;
  final int enginesDetected;
  final int totalEngines;
  final List<String> detections;

  ScanResult({
    required this.fileName,
    required this.threatLevel,
    required this.enginesDetected,
    required this.totalEngines,
    required this.detections,
  });
}

enum ScanThreatLevel {
  clean,
  low,
  medium,
  high,
  critical,
}
