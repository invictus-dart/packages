import 'package:hooks/hooks.dart';
import 'package:native_toolchain_zeekr/native_toolchain_zeekr.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final srcDir = input.outputDirectoryShared.resolve('src/');
    final dstDir = input.outputDirectory.resolve('dst/');
    final outDir = input.outputDirectory.resolve('out/');
    await RepositoryBuilder.git(
      url: 'https://github.com/facebook/zstd.git',
      refspec: 'v1.5.7',
      dir: srcDir,
    ).run(input: input, output: output);
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
      name: input.packageName,
      assetName: 'src/zstd.g.dart',
    ).run(input: input, output: output);
  });
}
