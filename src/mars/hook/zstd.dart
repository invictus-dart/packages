import 'package:code_assets/code_assets.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_x/native_toolchain_x.dart';
import 'package:process/process.dart';

import 'util.dart';

Map<String, dynamic> get _userDefines => <String, dynamic>{
  'url':
      'https://github.com/meta/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz',
  'sha256': 'eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3',
};

final class ZstdBuilder implements Builder {
  @override
  Future<void> run({
    required BuildInput input,
    required BuildOutputBuilder output,
    Logger? logger,
    ProcessManager? processManager,
    FileSystem? fileSystem,
  }) async {
    logger ??= createDefaultLogger('ZstdBuilder');
    processManager ??= const LocalProcessManager();
    fileSystem ??= const LocalFileSystem();

    final userDefines = input.userDefines.getValue('zstd', _userDefines);
    final url = userDefines['url'] as String;
    final sha256 = userDefines['sha256'] as String;
    final tgzName = Uri.parse(url).pathSegments.last;
    final tgzDirectory = tgzName.substring(0, tgzName.length - 7);
    final srcDir = input.outputDirectoryShared.resolve('$tgzDirectory/');
    final dstDir = input.outputDirectory.resolve('zstd/dst/');
    final outDir = input.outputDirectory.resolve('zstd/out/');
    await fileSystem.directory(dstDir).create(recursive: true);
    await fileSystem.directory(outDir).create(recursive: true);

    final targetOS = input.config.code.targetOS;

    // 1. Get zstd repository
    final repositoryPart = RepositoryBuilder.tgz(url: url, sha256: sha256);
    await repositoryPart.run(input: input, output: output);
    // 2. Compile static library with CMake
    final builder = CMakeBuilder(
      srcDir: srcDir,
      subDir: 'build/cmake/',
      dstDir: dstDir,
      outDir: outDir,
      variables: {
        'BUILD_SHARED_LIBS': 'OFF',
        'ZSTD_BUILD_PROGRAMS': 'OFF',
        'ZSTD_BUILD_SHARED': 'OFF',
        'ZSTD_BUILD_STATIC': 'ON',
        if (targetOS == .windows) 'ZSTD_USE_STATIC_RUNTIME': 'ON',
      },
    );
    await builder.run(input: input, output: output);
    // 3. Add code asset when link is enabled
    final libraries = getZstdLibraries(input.config.code.targetOS);
    if (input.config.linkingEnabled) {
      final linkMode = StaticLinking();
      output.assets.code.addAll(
        libraries.map(
          (library) => CodeAsset(
            package: input.packageName,
            name: library,
            linkMode: linkMode,
            file: outDir.resolve(
              'lib/${input.config.code.targetOS.libraryFileName(library, linkMode)}',
            ),
          ),
        ),
        routing: ToLinkHook(input.packageName),
      );
    }
  }
}
