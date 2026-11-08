import 'dart:io';

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
      'https://github.com/openssl/openssl/releases/download/openssl-3.5.9/openssl-3.5.9.tar.gz',
  'sha256': '603f5602e2eef00d77fbd429d34dcd5822bb301757a1bc9cdb24c670f1eb859a',
};

final class OpensslBuilder implements Builder {
  @override
  Future<void> run({
    required BuildInput input,
    required BuildOutputBuilder output,
    Logger? logger,
    ProcessManager? processManager,
    FileSystem? fileSystem,
  }) async {
    logger ??= createDefaultLogger('OpensslBuilder');
    processManager ??= const LocalProcessManager();
    fileSystem ??= const LocalFileSystem();

    final userDefines = input.userDefines.getValue('openssl', _userDefines);
    final url = userDefines['url'] as String;
    final sha256 = userDefines['sha256'] as String;
    final tgzName = Uri.parse(url).pathSegments.last;
    final tgzDirectory = tgzName.substring(0, tgzName.length - 7);
    final srcDir = input.outputDirectoryShared.resolve('$tgzDirectory/');
    final dstDir = input.outputDirectory.resolve('openssl/dst/');
    final outDir = input.outputDirectory.resolve('openssl/out/');
    await fileSystem.directory(dstDir).create(recursive: true);
    await fileSystem.directory(outDir).create(recursive: true);

    final targetOS = input.config.code.targetOS;
    final targetSdk = targetOS == .iOS ? input.config.code.iOS.targetSdk : null;
    final targetNdkApi = targetOS == .android
        ? input.config.code.android.targetNdkApi
        : null;
    final targetArchitecture = input.config.code.targetArchitecture;

    final resolver = CompilerResolver(
      codeConfig: input.config.code,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
    );
    final compiler = await resolver.resolveCompiler();
    final environment = switch (targetOS) {
      .android => {
        'ANDROID_NDK_ROOT': compiler.uri
            .resolve('../../../../../')
            .toFilePath(),
        'PATH': [
          compiler.uri.resolve('.').toFilePath(),
          ?Platform.environment['PATH'],
        ].join(OS.current == .windows ? ';' : ':'),
      },
      .iOS || .macOS => <String, String>{},
      .windows => await resolver.resolveEnvironment(compiler),
      .linux => {'CC': compiler.uri.toFilePath()},
      _ => throw UnsupportedError('Unsupported os: $targetOS'),
    };

    // 1. Get openssl repository
    final repositoryPart = RepositoryBuilder.tgz(url: url, sha256: sha256);
    await repositoryPart.run(input: input, output: output);
    // 2. Configure with Perl
    final perl = await Tools.perl.resolve(logger: logger);
    final target = switch (targetOS) {
      .android => switch (targetArchitecture) {
        .arm => 'android-arm',
        .arm64 => 'android-arm64',
        .ia32 => 'android-x86',
        .x64 => 'android-x86_64',
        _ => throw UnsupportedError(
          'Unsupported architecture: $targetArchitecture',
        ),
      },
      .iOS => switch (targetSdk) {
        .iPhoneOS => switch (targetArchitecture) {
          .arm64 => 'ios64-xcrun',
          _ => throw UnsupportedError(
            'Unsupported architecture: $targetArchitecture',
          ),
        },
        .iPhoneSimulator => switch (targetArchitecture) {
          .arm64 => 'iossimulator-arm64-xcrun',
          .x64 => 'iossimulator-x86_64-xcrun',
          _ => throw UnsupportedError(
            'Unsupported architecture: $targetArchitecture',
          ),
        },
        _ => throw UnsupportedError('Unsupported sdk: $targetSdk'),
      },
      .macOS => switch (targetArchitecture) {
        .arm64 => 'darwin64-arm64',
        .x64 => 'darwin64-x86_64',
        _ => throw UnsupportedError(
          'Unsupported architecture: $targetArchitecture',
        ),
      },
      .linux => switch (targetArchitecture) {
        .arm => 'linux-armv4',
        .arm64 => 'linux-aarch64',
        .ia32 => 'linux-x86',
        .x64 => 'linux-x86_64',
        _ => throw UnsupportedError(
          'Unsupported architecture: $targetArchitecture',
        ),
      },
      .windows => switch (targetArchitecture) {
        .arm64 => 'VC-WIN64-ARM',
        .ia32 => 'VC-WIN32',
        .x64 => 'VC-WIN64A',
        _ => throw UnsupportedError(
          'Unsupported architecture: $targetArchitecture',
        ),
      },
      _ => throw UnsupportedError('Unsupported os: $targetOS'),
    };
    await runProcess(
      executable: perl.uri,
      arguments: [
        srcDir.resolve('Configure').toFilePath(),
        target,
        'no-shared',
        'no-pinshared',
        'no-apps',
        'no-tests',
        'no-docs',
        if (targetOS == .android) '-D__ANDROID_API__=$targetNdkApi',
        '--prefix=${outDir.toFilePath()}',
        '--libdir=lib',
      ],
      workingDirectory: dstDir,
      environment: environment,
      logger: logger,
      processManager: processManager,
      throwOnUnexpectedExitCode: true,
    );
    // 3. Compile with make/nmake
    final executable = targetOS == .windows
        ? compiler.uri.resolve('nmake.exe')
        : await Tools.make.resolve(logger: logger).then((e) => e.uri);
    await runProcess(
      executable: executable,
      arguments: [
        if (targetOS != .windows) '-j${Platform.numberOfProcessors}',
        'build_libs',
      ],
      workingDirectory: dstDir,
      environment: environment,
      logger: logger,
      processManager: processManager,
      throwOnUnexpectedExitCode: true,
    );
    // 4. Install
    await runProcess(
      executable: executable,
      arguments: ['install'],
      workingDirectory: dstDir,
      environment: environment,
      logger: logger,
      processManager: processManager,
      throwOnUnexpectedExitCode: true,
    );
    // 5. Add code asset when link is enabled
    final libraries = getOpensslLibraries(targetOS);
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
