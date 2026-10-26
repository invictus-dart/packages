// Regenerates the Dart FFI bindings from src/mars.h.
//
// Usage:
//   dart run tool/ffigen.dart
//
// The ffigen configuration (formerly `ffigen.yaml`) is kept here so the
// binding generator and its config live in one place. See
// https://pub.dev/packages/ffigen for the programmatic configuration API
// (the YAML format is deprecated; this script is the recommended form).
//
// Generated output: lib/mars_bindings_generated.dart

import 'dart:io';

import 'package:ffigen/ffigen.dart';

Future<void> main() async {
  // Package root, resolved from the script location so the generator works
  // regardless of the current working directory.
  final packageRoot = Platform.script.resolve('../');

  final generator = FfiGenerator(
    input: Input(
      // Same entry-point as the old `headers.entry-points: [src/mars.h]`.
      // Resolve to an absolute URI: ffigen passes entry points to clang
      // verbatim, and clang must be able to open the header.
      entryPoints: [packageRoot.resolve('src/mars.h')],
      // Same as the old `headers.include-directives: [src/mars.h]`: only
      // keep declarations coming from the bridge header itself.
      include: (header) => header.path.endsWith('/src/mars.h'),
    ),
    output: Output(
      dart: DartOutput(
        path: packageRoot.resolve('lib/mars_bindings_generated.dart'),
      ),
      // Same as the old `comments: {style: any, length: full}`.
      commentType: const CommentType(CommentStyle.any, CommentLength.full),
      // Same as the old `ffi-native:`: emit @ffi.Native externs, resolved
      // through the build hook's code assets.
      style: const NativeExternalBindings(),
    ),
    visitors: [
      // The legacy YAML configuration included every top-level declaration
      // by default; the programmatic API excludes them by default, so mark
      // all top-level kinds as included to preserve that behavior.
      Visitor(
        func: (node) => node.isIncluded = true,
        enumClass: (node) => node.isIncluded = true,
        unnamedEnumConstant: (node) => node.isIncluded = true,
        struct: (node) => node.isIncluded = true,
        union: (node) => node.isIncluded = true,
        global: (node) => node.isIncluded = true,
      ),
    ],
  );
  await generator.generate();
}
