// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to invoke the native C compiler installed on the host machine.
library;

export 'src/cbuilder/build_mode.dart';
export 'src/cbuilder/cbuilder.dart' show CBuilder;
export 'src/cbuilder/clibrary.dart' show CLibrary;
export 'src/cbuilder/clinker.dart' show CLinker;
export 'src/cbuilder/language.dart' show Language;
export 'src/cbuilder/linker_options.dart' show LinkerOptions;
export 'src/cbuilder/optimization_level.dart';
export 'src/cbuilder/output_type.dart' show OutputType;
export 'src/utils/env_from_bat.dart';

export 'src/cbuilder/compiler_resolver.dart';
export 'src/tool/tool.dart';
export 'src/tool/tool_error.dart';
export 'src/tool/tool_instance.dart';
export 'src/tool/tool_requirement.dart';
export 'src/tool/tool_resolver.dart';
export 'src/utils/run_process.dart';
export 'src/xbuilder/cmake_builder.dart';
export 'src/xbuilder/logger.dart';
export 'src/xbuilder/repository_builder.dart';
export 'src/xbuilder/tools.dart';
export 'src/xbuilder/user_defines.dart';
