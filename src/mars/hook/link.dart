import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:mars/src/hook/util.dart';
import 'package:native_toolchain_x/native_toolchain_x.dart';
import 'package:record_use/record_use.dart';

void main(List<String> arguments) async {
  await link(arguments, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final treeShake = input.userDefines.getValue('tree_shake', true);

    final linker = CLinker.library(
      name: 'mars',
      assetName: 'src/mars_bindings_generated.dart',
      sources: input.assets.code
          .map(
            (asset) =>
                ArgumentError.checkNotNull(asset.file, 'file').toFilePath(),
          )
          .toList(),
      frameworks: frameworks,
      libraries: getSystemLibraries(input.config.code.targetOS),
    );
    await linker.run(
      input: input,
      output: output,
      linkerOptions: treeShake
          ? LinkerOptions.treeshake(
              symbolsToKeep: input.recordedUses?.calls.keys.cast<Method>().map(
                (e) => e.name,
              ),
            )
          : null,
    );
  });
}
