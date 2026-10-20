import 'package:file/file.dart';
import 'package:logging/logging.dart';
import 'package:process/process.dart';

import '../native_toolchain/android_ndk.dart';
import 'tool.dart';
import 'tool_error.dart';
import 'tool_instance.dart';
import 'tool_resolver.dart';

abstract final class ToolKit {
  static Tool get git => Tool(
    name: 'Git',
    defaultResolver: CliVersionResolver(
      wrappedResolver: PathToolResolver(toolName: 'Git', executableName: 'git'),
    ),
  );

  static Tool get cmake => Tool(
    name: 'CMake',
    defaultResolver: CliVersionResolver(
      wrappedResolver: PathToolResolver(
        toolName: 'CMake',
        executableName: 'cmake',
      ),
    ),
  );

  static Tool get ndk => androidNdk;
}

extension ToolExt on Tool {
  Future<ToolInstance> resolve({
    required Logger? logger,
    ProcessManager? processManager,
    FileSystem? fileSystem,
  }) async {
    final context = ToolResolvingContext(
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
    );
    final resolved = (await defaultResolver!.resolve(
      context,
    )).where((i) => i.tool == this).toList()..sort();
    final result = resolved.firstOrNull;
    if (result == null) {
      final errorMessage = '$name is not found';
      logger?.severe(errorMessage);
      throw ToolError(errorMessage);
    }
    return result;
  }
}
