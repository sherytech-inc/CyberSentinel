import 'dart:typed_data';

import 'report_file_saver_base.dart';

ReportFileSaver createReportFileSaver() => _UnsupportedReportFileSaver();

class _UnsupportedReportFileSaver implements ReportFileSaver {
  @override
  Future<ReportSaveResult> save({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) {
    throw UnsupportedError('Report file saving is unavailable.');
  }
}
