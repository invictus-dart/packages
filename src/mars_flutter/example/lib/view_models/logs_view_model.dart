import 'dart:io';

import 'package:clover/clover.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path;

class LogsViewModel extends ViewModel {
  List<File> _logs;

  LogsViewModel() : _logs = [] {
    _updateLogs();
  }

  List<File> get logs => List.unmodifiable(_logs);

  void _updateLogs() async {
    final filesDir = await path.getApplicationSupportDirectory();
    final logsPath = path.join(filesDir.path, 'logs');
    final logsDir = Directory(logsPath);
    final exists = await logsDir.exists();
    if (!exists) {
      return;
    }
    final entities = await logsDir.list().toList();
    _logs = entities.whereType<File>().toList();
    notifyListeners();
  }

  Future<XFile?> openLog() async {
    final typeGroup = XTypeGroup(label: 'XLOG', extensions: ['xlog']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    return file;
  }
}
