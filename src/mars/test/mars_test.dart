import 'dart:io';

import 'package:mars/mars.dart';
import 'package:test/test.dart';

void main() {
  test('xlog open/write/flush/close writes a log file', () {
    final logsDir = Directory.systemTemp.createTempSync('mars_test_log_');
    addTearDown(() => logsDir.deleteSync(recursive: true));

    XLog.open(
      logsDir: logsDir.path,
      cacheDir: logsDir.path,
      namePrefix: 'mars_test',
    );
    XLog.info('mars_test', 'hello mars from dart');
    XLog.flush(true);
    XLog.close();

    final logs = logsDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.contains('mars_test'))
        .toList();
    expect(logs, isNotEmpty, reason: 'expected xlog files in $logsDir');
  });
}
