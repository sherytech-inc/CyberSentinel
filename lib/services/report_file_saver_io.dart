import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'report_file_saver_base.dart';

ReportFileSaver createReportFileSaver() => NativeReportFileSaver();

class NativeReportFileSaver implements ReportFileSaver {
  @override
  Future<ReportSaveResult> save({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final extension =
        filename.contains('.') ? filename.split('.').last.toLowerCase() : null;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save CyberSentinel report',
      fileName: filename,
      type: extension == null ? FileType.any : FileType.custom,
      allowedExtensions: extension == null ? null : [extension],
      lockParentWindow: true,
    );
    if (path == null || path.isEmpty) {
      return const ReportSaveResult.cancelled();
    }
    await File(path).writeAsBytes(bytes, flush: true);
    return ReportSaveResult.saved(path);
  }
}
