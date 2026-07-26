class FirewallLog {
  final String id;
  final DateTime? timestamp;
  final String action;
  final String direction;
  final String? interfaceName;
  final String? protocol;
  final String? sourceIp;
  final String? destinationIp;
  final int? sourcePort;
  final int? destinationPort;
  final int? packetSize;
  final String? flags;
  final String? rule;
  final int rawLineNumber;
  final String parseStatus;
  final List<String> messages;

  const FirewallLog({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.direction,
    required this.interfaceName,
    required this.protocol,
    required this.sourceIp,
    required this.destinationIp,
    required this.sourcePort,
    required this.destinationPort,
    required this.packetSize,
    required this.flags,
    required this.rule,
    required this.rawLineNumber,
    required this.parseStatus,
    required this.messages,
  });

  factory FirewallLog.fromJson(Map<String, dynamic> json) {
    final id = json['event_id']?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('Firewall event identity is missing.');
    }
    int? asInt(Object? value) =>
        value is int ? value : int.tryParse(value?.toString() ?? '');
    final rawMessages = json['messages'];
    return FirewallLog(
      id: id,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? ''),
      action: json['action']?.toString() ?? 'unknown',
      direction: json['direction']?.toString() ?? 'unknown',
      interfaceName: json['interface']?.toString(),
      protocol: json['protocol']?.toString(),
      sourceIp: json['source_ip']?.toString(),
      destinationIp: json['destination_ip']?.toString(),
      sourcePort: asInt(json['source_port']),
      destinationPort: asInt(json['destination_port']),
      packetSize: asInt(json['packet_size']),
      flags: json['flags']?.toString(),
      rule: json['rule']?.toString(),
      rawLineNumber: asInt(json['raw_line_number']) ?? 0,
      parseStatus: json['parse_status']?.toString() ?? 'partial',
      messages: rawMessages is List
          ? rawMessages.map((item) => item.toString()).toList(growable: false)
          : const [],
    );
  }
}

class FirewallCount {
  final String value;
  final int count;

  const FirewallCount(this.value, this.count);

  factory FirewallCount.fromJson(Map<String, dynamic> json) => FirewallCount(
      json['value']?.toString() ?? 'unknown',
      json['count'] is int ? json['count'] as int : 0);
}

class FirewallPortCount {
  final int port;
  final int count;

  const FirewallPortCount(this.port, this.count);

  factory FirewallPortCount.fromJson(Map<String, dynamic> json) =>
      FirewallPortCount(
        json['port'] is int ? json['port'] as int : 0,
        json['count'] is int ? json['count'] as int : 0,
      );
}

class FirewallAnalysisSummary {
  final String detectedFormat;
  final int totalLines;
  final int parsedEvents;
  final int completeEvents;
  final int partialEvents;
  final int failedLines;
  final int allowedCount;
  final int deniedDroppedCount;
  final int inboundCount;
  final int outboundCount;
  final List<FirewallCount> protocolDistribution;
  final List<FirewallCount> topSourceIps;
  final List<FirewallCount> topDestinationIps;
  final List<FirewallPortCount> topDestinationPorts;
  final DateTime? firstTimestamp;
  final DateTime? lastTimestamp;
  final List<String> warnings;

  const FirewallAnalysisSummary({
    required this.detectedFormat,
    required this.totalLines,
    required this.parsedEvents,
    required this.completeEvents,
    required this.partialEvents,
    required this.failedLines,
    required this.allowedCount,
    required this.deniedDroppedCount,
    required this.inboundCount,
    required this.outboundCount,
    required this.protocolDistribution,
    required this.topSourceIps,
    required this.topDestinationIps,
    required this.topDestinationPorts,
    required this.firstTimestamp,
    required this.lastTimestamp,
    required this.warnings,
  });

  factory FirewallAnalysisSummary.fromJson(Map<String, dynamic> json) {
    int number(String key) => json[key] is int ? json[key] as int : 0;
    List<T> parseList<T>(
      String key,
      T Function(Map<String, dynamic>) parser,
    ) {
      final value = json[key];
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map((item) => parser(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    }

    return FirewallAnalysisSummary(
      detectedFormat: json['detected_format']?.toString() ?? 'unknown',
      totalLines: number('total_lines'),
      parsedEvents: number('parsed_events'),
      completeEvents: number('complete_events'),
      partialEvents: number('partial_events'),
      failedLines: number('failed_lines'),
      allowedCount: number('allowed_count'),
      deniedDroppedCount: number('denied_dropped_count'),
      inboundCount: number('inbound_count'),
      outboundCount: number('outbound_count'),
      protocolDistribution:
          parseList('protocol_distribution', FirewallCount.fromJson),
      topSourceIps: parseList('top_source_ips', FirewallCount.fromJson),
      topDestinationIps:
          parseList('top_destination_ips', FirewallCount.fromJson),
      topDestinationPorts:
          parseList('top_destination_ports', FirewallPortCount.fromJson),
      firstTimestamp:
          DateTime.tryParse(json['first_timestamp']?.toString() ?? ''),
      lastTimestamp:
          DateTime.tryParse(json['last_timestamp']?.toString() ?? ''),
      warnings: json['warnings'] is List
          ? (json['warnings'] as List)
              .map((item) => item.toString())
              .toList(growable: false)
          : const [],
    );
  }
}

class FirewallAnalysisResult {
  final String status;
  final String filename;
  final FirewallAnalysisSummary summary;
  final List<FirewallLog> events;
  final bool eventsTruncated;

  const FirewallAnalysisResult({
    required this.status,
    required this.filename,
    required this.summary,
    required this.events,
    required this.eventsTruncated,
  });

  factory FirewallAnalysisResult.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];
    final events = json['events'];
    if (summary is! Map || events is! List) {
      throw const FormatException('Firewall analysis response is incomplete.');
    }
    return FirewallAnalysisResult(
      status: json['status']?.toString() ?? 'partial',
      filename: json['filename']?.toString() ?? 'firewall-log.txt',
      summary:
          FirewallAnalysisSummary.fromJson(Map<String, dynamic>.from(summary)),
      events: events
          .whereType<Map>()
          .map((item) => FirewallLog.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      eventsTruncated: json['events_truncated'] == true,
    );
  }
}
