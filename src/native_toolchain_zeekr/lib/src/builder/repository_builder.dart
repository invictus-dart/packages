import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:process/process.dart';

import '../tool/tool_kit.dart';
import '../utils/run_process.dart';
import '../utils/user_defines.dart';
import 'logger.dart';

abstract base class RepositoryBuilder implements Builder {
  factory RepositoryBuilder.git({
    required String url,
    required String refspec,
    required Uri dir,
  }) => GitRepositoryBuilder(url: url, refspec: refspec, dir: dir);

  RepositoryBuilder.impl();

  @override
  Future<void> run({
    required BuildInput input,
    required BuildOutputBuilder output,
    Logger? logger,
  });
}

final class GitRepositoryBuilder extends RepositoryBuilder {
  final String url;
  final String refspec;
  final Uri dir;

  GitRepositoryBuilder({
    required this.url,
    required this.refspec,
    required this.dir,
  }) : super.impl();

  @override
  Future<void> run({
    required BuildInput input,
    required BuildOutputBuilder output,
    Logger? logger,
    ProcessManager? processManager,
    FileSystem? fileSystem,
  }) async {
    logger ??= createDefaultLogger();
    processManager ??= const LocalProcessManager();
    fileSystem ??= const LocalFileSystem();

    final git = await ToolKit.git.resolve(logger: logger);
    final url = input.userDefines.getValue('url', this.url);
    final refspec = input.userDefines.getValue('refspec', this.refspec);

    await fileSystem.directory(dir).create(recursive: true);

    // git init
    await runProcess(
      executable: git.uri,
      arguments: ['init'],
      workingDirectory: dir,
      logger: logger,
      processManager: processManager,
      throwOnUnexpectedExitCode: true,
    );
    // git remote
    final result = await runProcess(
      executable: git.uri,
      arguments: ['remote'],
      workingDirectory: dir,
      logger: logger,
      processManager: processManager,
      throwOnUnexpectedExitCode: true,
    );
    if (result.stdout.trim().isEmpty) {
      // git remote add origin <url>
      await runProcess(
        executable: git.uri,
        arguments: ['remote', 'add', 'origin', url],
        workingDirectory: dir,
        logger: logger,
        processManager: processManager,
        throwOnUnexpectedExitCode: true,
      );
    } else {
      // git remote set-url origin <url>
      await runProcess(
        executable: git.uri,
        arguments: ['remote', 'set-url', 'origin', url],
        workingDirectory: dir,
        logger: logger,
        processManager: processManager,
        throwOnUnexpectedExitCode: true,
      );
    }
    // git fetch origin <refspec>
    await runProcess(
      executable: git.uri,
      arguments: ['fetch', 'origin', refspec],
      workingDirectory: dir,
      logger: logger,
      processManager: processManager,
      throwOnUnexpectedExitCode: true,
    );
    // git reset --hard <commit>
    await runProcess(
      executable: git.uri,
      arguments: ['reset', '--hard', 'FETCH_HEAD'],
      workingDirectory: dir,
      logger: logger,
      processManager: processManager,
      throwOnUnexpectedExitCode: true,
    );
  }
}
