import 'package:hooks/hooks.dart';

import 'libraries.dart';

void main(List<String> arguments) async {
  await build(arguments, (input, output) async {
    final libraryParts = getLibraryParts(input);
    final library = getLibrary(input);

    for (final libraryPart in libraryParts) {
      await libraryPart.build(
        input: input,
        output: output,
        linkModePreference: .static,
      );
    }
    await library.build(input: input, output: output);
  });
}
