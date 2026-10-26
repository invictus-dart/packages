import 'dart:io';

import 'package:mars/mars.dart';
import 'package:test/test.dart';

void main() {
  test('marsVersion is not empty', () {
    expect(marsVersion, isNotEmpty);
  });

  test('xlog open/write/flush/close writes a log file', () {
    final logDir = Directory.systemTemp.createTempSync('mars_test_log_');
    addTearDown(() => logDir.deleteSync(recursive: true));

    xlogSetLevel(MarsLogLevel.all);
    xlogOpen(XLogConfig(
      mode: MarsAppenderMode.sync,
      logDir: logDir.path,
      namePrefix: 'mars_test',
      compressMode: MarsCompressMode.zlib,
    ));
    xlogWrite(MarsLogLevel.info, 'mars_test', 'mars_test.dart', 1,
        'hello mars from dart');
    xlogFlushSync();
    xlogClose();

    final logFiles = logDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('mars_test'))
        .toList();
    expect(logFiles, isNotEmpty, reason: 'expected xlog files in $logDir');
  });
}
