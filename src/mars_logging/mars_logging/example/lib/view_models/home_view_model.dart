import 'package:clover/clover.dart';
import 'package:logging/logging.dart';

Logger get _logger => Logger('HomeViewModel');

class HomeViewModel extends ViewModel {
  final List<Level> levels;

  HomeViewModel()
    : levels = List.unmodifiable([
        Level.FINEST,
        Level.FINER,
        Level.FINE,
        Level.CONFIG,
        Level.INFO,
        Level.WARNING,
        Level.SEVERE,
        Level.SHOUT,
      ]);

  void log(Level level) {
    _logger.log(level, 'A message with $level.');
  }
}
