import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mars/mars.dart';
import 'package:mars_logging/mars_logging.dart';

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
    pubKey:
        'f3d382d0bd7e33356d8dc497e1f4b3f93f8d4f96d0fdddda66e4eaf9abb50564ce356990d7af20a47cccfb8c3e4b9070c9a56fad0ffd07d0114238b950a36abc',
    useConsole: true,
    maxFileSize: 10 * 1024 * 1024,
    maxAliveDuration: 30 * 24 * 60 * 60,
  );
  final logger = Logger('mars_logging');
  logger.onRecord.listen(xlog.onRecord);
  try {
    throw AssertionError();
  } catch (e, st) {
    logger.finest('A message with ${Level.FINEST}', e, st);
    logger.finer('A message with ${Level.FINER}', e, st);
    logger.fine('A message with ${Level.FINE}', e, st);
    logger.config('A message with ${Level.CONFIG}', e, st);
    logger.info('A message with ${Level.INFO}', e, st);
    logger.warning('A message with ${Level.WARNING}', e, st);
    logger.severe('A message with ${Level.SEVERE}', e, st);
    logger.shout('A message with ${Level.SHOUT}', e, st);
  }
  await xlog.flush();
  xlog.close();

  final date = DateTime.now();
  final dateNumber = date.year * 10000 + date.month * 100 + date.day;
  final logUri = Platform.script.resolve('logs/log_$dateNumber.xlog');
  final log = File.fromUri(logUri);
  final input = await log.readAsBytes();
  final output = await xlog.decode(
    input,
    privKey: 'c030b50a82ac27f2b14b63781a4a18fe22d92ca456636d5401743fb375aefafe',
  );
  final text = utf8.decode(output);
  stdout.writeln(text);
}
