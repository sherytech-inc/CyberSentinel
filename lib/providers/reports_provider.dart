import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api/clients/local_agent_client.dart';
import '../models/report_summary.dart';
import '../services/report_file_saver.dart';
import '../services/websocket_service.dart';
import 'session_cleanup_coordinator.dart';

enum ReportLoadState { idle, loading, data, partial, error }

enum ReportExportKind {
  pdf('pdf'),
  json('json'),
  alertsCsv('alerts_csv'),
  actionsCsv('actions_csv');

  final String wireName;
  const ReportExportKind(this.wireName);
}

enum ReportExportStatus { saved, cancelled, failed, busy }

class ReportExportOutcome {
  final ReportExportStatus status;
  final String message;

  const ReportExportOutcome(this.status, this.message);
}

typedef ReportSummaryLoader = Future<Map<String, dynamic>> Function();
typedef ReportExportLoader = Future<AuthenticatedDownload> Function(
  String type,
);

class ReportsProvider extends ChangeNotifier {
  final ReportSummaryLoader _summaryLoader;
  final ReportExportLoader _exportLoader;
  final ReportFileSaver _fileSaver;
  final WebSocketService _wsService;
  StreamSubscription? _statsSubscription;

  ReportLoadState _state = ReportLoadState.idle;
  ReportLoadState get state => _state;
  bool get isLoading => _state == ReportLoadState.loading;
  bool get isRefreshing => _refreshFuture != null && _summary != null;

  ReportSummary? _summary;
  ReportSummary? get summary => _summary;

  String? _error;
  String? get error => _error;

  Future<void>? _refreshFuture;
  final Set<ReportExportKind> _activeExports = {};

  ReportsProvider({
    ReportSummaryLoader? summaryLoader,
    ReportExportLoader? exportLoader,
    ReportFileSaver? fileSaver,
    WebSocketService? webSocketService,
    bool listenToWebSocket = true,
  })  : _summaryLoader = summaryLoader ?? LocalAgentClient.getReportSummary,
        _exportLoader = exportLoader ?? LocalAgentClient.downloadReport,
        _fileSaver = fileSaver ?? createReportFileSaver(),
        _wsService = webSocketService ?? WebSocketService() {
    SessionCleanupCoordinator.registerCleanupTask(clear);
    if (listenToWebSocket) {
      _statsSubscription = _wsService.statsUpdateStream.listen((_) {
        if (_summary != null) {
          refresh(silent: true);
        }
      });
    }
  }

  bool isExporting(ReportExportKind kind) => _activeExports.contains(kind);

  Future<void> refresh({bool silent = false}) {
    final active = _refreshFuture;
    if (active != null) return active;

    final operation = _loadSummary(silent: silent);
    _refreshFuture = operation;
    if (_summary != null) {
      notifyListeners();
    }
    return operation.whenComplete(() {
      if (identical(_refreshFuture, operation)) {
        _refreshFuture = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadSummary({required bool silent}) async {
    if (!silent && _summary == null) {
      _state = ReportLoadState.loading;
      _error = null;
      notifyListeners();
    }

    try {
      final data = await _summaryLoader();
      if (data['error'] == true) {
        _handleLoadFailure(data);
        return;
      }
      final nextSummary = ReportSummary.fromJson(data);
      _summary = nextSummary;
      _error = null;
      _state = nextSummary.hasPartialSources
          ? ReportLoadState.partial
          : ReportLoadState.data;
    } on FormatException {
      _setSafeLoadError('Report data is temporarily unavailable.');
    } catch (_) {
      _setSafeLoadError('Report data is temporarily unavailable.');
    } finally {
      notifyListeners();
    }
  }

  void _handleLoadFailure(Map<String, dynamic> data) {
    final statusCode = data['status_code'] as int?;
    if (statusCode == 401 || statusCode == 403) {
      _setSafeLoadError('You are not authorized to view reports.');
    } else if (statusCode == 404) {
      _setSafeLoadError('No report data is available yet.');
    } else {
      _setSafeLoadError('Report data is temporarily unavailable.');
    }
  }

  void _setSafeLoadError(String message) {
    _error = message;
    _state = _summary == null ? ReportLoadState.error : ReportLoadState.partial;
  }

  Future<ReportExportOutcome> export(ReportExportKind kind) async {
    if (_activeExports.contains(kind)) {
      return const ReportExportOutcome(
        ReportExportStatus.busy,
        'This export is already in progress.',
      );
    }
    _activeExports.add(kind);
    notifyListeners();

    try {
      final download = await _exportLoader(kind.wireName);
      final result = await _fileSaver.save(
        bytes: download.bytes,
        filename: download.filename,
        contentType: download.contentType,
      );
      if (result.status == ReportSaveStatus.cancelled) {
        return const ReportExportOutcome(
          ReportExportStatus.cancelled,
          'Export was cancelled.',
        );
      }
      final location = result.location;
      return ReportExportOutcome(
        ReportExportStatus.saved,
        location == null || location.isEmpty
            ? '${download.filename} was saved.'
            : '${download.filename} was saved to $location.',
      );
    } on ReportDownloadException catch (error) {
      return ReportExportOutcome(
        ReportExportStatus.failed,
        _downloadErrorMessage(error.code),
      );
    } catch (_) {
      return const ReportExportOutcome(
        ReportExportStatus.failed,
        'The file could not be saved.',
      );
    } finally {
      _activeExports.remove(kind);
      notifyListeners();
    }
  }

  String _downloadErrorMessage(String code) {
    switch (code) {
      case 'timeout':
        return 'Export timed out.';
      case 'not_authorized':
        return 'You are not authorized to export reports.';
      case 'empty_export':
        return 'No report data is available yet.';
      default:
        return 'Report service is temporarily unavailable.';
    }
  }

  void clear() {
    _summary = null;
    _error = null;
    _state = ReportLoadState.idle;
    _activeExports.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    super.dispose();
  }
}
