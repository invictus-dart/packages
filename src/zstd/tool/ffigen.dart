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
    ),
    visitors: [
      Visitor(
        func: (node) => node.isIncluded = node.originalName.startsWith('ZSTD_'),
        struct: (node) =>
            node.isIncluded = node.originalName.startsWith('ZSTD_'),
        union: (node) =>
            node.isIncluded = node.originalName.startsWith('ZSTD_'),
        enumClass: (node) => node
          ..isIncluded = node.originalName.startsWith('ZSTD_')
          ..silenceWarning = true,
        global: (node) =>
            node.isIncluded = node.originalName.startsWith('ZSTD_'),
        macroConstant: (node) =>
            node.isIncluded = node.originalName.startsWith('ZSTD_'),
        typealias: (node) => node.originalName.startsWith('ZSTD_')
            ? node.isIncluded = .ifUsed
            : node.isIncluded = .never,
      ),
    ],
  );
  await generator.generate();
}
