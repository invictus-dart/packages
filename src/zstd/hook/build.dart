import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_x/native_toolchain_x.dart';

String get _url =>
    'https://github.com/meta/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz';
String get _sha256 =>
    'eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final url = input.userDefines.getValue('url', _url);
    final sha256 = input.userDefines.getValue('sha256', _sha256);

    final targetOS = input.config.code.targetOS;

    final tgzName = Uri.parse(url).pathSegments.last;
    // TODO: The source directory name is inferred by stripping a hardcoded
    // `.tar.gz` (7-char) suffix from the URL file name. This relies on the
    // GitHub release tarball convention `<repo>-<tag>/` and breaks for other
    // suffixes such as `.tgz` supplied via user defines. Derive the root
    // directory from the extracted archive instead: use the single child
    // directory of the extraction directory, or read the first tar entry name.
    final tgzDirectory = tgzName.substring(0, tgzName.length - 7);
    final srcDir = input.outputDirectoryShared.resolve('$tgzDirectory/');
    final outDir = input.outputDirectory.resolve('out/');

    // 1. Get repository
    final repositoryPart = RepositoryBuilder.tgz(url: url, sha256: sha256);
    await repositoryPart.run(input: input, output: output);
    final builder = CMakeBuilder(
      srcDir: srcDir,
      subDir: 'build/cmake/',
      variables: input.config.linkingEnabled
          ? {
              'BUILD_SHARED_LIBS': 'OFF',
              'ZSTD_BUILD_PROGRAMS': 'OFF',
              'ZSTD_BUILD_SHARED': 'OFF',
              'ZSTD_BUILD_STATIC': 'ON',
            }
          : {
              'BUILD_SHARED_LIBS': 'ON',
              'ZSTD_BUILD_PROGRAMS': 'OFF',
              'ZSTD_BUILD_SHARED': 'ON',
              'ZSTD_BUILD_STATIC': 'OFF',
            },
    );
    await builder.run(input: input, output: output);
    // 3. Add code asset
    final linkMode = input.config.linkingEnabled
        ? StaticLinking()
        : DynamicLoadingBundled();
    final libraryName = targetOS == .windows && input.config.linkingEnabled
        ? 'zstd_static'
        : 'zstd';
    final assetDirectoryName = targetOS.libraryDirectoryName(linkMode);
    final assetName = targetOS.libraryFileName(libraryName, linkMode);
    final asset = CodeAsset(
      package: input.packageName,
      name: 'src/zstd_bindings_generated.dart',
      linkMode: linkMode,
      file: outDir.resolve('$assetDirectoryName/$assetName'),
    );
    output.assets.code.add(
      asset,
      routing: input.config.linkingEnabled
          ? ToLinkHook(input.packageName)
          : ToAppBundle(),
    );
  });
}

extension on OS {
  String libraryDirectoryName(LinkMode linkMode) => switch (this) {
    .android => 'lib',
    .iOS => 'lib',
    .macOS => 'lib',
    .windows => linkMode is DynamicLoadingBundled ? 'bin' : 'lib',
    .linux => 'lib',
    _ => throw UnsupportedError('$this is not supported'),
  };
}
