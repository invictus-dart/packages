import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:record_use/record_use.dart';

import 'util.dart';

void main(List<String> arguments) async {
  await link(arguments, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final targetOS = input.config.code.targetOS;
    final targetArchitecture = input.config.code.targetArchitecture;
    final targetSdk = targetOS == .iOS ? input.config.code.iOS.targetSdk : null;

    final linker = CLinker.library(
      name: 'mars',
      assetName: 'src/mars.g.dart',
      sources: input.assets.code
          .map(
            (asset) =>
                ArgumentError.checkNotNull(asset.file, 'file').toFilePath(),
          )
          .toList(),
      frameworks: frameworks,
      libraries: [
        ...getSystemLibraries(targetOS),
        ...getOpensslLibraries(targetOS),
      ],
      libraryDirectories: [
        '.',
        getOpensslLibraryDirectory(
          input.packageRoot,
          targetOS,
          targetArchitecture,
          targetSdk,
        ),
      ],
    );
    await linker.run(
      input: input,
      output: output,
      linkerOptions: LinkerOptions.treeshake(
        symbolsToKeep: input.recordedUses?.calls.keys.cast<Method>().map(
          (e) => e.name,
        ),
      ),
    );
  });
}
