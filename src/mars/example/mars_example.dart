import 'dart:convert';
import 'dart:io';

import 'package:mars/mars.dart';

void main() async {
  xlog.open(
    mode: .async,
    level: .debug,
    logsDir: Platform.script.resolve('logs/').toFilePath(),
    cacheDir: Platform.script.resolve('logs/cache/').toFilePath(),
    cacheDays: 0,
    namePrefix: 'log',
    compressMode: .zstd,
    compressLevel: .level6,
    // pubKey:
    //     'f3d382d0bd7e33356d8dc497e1f4b3f93f8d4f96d0fdddda66e4eaf9abb50564ce356990d7af20a47cccfb8c3e4b9070c9a56fad0ffd07d0114238b950a36abc',
    useConsole: true,
    maxFileSize: 10 * 1024 * 1024,
    maxAliveDuration: 30 * 24 * 60 * 60,
  );
  try {
    throw AssertionError();
  } catch (e, st) {
    xlog.verbose('mars', 'A message with ${LogLevel.verbose}', e, st);
    xlog.debug('mars', 'A message with ${LogLevel.debug}', e, st);
    xlog.info('mars', 'A message with ${LogLevel.info}', e, st);
    xlog.warn('mars', 'A message with ${LogLevel.warn}', e, st);
    xlog.error('mars', 'A message with ${LogLevel.error}', e, st);
    xlog.fatal('mars', 'A message with ${LogLevel.fatal}', e, st);
  }
  await xlog.flushSync();
  xlog.close();

  final date = DateTime.now();
  final dateNumber = date.year * 10000 + date.month * 100 + date.day;
  final logUri = Platform.script.resolve('logs/log_$dateNumber.xlog');
  final log = File.fromUri(logUri);
  final input = await log.readAsBytes();
  final output = await xlog.decode(input);
  final text = utf8.decode(output);
  stdout.writeln(text);
}
