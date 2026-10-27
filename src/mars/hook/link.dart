// Link hook: applies treeshake to the Mars dynamic library produced by the
// build hook. The dynamic library is already fully linked in build.dart; this
// step only removes unused symbols.

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:record_use/record_use.dart';

void main(List<String> args) async {
  await link(args, (input, output) async {
    final asset = input.assets.code.single;
    final builder = CLinker.library(
      name: asset.id.split('/').first.replaceAll('package:', ''),
      assetName: asset.id.split('/').skip(1).join('/'),
      sources: [
        ArgumentError.checkNotNull(asset.file, 'asset.file').toFilePath(),
      ],
      linkerOptions: LinkerOptions.treeshake(
        symbolsToKeep: input.recordedUses?.calls.keys.cast<Method>().map(
          (e) => e.name,
        ),
      ),
    );
    await builder.run(input: input, output: output);
  });
}
