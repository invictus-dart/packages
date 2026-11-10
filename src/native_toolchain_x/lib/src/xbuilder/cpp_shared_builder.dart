import 'package:code_assets/code_assets.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:process/process.dart';

import '../cbuilder/compiler_resolver.dart';
import '../cbuilder/run_cbuilder.dart';
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
    final target = RunCBuilder.androidNdkClangTargetFlags[targetArchitecture];
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
}
