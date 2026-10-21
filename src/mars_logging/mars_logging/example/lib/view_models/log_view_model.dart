import 'package:clover/clover.dart';
import 'package:path/path.dart' as path;

class LogViewModel extends ViewModel {
  final String logPath;

  LogViewModel(this.logPath);

  String get logName => path.basenameWithoutExtension(logPath);
}
