import 'dart:typed_data';

import 'package:cybersentinel/services/report_file_saver_base.dart';
import 'package:cybersentinel/services/report_file_saver_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

class _CancelledFilePicker extends FilePicker {
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    return null;
  }
}

void main() {
  test('native save-dialog cancellation is not a failure', () async {
    FilePicker.platform = _CancelledFilePicker();

    final result = await NativeReportFileSaver().save(
      bytes: Uint8List.fromList([1, 2, 3]),
      filename: 'cybersentinel-report.pdf',
      contentType: 'application/pdf',
    );

    expect(result.status, ReportSaveStatus.cancelled);
    expect(result.location, isNull);
  });
}
