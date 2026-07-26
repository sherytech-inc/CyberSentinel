import 'dart:typed_data';

import 'package:cybersentinel/services/report_file_saver_base.dart';
import 'package:cybersentinel/services/report_file_saver_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web saver creates a byte download without navigation', () async {
    final saver = WebReportFileSaver();
    final result = await saver.save(
      bytes: Uint8List.fromList([1, 2, 3]),
      filename: 'cybersentinel-report.json',
      contentType: 'application/json',
    );

    expect(result.status, ReportSaveStatus.saved);
    expect(result.location, 'cybersentinel-report.json');
  });
}
