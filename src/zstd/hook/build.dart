import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_zeekr/native_toolchain_zeekr.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final srcDir = input.outputDirectoryShared.resolve('src/');
    final dstDir = input.outputDirectory.resolve('dst/');
    final outDir = input.outputDirectory.resolve('out/');
    // 1. Clone repository
    await RepositoryBuilder.git(
      url: 'https://github.com/facebook/zstd.git',
      refspec: 'v1.5.7',
      dir: srcDir,
    ).run(input: input, output: output);
    // 2. Compile dynamic library
    await CMakeBuilder(
      srcDir: srcDir,
      subDir: 'build/cmake/',
      dstDir: dstDir,
      outDir: outDir,
      variables: {
        'BUILD_SHARED_LIBS': 'ON',
        'ZSTD_BUILD_PROGRAMS': 'OFF',
        'ZSTD_BUILD_STATIC': 'OFF',
        'ZSTD_BUILD_SHARED': 'ON',
      },
    ).run(input: input, output: output);
    // 3. Add code asset
    final linkMode = DynamicLoadingBundled();
    final libraryDirName = input.config.code.targetOS.libraryDirectoryName(
      linkMode,
    );
    final libraryName = input.config.code.targetOS.libraryFileName(
      'zstd',
      linkMode,
    );
    final libraryAsset = CodeAsset(
      package: input.packageName,
      name: 'src/zstd.g.dart',
      linkMode: linkMode,
      file: outDir.resolve('$libraryDirName/$libraryName'),
    );
    output.assets.code.add(libraryAsset);
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
