import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:process/process.dart';

import '../utils/run_process.dart';
import '../tool/tool_resolver.dart';
import 'logger.dart';
import 'tools.dart';

abstract base class RepositoryBuilder implements Builder {
  factory RepositoryBuilder.tgz({
    required String url,
    required String sha256,
    Uri? dir,
  }) => _TgzRepositoryBuilder(url: url, sha256: sha256, dir: dir);

  factory RepositoryBuilder.git({
    required String url,
    required String refspec,
    Uri? dir,
  }) => _GitRepositoryBuilder(url: url, refspec: refspec, dir: dir);

  RepositoryBuilder.impl();

  @override
  Future<void> run({
    required BuildInput input,
    required BuildOutputBuilder output,
    Logger? logger,
  });
}

final class _TgzRepositoryBuilder extends RepositoryBuilder {
  final String url;
  final String sha256;
  final Uri? dir;

  _TgzRepositoryBuilder({required this.url, required this.sha256, this.dir})
    : super.impl();

  @override
  Future<void> run({
    required BuildInput input,
    required BuildOutputBuilder output,
    Logger? logger,
    ProcessManager? processManager,
    FileSystem? fileSystem,
  }) async {
    logger ??= createDefaultLogger('RepositoryBuilder');
    processManager ??= const LocalProcessManager();
    fileSystem ??= const LocalFileSystem();

    final context = ToolResolvingContext(
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
    );
    final tar = await Tools.tar.resolve(context);

    final dir = this.dir ?? input.outputDirectoryShared;
    await fileSystem.directory(dir).create(recursive: true);

    final tgzUrl = Uri.parse(url);
    final tgzName = tgzUrl.pathSegments.last;
    final tgzUri = dir.resolve(tgzName);
    final tgz = fileSystem.file(tgzUri);
    final tgzExists = await tgz.exists();
    if (tgzExists) return;
    final client = HttpClient()
      ..findProxy = HttpClient.findProxyFromEnvironment;
    final request = await client.getUrl(tgzUrl);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Error downloading file: Status code ${response.statusCode}',
      );
    }
    final tmpUri = dir.resolve('$tgzName.tmp');
    final tmp = fileSystem.file(tmpUri);
    final tmpSink = tmp.openWrite();
    await response.pipe(tmpSink);
    final bytes = await tmp.readAsBytes();
    final hash = crypto.sha256.convert(bytes).toString();
    if (hash != sha256) {
      throw Exception(
        'Download failed, invalid hash: $hash, '
        'expected $sha256.',
      );
    }
    await runProcess(
      executable: tar.uri,
      arguments: [
        '-xzf',
        tmp.path,
        '-C',
        dir.toFilePath(),
        // '--strip-components=1',
      ],
      workingDirectory: dir,
      logger: logger,
      processManager: processManager,
      throwOnUnexpectedExitCode: true,
    );
    await tmp.rename(tgz.path);
  }
}

final class _GitRepositoryBuilder extends RepositoryBuilder {
  final String url;
  final String refspec;
  final Uri? dir;

  _GitRepositoryBuilder({required this.url, required this.refspec, this.dir})
    : super.impl();

  @override
  Future<void> run({
    required BuildInput input,
    required BuildOutputBuilder output,
    Logger? logger,
    ProcessManager? processManager,
    FileSystem? fileSystem,
  }) async {
    logger ??= createDefaultLogger('RepositoryBuilder');
    processManager ??= const LocalProcessManager();
    fileSystem ??= const LocalFileSystem();

    if (!input.config.buildCodeAssets) return;

    final context = ToolResolvingContext(
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
    );
    final git = await Tools.git.resolve(context);

    final dir = this.dir ?? input.outputDirectoryShared;
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
