import 'package:change_case/change_case.dart';
import 'package:code_assets/code_assets.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:process/process.dart';

import '../cbuilder/build_mode.dart';
import '../cbuilder/compiler_resolver.dart';
import '../tool/tool_error.dart';
import '../tool/tool_instance.dart';
import '../utils/run_process.dart';
import 'logger.dart';
import 'tools.dart';

final class CMakeBuilder implements Builder {
  final Uri srcDir;
  final String? subDir;
  Uri? dstDir;
  Uri? outDir;
  final Map<String, String> variables;
  final BuildMode buildMode;

  CMakeBuilder({
    required this.srcDir,
    this.subDir,
    this.dstDir,
    this.outDir,
    this.variables = const {},
    this.buildMode = .release,
  });

  @override
  Future<void> run({
    required BuildInput input,
    required BuildOutputBuilder output,
    Logger? logger,
    ProcessManager? processManager,
    FileSystem? fileSystem,
  }) async {
    logger ??= createDefaultLogger('CMakeBuilder');
    processManager ??= const LocalProcessManager();
    fileSystem ??= const LocalFileSystem();

    if (!input.config.buildCodeAssets) {
      logger.info(
        'config.buildAssetTypes did not contain CodeAssets, '
        'skipping CodeAsset ${input.packageName} build.',
      );
      return;
    }

    final cmake = await Tools.cmake.resolve(logger: logger);
    final buildMode = this.buildMode.name.toCapitalCase();

    final subDir = this.subDir;
    final dstDir = this.dstDir ?? input.outputDirectory.resolve('dst/');
    final outDir = this.outDir ?? input.outputDirectory.resolve('out/');
    await fileSystem.directory(dstDir).create(recursive: true);
    await fileSystem.directory(outDir).create(recursive: true);

    // cmake -S<src> -B<dst> -D<variable>
    await runProcess(
      executable: cmake.uri,
      arguments: [
        '-S${subDir == null ? srcDir.toFilePath() : srcDir.resolve(subDir).toFilePath()}',
        '-B${dstDir.toFilePath()}',
        '-DCMAKE_BUILD_TYPE=$buildMode',
        '-DCMAKE_INSTALL_PREFIX=${outDir.toFilePath()}',
        '-DCMAKE_INSTALL_LIBDIR=lib',
        // '-DCMAKE_PLATFORM_NO_VERSIONED_SONAME=ON',
        ...await _getOsVariables(
          codeConfig: input.config.code,
          logger: logger,
          processManager: processManager,
          fileSystem: fileSystem,
        ),
        ...variables.entries.map((e) => '-D${e.key}=${e.value}'),
      ],
      workingDirectory: srcDir,
      logger: logger,
      processManager: processManager,
      throwOnUnexpectedExitCode: true,
    );
    // cmake --build <dst> --config <type>
    await runProcess(
      executable: cmake.uri,
      arguments: ['--build', dstDir.toFilePath(), '--config', buildMode],
      workingDirectory: srcDir,
      logger: logger,
      processManager: processManager,
      throwOnUnexpectedExitCode: true,
    );
    // cmake --install <dst> --config <type> --prefix <out>
    await runProcess(
      executable: cmake.uri,
      arguments: [
        '--install',
        dstDir.toFilePath(),
        '--config',
        buildMode,
        '--prefix',
        outDir.toFilePath(),
      ],
      workingDirectory: srcDir,
      logger: logger,
      processManager: processManager,
      throwOnUnexpectedExitCode: true,
    );
  }

  // https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html#cross-compiling
  // https://developer.android.com/studio/projects/configure-cmake?hl=zh-cn#call-cmake-cli
  // https://developer.android.com/ndk/guides/cmake?hl=zh-cn#command-line
  Future<List<String>> _getOsVariables({
    required CodeConfig codeConfig,
    Logger? logger,
    ProcessManager? processManager,
    FileSystem? fileSystem,
  }) async => switch (codeConfig.targetOS) {
    .android => await _getAndroidVariables(
      codeConfig: codeConfig,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
    ),
    .iOS => [
      '-DCMAKE_SYSTEM_NAME=iOS',
      '-DCMAKE_OSX_SYSROOT=${codeConfig.iOS.targetSdk.type}',
      '-DCMAKE_OSX_ARCHITECTURES=${codeConfig.targetArchitecture.toDarwin()}',
      '-DCMAKE_OSX_DEPLOYMENT_TARGET=${codeConfig.iOS.targetVersion}',
    ],
    .macOS => [
      '-DCMAKE_OSX_ARCHITECTURES=${codeConfig.targetArchitecture.toDarwin()}',
      '-DCMAKE_OSX_DEPLOYMENT_TARGET=${codeConfig.macOS.targetVersion}',
    ],
    .windows => [
      '-DCMAKE_GENERATOR_PLATFORM=${codeConfig.targetArchitecture.toWindows()}',
    ],
    .linux => await _getLinuxVariables(
      codeConfig: codeConfig,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
    ),
    _ => [],
  };

  Future<List<String>> _getAndroidVariables({
    required CodeConfig codeConfig,
    Logger? logger,
    ProcessManager? processManager,
    FileSystem? fileSystem,
  }) async {
    final resolver = CompilerResolver(
      codeConfig: codeConfig,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
    );
    final compiler = await resolver.resolveCompiler();
    final ndkUri = compiler.uri.resolve('../../../../../');
    return [
      '-DCMAKE_TOOLCHAIN_FILE=${ndkUri.resolve('build/cmake/android.toolchain.cmake').toFilePath()}',
      '-DANDROID_ABI=${codeConfig.targetArchitecture.toAndroid()}',
      '-DANDROID_PLATFORM=android-${codeConfig.android.targetNdkApi}',
    ];
  }

  Future<List<String>> _getLinuxVariables({
    required CodeConfig codeConfig,
    Logger? logger,
    ProcessManager? processManager,
    FileSystem? fileSystem,
  }) async {
    final resolver = CompilerResolver(
      codeConfig: codeConfig,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
    );
    final compiler = await resolver.resolveCompiler();
    return [
      '-DCMAKE_SYSTEM_NAME=Linux',
      '-DCMAKE_SYSTEM_PROCESSOR=${codeConfig.targetArchitecture.toLinux()}',
      '-DCMAKE_C_COMPILER=${compiler.uri.toFilePath()}',
      '-DCMAKE_CXX_COMPILER=${compiler.cxxUri.toFilePath()}',
    ];
  }
}

extension on Architecture {
  String toAndroid() => switch (this) {
    .arm => 'armeabi-v7a',
    .arm64 => 'arm64-v8a',
    .ia32 => 'x86',
    .x64 => 'x86_64',
    .riscv64 => 'riscv64',
    _ => throw UnsupportedError('$this is not supported'),
  };

  String toDarwin() => switch (this) {
    .arm64 => 'arm64',
    .x64 => 'x86_64',
    _ => throw UnsupportedError('$this is not supported'),
  };

  String toWindows() => switch (this) {
    .arm => 'ARM',
    .arm64 => 'ARM64',
    .ia32 => 'Win32',
    .x64 => 'x64',
    _ => throw UnsupportedError('$this is not supported'),
  };

  String toLinux() => switch (this) {
    .arm => 'arm',
    .arm64 => 'aarch64',
    .ia32 => 'i686',
    .riscv32 => 'riscv32',
    .riscv64 => 'riscv64',
    .x64 => 'x86_64',
    _ => throw UnsupportedError('$this is not supported'),
  };
}

extension on ToolInstance {
  Uri get cxxUri {
    final cLast = uri.pathSegments.last;
    final cxxLast = cLast.contains('gcc')
        ? cLast.replaceLast('gcc', 'g++')
        : cLast.contains('clang')
        ? cLast.replaceLast('clang', 'clang++')
        : throw ToolError('$tool is not a clang or gcc based compiler');
    return uri.resolve(cxxLast);
  }
}

extension on String {
  String replaceLast(String from, String to) {
    final start = lastIndexOf(from);
    if (start < 0) return this;
    final end = start + from.length;
    return replaceRange(start, end, to);
  }
}
