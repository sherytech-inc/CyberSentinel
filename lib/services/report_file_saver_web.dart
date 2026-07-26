import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'report_file_saver_base.dart';

ReportFileSaver createReportFileSaver() => WebReportFileSaver();

class WebReportFileSaver implements ReportFileSaver {
  @override
  Future<ReportSaveResult> save({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final blob = web.Blob(
      <JSUint8Array>[bytes.toJS].toJS,
      web.BlobPropertyBag(type: contentType),
    );
    final objectUrl = web.URL.createObjectURL(blob);
    try {
      final anchor = web.HTMLAnchorElement()
        ..href = objectUrl
        ..download = filename;
      web.document.body?.appendChild(anchor);
      anchor.click();
      anchor.remove();
    } finally {
      web.URL.revokeObjectURL(objectUrl);
    }
    return ReportSaveResult.saved(filename);
  }
}
