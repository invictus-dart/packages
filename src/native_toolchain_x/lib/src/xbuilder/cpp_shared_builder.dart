import 'package:code_assets/code_assets.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:process/process.dart';

import '../cbuilder/compiler_resolver.dart';
import 'logger.dart';

class CppSharedBuilder implements Builder {
  @override
  Future<void> run({
    required BuildInput input,
    required BuildOutputBuilder output,
    Logger? logger,
    ProcessManager? processManager,
    FileSystem? fileSystem,
  }) async {
    logger ??= createDefaultLogger('CppSharedBuilder');
    processManager ??= const LocalProcessManager();
    fileSystem ??= const LocalFileSystem();

    if (!input.config.buildCodeAssets ||
        input.config.code.targetOS != .android) {
      return;
    }

    final targetArchitecture = input.config.code.targetArchitecture;

    final resolver = CompilerResolver(
      codeConfig: input.config.code,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
    );
    final compiler = await resolver.resolveCompiler();
    final target = sysrootTargets[targetArchitecture];
    if (target == null) {
      throw UnsupportedError('Unsupported architecture: $targetArchitecture');
    }
    // The compiler lives at <ndk>/toolchains/llvm/prebuilt/<host>/bin/clang.
    final fileUri = compiler.uri.resolve(
      '../sysroot/usr/lib/$target/libc++_shared.so',
    );
    final assetUri = input.outputDirectory.resolve('libc++_shared.so');
    final assetPath = assetUri.toFilePath();
    await fileSystem.file(fileUri).copy(assetPath);
    final asset = CodeAsset(
      package: input.packageName,
      name: 'libc++_shared.so',
      file: assetUri,
      linkMode: DynamicLoadingBundled(),
    );
    output.assets.code.add(asset);
    output.dependencies.add(fileUri);
  }

  /// NDK sysroot library directories are named after the *platform* triples,
  /// which differ from the clang target triples in
  /// [RunCBuilder.androidNdkClangTargetFlags]: 32-bit ARM compiles with
  /// "armv7a-linux-androideabi" but its sysroot directory is
  /// "arm-linux-androideabi". Do not merge with the clang target table.
  static final sysrootTargets = {
    Architecture.arm: 'arm-linux-androideabi',
    Architecture.arm64: 'aarch64-linux-android',
    Architecture.ia32: 'i686-linux-android',
    Architecture.x64: 'x86_64-linux-android',
    Architecture.riscv64: 'riscv64-linux-android',
  };
}
