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
// Generated output: lib/src/mars.g.dart

import 'dart:io';

import 'package:ffigen/ffigen.dart';

Future<void> main() async {
  final rootUri = Platform.script.resolve('../');
  final generator = FfiGenerator(
    input: Input(
      entryPoints: [rootUri.resolve('src/mars.h')],
      include: (header) => header.path.endsWith('mars.h'),
    ),
    output: Output(
      dart: DartOutput(path: rootUri.resolve('lib/src/mars.g.dart')),
      // Generates lib/src/mars_record_use_mapping.dart, a Dart-name to
      // native-symbol mapping consumed by hook/link.dart for treeshaking.
      recordUseMapping: rootUri.resolve('lib/src/mars_record_use_mapping.dart'),
    ),
    visitors: [
      Visitor(
        func: (node) {
          node.isIncluded = true;
          // Annotate every generated binding with @RecordUse() so the
          // compiler records actual call sites (input.recordedUses in the
          // link hook) and link.dart can treeshake unused symbols.
          node.recordUse = true;
        },
        struct: (node) => node.isIncluded = true,
        union: (node) => node.isIncluded = true,
        enumClass: (node) => node.isIncluded = true,
        global: (node) => node.isIncluded = true,
        macroConstant: (node) => node.isIncluded = true,
        typealias: (node) => node.isIncluded = .ifUsed,
      ),
    ],
  );
  await generator.generate();
}
