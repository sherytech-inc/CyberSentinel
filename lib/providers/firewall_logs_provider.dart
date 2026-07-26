import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api/clients/local_agent_client.dart';
import '../models/firewall_log.dart';
import 'session_cleanup_coordinator.dart';

typedef FirewallAnalyzeRequest = Future<Map<String, dynamic>> Function(
    String filename, List<int> bytes);

enum FirewallAnalysisState {
  noFile,
  fileSelected,
  uploading,
  analyzing,
  complete,
  partial,
  unsupportedFormat,
  invalidFile,
  oversized,
  timedOut,
  unavailable,
  unauthorized,
}

class FirewallLogsProvider extends ChangeNotifier {
  FirewallLogsProvider({FirewallAnalyzeRequest? analyzeRequest})
      : _analyzeRequest =
            analyzeRequest ?? LocalAgentClient.analyzeFirewallLogs {
    SessionCleanupCoordinator.registerCleanupTask(clear);
  }

  final FirewallAnalyzeRequest _analyzeRequest;
  FirewallAnalysisState _state = FirewallAnalysisState.noFile;
  String? _filename;
  List<int>? _selectedBytes;
  String? _message;
  FirewallAnalysisResult? _result;
  int _generation = 0;
  bool _disposed = false;

  String? _actionFilter;
  String? _protocolFilter;
  String? _directionFilter;
  String? _parseStatusFilter;
  String _sourceFilter = '';
  String _destinationFilter = '';
  String _portFilter = '';
  List<FirewallLog>? _filteredCache;
  FirewallLog? _selectedEvent;

  FirewallAnalysisState get state => _state;
  String? get filename => _filename;
  String? get message => _message;
  FirewallAnalysisResult? get result => _result;
  FirewallAnalysisSummary? get summary => _result?.summary;
  List<FirewallLog> get logs => _result?.events ?? const [];
  bool get isLoading =>
      _state == FirewallAnalysisState.uploading ||
      _state == FirewallAnalysisState.analyzing;
  bool get canAnalyze => _selectedBytes != null && !isLoading;
  bool get autoFetch => false;
  bool get hasMore => false;
  String? get error => _message;
  String? get actionFilter => _actionFilter;
  String? get protocolFilter => _protocolFilter;
  String? get directionFilter => _directionFilter;
  String? get parseStatusFilter => _parseStatusFilter;
  FirewallLog? get selectedEvent => _selectedEvent;

  int get blockedCount => logs
      .where((event) => {'deny', 'drop', 'reject'}.contains(event.action))
      .length;
  int get allowedCount => logs.where((event) => event.action == 'allow').length;
  List<FirewallLog> get blockedLogs => logs
      .where((event) => {'deny', 'drop', 'reject'}.contains(event.action))
      .take(5)
      .toList(growable: false);

  List<FirewallLog> get filteredLogs {
    final existing = _filteredCache;
    if (existing != null) return existing;
    final port = int.tryParse(_portFilter.trim());
    final source = _sourceFilter.trim().toLowerCase();
    final destination = _destinationFilter.trim().toLowerCase();
    return _filteredCache = logs.where((event) {
      if (_actionFilter != null && event.action != _actionFilter) return false;
      if (_protocolFilter != null &&
          event.protocol?.toLowerCase() != _protocolFilter) {
        return false;
      }
      if (_directionFilter != null && event.direction != _directionFilter) {
        return false;
      }
      if (_parseStatusFilter != null &&
          event.parseStatus != _parseStatusFilter) {
        return false;
      }
      if (source.isNotEmpty &&
          !(event.sourceIp?.toLowerCase().contains(source) ?? false)) {
        return false;
      }
      if (destination.isNotEmpty &&
          !(event.destinationIp?.toLowerCase().contains(destination) ??
              false)) {
        return false;
      }
      if (port != null &&
          event.sourcePort != port &&
          event.destinationPort != port) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  void selectFile(String filename, List<int> bytes) {
    _generation++;
    _filename = filename.split(RegExp(r'[/\\]')).last;
    _selectedBytes = List<int>.unmodifiable(bytes);
    _message = null;
    _result = null;
    _selectedEvent = null;
    _invalidateFilters();
    _state = FirewallAnalysisState.fileSelected;
    notifyListeners();
  }

  Future<void> analyze() async {
    if (!canAnalyze) return;
    final requestGeneration = ++_generation;
    final name = _filename!;
    final bytes = _selectedBytes!;
    _state = FirewallAnalysisState.uploading;
    _message = null;
    notifyListeners();
    if (requestGeneration != _generation) return;
    _state = FirewallAnalysisState.analyzing;
    notifyListeners();

    try {
      final response = await _analyzeRequest(name, bytes);
      if (requestGeneration != _generation || _disposed) return;
      if (response['error'] == true) {
        _applyError(response);
        return;
      }
      final parsed = FirewallAnalysisResult.fromJson(response);
      _result = parsed;
      _state = parsed.status == 'partial'
          ? FirewallAnalysisState.partial
          : FirewallAnalysisState.complete;
      _message = parsed.status == 'partial'
          ? 'Some lines could not be parsed. Valid events are still shown.'
          : null;
      _invalidateFilters();
      notifyListeners();
    } on FormatException {
      if (requestGeneration != _generation || _disposed) return;
      _state = FirewallAnalysisState.unavailable;
      _message = 'The analysis service returned an invalid response.';
      notifyListeners();
    } catch (_) {
      if (requestGeneration != _generation || _disposed) return;
      _state = FirewallAnalysisState.unavailable;
      _message = 'Firewall Log Analysis is temporarily unavailable.';
      notifyListeners();
    }
  }

  void _applyError(Map<String, dynamic> response) {
    final status =
        response['status']?.toString() ?? response['code']?.toString() ?? '';
    final statusCode = response['status_code'];
    if (statusCode == 401 || statusCode == 403) {
      _state = FirewallAnalysisState.unauthorized;
      _message = 'Sign in with an active analyst account to analyze logs.';
    } else if (status == 'unsupported_format') {
      _state = FirewallAnalysisState.unsupportedFormat;
      _message = 'Unsupported or unrecognized firewall log format.';
    } else if (status == 'file_too_large' || statusCode == 413) {
      _state = FirewallAnalysisState.oversized;
      _message = 'The selected file exceeds the 5 MB upload limit.';
    } else if (status == 'invalid_file') {
      _state = FirewallAnalysisState.invalidFile;
      _message =
          response['message']?.toString() ?? 'The selected file is invalid.';
    } else if ((response['message']?.toString() ?? '')
        .toLowerCase()
        .contains('timed out')) {
      _state = FirewallAnalysisState.timedOut;
      _message = 'Firewall log analysis timed out. You can try again.';
    } else {
      _state = FirewallAnalysisState.unavailable;
      _message = 'Firewall Log Analysis is temporarily unavailable.';
    }
    notifyListeners();
  }

  void cancel() {
    _generation++;
    _state = _selectedBytes == null
        ? FirewallAnalysisState.noFile
        : FirewallAnalysisState.fileSelected;
    _message = null;
    notifyListeners();
  }

  void selectEvent(FirewallLog? event) {
    _selectedEvent = event;
    notifyListeners();
  }

  void setFilters({
    String? action,
    String? protocol,
    String? direction,
    String? parseStatus,
    String? source,
    String? destination,
    String? port,
  }) {
    _actionFilter = action;
    _protocolFilter = protocol;
    _directionFilter = direction;
    _parseStatusFilter = parseStatus;
    if (source != null) _sourceFilter = source;
    if (destination != null) _destinationFilter = destination;
    if (port != null) _portFilter = port;
    _filteredCache = null;
    notifyListeners();
  }

  void clearFilters() {
    _actionFilter = null;
    _protocolFilter = null;
    _directionFilter = null;
    _parseStatusFilter = null;
    _sourceFilter = '';
    _destinationFilter = '';
    _portFilter = '';
    _filteredCache = null;
    notifyListeners();
  }

  void _invalidateFilters() => _filteredCache = null;

  // Retained as no-ops for SettingsProvider wiring during this read-only phase.
  void updateRefreshInterval(Duration? _) {}
  void toggleAutoFetch() {}
  Future<void> fetchLogs({bool refresh = false}) async {}

  void clear() {
    _generation++;
    _filename = null;
    _selectedBytes = null;
    _message = null;
    _result = null;
    _selectedEvent = null;
    _actionFilter = null;
    _protocolFilter = null;
    _directionFilter = null;
    _parseStatusFilter = null;
    _sourceFilter = '';
    _destinationFilter = '';
    _portFilter = '';
    _filteredCache = null;
    _state = FirewallAnalysisState.noFile;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
