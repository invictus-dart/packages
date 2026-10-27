// Link hook: applies treeshake to the Mars dynamic library produced by the
// build hook. The dynamic library is already fully linked in build.dart; this
// step only removes unused symbols. On Windows this is not possible (MSVC
// cannot relink an already-linked DLL as input), so the DLL is passed through
// unchanged, matching upstream mars which does not strip exports on Windows.

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:record_use/record_use.dart';

void main(List<String> args) async {
  await link(args, (input, output) async {
    final asset = input.assets.code.single;
    final targetOS = input.config.code.targetOS;
    if (targetOS == OS.windows) {
      // Windows: the build hook already produced the final DLL, and cl.exe/link
      // cannot take that DLL as input for relinking (fails with LNK1107).
      // Upstream mars does not strip exports on Windows either, so pass the
      // build-hook output through unchanged.
      output.assets.code.add(
        CodeAsset(
          package: asset.id.split('/').first.replaceAll('package:', ''),
          name: asset.id.split('/').skip(1).join('/'),
          linkMode: asset.linkMode,
          file: asset.file,
        ),
      );
      return;
    }
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
