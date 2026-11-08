import 'dart:io';

import 'package:ffigen/ffigen.dart';

void main(List<String> args) async {
  final rootUri = Platform.script.resolve('../');
  final generator = FfiGenerator(
    input: Input(
      entryPoints: [
        rootUri.resolve('src/include/zdict.h'),
        rootUri.resolve('src/include/zstd_errors.h'),
        rootUri.resolve('src/include/zstd.h'),
      ],
      include: (header) =>
          header.path.endsWith('zdict.h') ||
          header.path.endsWith('zstd_errors.h') ||
          header.path.endsWith('zstd.h'),
    ),
    output: Output(
      dart: DartOutput(
        path: rootUri.resolve('lib/src/zstd_bindings_generated.dart'),
      ),
      recordUseMapping: rootUri.resolve('lib/src/zstd_record_use_mapping.dart'),
    ),
    visitors: [
      Visitor(
        func: (node) => node.recordUse = node.isIncluded = true,
        struct: (node) => node.isIncluded = true,
        union: (node) => node.isIncluded = true,
        enumClass: (node) => node
          ..isIncluded = true
          ..silenceWarning = true,
        global: (node) => node.isIncluded = true,
        macroConstant: (node) => node.isIncluded = true,
        typealias: (node) => node.isIncluded = .ifUsed,
      ),
    ],
  );
  await generator.generate();
}
