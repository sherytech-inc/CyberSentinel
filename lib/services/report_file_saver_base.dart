import 'dart:typed_data';

enum ReportSaveStatus { saved, cancelled }

class ReportSaveResult {
  final ReportSaveStatus status;
  final String? location;

  const ReportSaveResult.saved(this.location) : status = ReportSaveStatus.saved;
  const ReportSaveResult.cancelled()
      : status = ReportSaveStatus.cancelled,
        location = null;
}

abstract class ReportFileSaver {
  Future<ReportSaveResult> save({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  });
}
