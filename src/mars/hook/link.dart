import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:record_use/record_use.dart';

import 'libraries.dart';

void main(List<String> arguments) async {
  await link(arguments, (input, output) async {
    final library = getLibrary(input);
    await library.link(
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
