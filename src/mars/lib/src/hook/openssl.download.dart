import 'package:code_assets/code_assets.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_x/native_toolchain_x.dart';
import 'package:process/process.dart';

import 'util.dart';

/// Pinned install trees from invictus-dart/openssl release v3.5.9, one per
/// OpenSSL Configure target. Each archive carries headers and the static
/// libcrypto/libssl, so the extracted directory serves as both the include and
/// the library path. `sha256` is the digest GitHub reports for the asset.
///
/// Overriding is all-or-nothing: `getValue` replaces the default instead of
/// merging into it, so an override has to carry every entry it needs.
Map<String, dynamic> get _userDefines => <String, dynamic>{
  'android': <String, dynamic>{
    'arm': <String, dynamic>{
      'url':
          'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-android-arm.tar.gz',
      'sha256':
          'f352e0a6e3f5e4d0733987953bd22a422c99bddf052fa8817bcc0de3242a21ee',
    },
    'arm64': <String, dynamic>{
      'url':
          'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-android-arm64.tar.gz',
      'sha256':
          'f07d46e5fbbb677922329e5ec2ad08eb7cc7271c886835b0acf3225e7fb6fdda',
    },
    'ia32': <String, dynamic>{
      'url':
          'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-android-x86.tar.gz',
      'sha256':
          '94a9278e9f2ca6c5ed7b513c6835edb153f711fc9626c5b1986e83bd182593ef',
    },
    'x64': <String, dynamic>{
      'url':
          'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-android-x86_64.tar.gz',
      'sha256':
          'd7247a1225343a9753c5f07f957a3d99f861d0b5f72549a621b09ec8c8b155c6',
    },
  },
  'ios': <String, dynamic>{
    'simulator': <String, dynamic>{
      'arm64': <String, dynamic>{
        'url':
            'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-iossimulator-arm64-xcrun.tar.gz',
        'sha256':
            'f54b5c8d7389deaafa4ad4f4e9c2384ad3466775148ba0e69ab0cdfae0a22b81',
      },
      'x64': <String, dynamic>{
        'url':
            'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-iossimulator-x86_64-xcrun.tar.gz',
        'sha256':
            'df7efb0bdc05da30d58552f55d23a154a19c45c5351c5b9fb46d133c1baac251',
      },
    },
    'device': <String, dynamic>{
      'url':
          'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-ios64-xcrun.tar.gz',
      'sha256':
          'f6ff2e6bc057458b70fa10dff24cd2120cbeeb3898239049d7cce6d6fe787768',
    },
  },
  'macos': <String, dynamic>{
    'arm64': <String, dynamic>{
      'url':
          'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-darwin64-arm64.tar.gz',
      'sha256':
          'a88d44695e27b9c2953066f4e663fd6660d6ad213a67b85a8603a2f6d635621f',
    },
    'x64': <String, dynamic>{
      'url':
          'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-darwin64-x86_64.tar.gz',
      'sha256':
          '41454fc73ec5c2f663bbafb2d36bc23099f79835359e3bceafe286c2c1903acb',
    },
  },
  'windows': <String, dynamic>{
    'arm64': <String, dynamic>{
      'url':
          'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-VC-WIN64-ARM.tar.gz',
      'sha256':
          '102033479a8ba70f299ade1adbf61bd5487899b0d5601b250956850abe6f4882',
    },
    'ia32': <String, dynamic>{
      'url':
          'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-VC-WIN32.tar.gz',
      'sha256':
          'e7f117063d744858e05adc5d70544eeb9ab436647315c006efee0c67859084af',
    },
    'x64': <String, dynamic>{
      'url':
          'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-VC-WIN64A.tar.gz',
      'sha256':
          'fb7525dd6cbfa9ada1951bb064e54db0ccfc78d75d82e93109e83fd5513bebbf',
    },
  },
  'linux': <String, dynamic>{
    'arm': <String, dynamic>{
      'url':
          'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-linux-armv4.tar.gz',
      'sha256':
          'be449d8eae49a4b9752251a387b8c3a5617e5acca0b07ba355501efc2409f609',
    },
    'arm64': <String, dynamic>{
      'url':
          'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-linux-aarch64.tar.gz',
      'sha256':
          '869866975f7eeba1504ea7bb720092d73cd8622878ca7bdf049a4104cb7d6ea6',
    },
    'ia32': <String, dynamic>{
      'url':
          'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-linux-x86.tar.gz',
      'sha256':
          '7d2d6b71441d892201a2fc7abe863b335dfc972e69e5c5caa36df56587fab2d4',
    },
    'x64': <String, dynamic>{
      'url':
          'https://github.com/invictus-dart/openssl/releases/download/v3.5.9/openssl-3.5.9-linux-x86_64.tar.gz',
      'sha256':
          '4b5d6a835e10b847cf1a2478ae52993af94d03cc8f06dac6c583e4ddc6c1bbf4',
    },
  },
};

class OpensslBuilder implements Builder {
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

    final targetOS = input.config.code.targetOS;
    final targetSdk = targetOS == .iOS ? input.config.code.iOS.targetSdk : null;
    final targetArchitecture = input.config.code.targetArchitecture;
    final userDefines = input.userDefines.getValue('openssl', _userDefines);

    final outDir = input.outputDirectory.resolve('openssl/out/');
    await fileSystem.directory(outDir).create(recursive: true);

    final target = switch (targetOS) {
      .android => switch (targetArchitecture) {
        .arm => userDefines['android']['arm'] as Map<String, dynamic>,
        .arm64 => userDefines['android']['arm64'] as Map<String, dynamic>,
        .ia32 => userDefines['android']['ia32'] as Map<String, dynamic>,
        .x64 => userDefines['android']['x64'] as Map<String, dynamic>,
        _ => throw UnsupportedError(
          'Unsupported architecture: $targetArchitecture',
        ),
      },
      .iOS => switch (targetSdk) {
        .iPhoneSimulator => switch (targetArchitecture) {
          .arm64 =>
            userDefines['ios']['simulator']['arm64'] as Map<String, dynamic>,
          .x64 =>
            userDefines['ios']['simulator']['x64'] as Map<String, dynamic>,
          _ => throw UnsupportedError(
            'Unsupported architecture: $targetArchitecture',
          ),
        },
        .iPhoneOS => switch (targetArchitecture) {
          .arm64 =>
            userDefines['ios']['device']['arm64'] as Map<String, dynamic>,
          _ => throw UnsupportedError(
            'Unsupported architecture: $targetArchitecture',
          ),
        },
        _ => throw UnsupportedError('Unsupported sdk: $targetSdk'),
      },
      .macOS => switch (targetArchitecture) {
        .arm64 => userDefines['macos']['arm64'] as Map<String, dynamic>,
        .x64 => userDefines['macos']['x64'] as Map<String, dynamic>,
        _ => throw UnsupportedError(
          'Unsupported architecture: $targetArchitecture',
        ),
      },
      .windows => switch (targetArchitecture) {
        .arm64 => userDefines['windows']['arm64'] as Map<String, dynamic>,
        .ia32 => userDefines['windows']['ia32'] as Map<String, dynamic>,
        .x64 => userDefines['windows']['x64'] as Map<String, dynamic>,
        _ => throw UnsupportedError(
          'Unsupported architecture: $targetArchitecture',
        ),
      },
      .linux => switch (targetArchitecture) {
        .arm => userDefines['linux']['arm'] as Map<String, dynamic>,
        .arm64 => userDefines['linux']['arm64'] as Map<String, dynamic>,
        .ia32 => userDefines['linux']['ia32'] as Map<String, dynamic>,
        .x64 => userDefines['linux']['x64'] as Map<String, dynamic>,
        _ => throw UnsupportedError(
          'Unsupported architecture: $targetArchitecture',
        ),
      },
      _ => throw UnsupportedError('Unsupported os: $targetOS'),
    };

    final url = target['url'] as String;
    final sha256 = target['sha256'] as String;

    final builder = DownloadBuilder.tgz(
      url: url,
      sha256: sha256,
      dir: outDir,
      stripComponents: 1,
    );
    await builder.run(input: input, output: output);

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
              'lib/${targetOS.libraryFileName(library, linkMode)}',
            ),
          ),
        ),
        routing: ToLinkHook(input.packageName),
      );
    }
  }
}
