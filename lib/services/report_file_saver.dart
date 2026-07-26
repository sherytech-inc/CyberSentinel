import 'report_file_saver_base.dart';
import 'report_file_saver_stub.dart'
    if (dart.library.io) 'report_file_saver_io.dart'
    if (dart.library.html) 'report_file_saver_web.dart' as platform;

export 'report_file_saver_base.dart';

ReportFileSaver createReportFileSaver() => platform.createReportFileSaver();
