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
        // TODO(jni-treeshake): JNI 符号（JNI_OnLoad / JNI_OnUnload /
        // ImportLibs / Export* / Java_com_tencent_mars_*）目前不在 Dart
        // recordedUses 里，会被 treeshake 生成的精确白名单 version-script
        // 裁掉且不导出，导致 System.loadLibrary("mars") 不触发 JNI_OnLoad、
        // Java 静态注册不可用。后续二选一：
        //  1) 支持 JNI treeshake：枚举 keep 上述符号（native_toolchain_c
        //     0.19.5 的 symbolsToKeep 只支持精确名、不支持前缀通配），或改用
        //     LinkerOptions.manual(gcSections: false, symbolsToKeep: null)
        //     全符号导出（对齐上游 marsstn 无 version-script 的语义）。
        //  2) 通过 HookInput.userDefines 加开关（如 userDefines['jni']=true
        //     时保留 JNI 符号、false 时走纯 FFI treeshake），避免改 hook 代码。
        // 当前保持纯 FFI treeshake，不保留 JNI 符号。
        symbolsToKeep: input.recordedUses?.calls.keys.cast<Method>().map(
          (e) => e.name,
        ),
      ),
    );
  });
}
