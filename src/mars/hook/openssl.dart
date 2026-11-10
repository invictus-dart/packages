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

    if (!input.config.buildCodeAssets) return;

    final userDefines = input.userDefines.getValue('openssl', _userDefines);
    final url = userDefines['url'] as String;
    final sha256 = userDefines['sha256'] as String;
    final tgzName = Uri.parse(url).pathSegments.last;
    // TODO: The source directory name is inferred by stripping a hardcoded
    // `.tar.gz` (7-char) suffix from the URL file name. This relies on the
    // GitHub release tarball convention `<repo>-<tag>/` and breaks for other
    // suffixes such as `.tgz` supplied via user defines. Derive the root
    // directory from the extracted archive instead: use the single child
    // directory of the extraction directory, or read the first tar entry name.
    final tgzDirectory = tgzName.substring(0, tgzName.length - 7);
    final srcDir = input.outputDirectoryShared.resolve('$tgzDirectory/');
    final dstDir = input.outputDirectory.resolve('openssl/dst/');
    final outDir = input.outputDirectory.resolve('openssl/out/');
    await fileSystem.directory(dstDir).create(recursive: true);
    await fileSystem.directory(outDir).create(recursive: true);

    final targetOS = input.config.code.targetOS;
    final targetSdk = targetOS == .iOS ? input.config.code.iOS.targetSdk : null;
    final targetArchitecture = input.config.code.targetArchitecture;

    final context = ToolResolvingContext(
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
    );
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
      .iOS => switch (targetSdk) {
        .iPhoneOS => {
          'SDKROOT': await iPhoneOSSdk
              .resolve(context)
              .then((e) => e.uri.toFilePath()),
        },
        .iPhoneSimulator => {
          'SDKROOT': await iPhoneSimulatorSdk
              .resolve(context)
              .then((e) => e.uri.toFilePath()),
        },
        _ => throw UnsupportedError('Unsupported sdk: $targetSdk'),
      },
      .macOS => {
        'SDKROOT': await macosxSdk
            .resolve(context)
            .then((e) => e.uri.toFilePath()),
      },
      .windows => await resolver.resolveEnvironment(compiler),
      .linux => {'CC': compiler.uri.toFilePath()},
      _ => throw UnsupportedError('Unsupported os: $targetOS'),
    };

    // 1. Get openssl repository
    final repositoryPart = RepositoryBuilder.tgz(url: url, sha256: sha256);
    await repositoryPart.run(input: input, output: output);
    // 2. Configure with Perl
    final perl = await Tools.perl.resolve(context);
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
        if (targetOS == .android)
          '-D__ANDROID_API__=${input.config.code.android.targetNdkApi}',
        if (targetOS == .iOS)
          '-mios-version-min=${_appleDeploymentTarget(input.config.code.iOS.deploymentVersion)}',
        if (targetOS == .macOS)
          '-mmacos-version-min=${_appleDeploymentTarget(input.config.code.macOS.deploymentVersion)}',
        '--prefix=${outDir.toFilePath()}',
        '--libdir=lib',
      ],
      workingDirectory: dstDir,
      environment: environment,
      logger: logger,
      processManager: processManager,
      throwOnUnexpectedExitCode: true,
    );
    // 3. Compile in parallel: jom on Windows, GNU make everywhere else.
    // nmake is not used on Windows because it has no parallel mode at all,
    // which is what made the Windows build an order of magnitude slower than
    // the macOS one for identical sources.
    final tool = targetOS == .windows
        ? await Tools.jom.resolve(context)
        : await Tools.make.resolve(context);
    await runProcess(
      executable: tool.uri,
      arguments: [
        // jom takes `/J <n>`, GNU make takes `-j<n>`. Both propagate the job
        // count through MAKEFLAGS to the `$(MAKE) ... _build_libs` recursion
        // OpenSSL's makefile performs, so the leaf compiler invocations run in
        // parallel too.
        ...targetOS == .windows
            ? ['/J', '${Platform.numberOfProcessors}']
            : ['-j${Platform.numberOfProcessors}'],
        'build_libs',
      ],
      workingDirectory: dstDir,
      environment: {
        ...environment,
        // OpenSSL's generated makefile passes the shared
        // `/Zi /Fdossl_static.pdb` to every `cl` invocation without `/FS`, so
        // parallel compiles collide on the same PDB and abort with C1041.
        // `/FS` serialises PDB writes through mspdbsrv. `cl` reads `CL` from
        // the environment, so this needs no change to the generated makefile
        // or to the vendored sources.
        if (targetOS == .windows)
          'CL': {...?environment['CL']?.split(' '), '/FS'}.join(' '),
      },
      logger: logger,
      processManager: processManager,
      throwOnUnexpectedExitCode: true,
    );
    // 4. Install. Serial on Windows: `jom` uses every core unless `/J` is
    // given, and the install rules are not independent. Both `install_dev` and
    // `install_runtime` pull in `build_programs`/`build_libs`, whose recipes
    // run the makefile's `depend` target. `depend` rewrites `makefile` by
    // renaming `makefile-<pid>` over it (`util/add-depends.pl`), and Windows
    // refuses that rename while another jom instance still has the makefile
    // open, which surfaces as `[depend] Error 13` from two parallel instances.
    // `/J 1` runs those `depend` steps strictly one at a time.
    await runProcess(
      executable: tool.uri,
      arguments: [
        'install',
        if (targetOS == .windows) ...['/J', '1'],
      ],
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

String _appleDeploymentTarget(AppleVersion version) {
  final major = version.major;
  final minor = version.minor;
  final patch = version.patch;
  if (patch != 0) return '$major.$minor.$patch';
  if (minor != 0) return '$major.$minor';
  return '$major';
}
