import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:process/process.dart';

import '../tool/tool_resolver.dart';
import '../utils/run_process.dart';
import 'logger.dart';
import 'tools.dart';

abstract base class DownloadBuilder implements Builder {
  factory DownloadBuilder.tgz({
    required String url,
    required String sha256,
    Uri? dir,
    int? stripComponents,
  }) => _TgzDownloadBuilder(
    url: url,
    sha256: sha256,
    dir: dir,
    stripComponents: stripComponents,
  );

  DownloadBuilder.impl();

  @override
  Future<void> run({
    required BuildInput input,
    required BuildOutputBuilder output,
    Logger? logger,
  });
}

final class _TgzDownloadBuilder extends DownloadBuilder {
  final String url;
  final String sha256;
  final Uri? dir;
  final int? stripComponents;

  _TgzDownloadBuilder({
    required this.url,
    required this.sha256,
    this.dir,
    this.stripComponents,
  }) : super.impl();

  @override
  Future<void> run({
    required BuildInput input,
    required BuildOutputBuilder output,
    Logger? logger,
    ProcessManager? processManager,
    FileSystem? fileSystem,
  }) async {
    logger ??= createDefaultLogger('DownloadBuilder');
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
        if (stripComponents != null) '--strip-components=$stripComponents',
      ],
      workingDirectory: dir,
      logger: logger,
      processManager: processManager,
      throwOnUnexpectedExitCode: true,
    );
    await tmp.rename(tgz.path);
  }
}
