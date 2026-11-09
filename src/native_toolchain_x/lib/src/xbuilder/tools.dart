import '../tool/tool.dart';
import '../tool/tool_instance.dart';
import '../tool/tool_resolver.dart';

abstract final class Tools {
  static Tool get tar => Tool(
    name: 'Tar',
    defaultResolver: CliVersionResolver(
      wrappedResolver: PathToolResolver(toolName: 'Tar', executableName: 'tar'),
    ),
  );

  static Tool get git => Tool(
    name: 'Git',
    defaultResolver: CliVersionResolver(
      wrappedResolver: PathToolResolver(toolName: 'Git', executableName: 'git'),
    ),
  );

  static Tool get cmake => Tool(
    name: 'CMake',
    defaultResolver: CliVersionResolver(
      wrappedResolver: PathToolResolver(
        toolName: 'CMake',
        executableName: 'cmake',
      ),
    ),
  );

  static Tool get perl => Tool(
    name: 'Perl',
    defaultResolver: CliVersionResolver(
      wrappedResolver: PathToolResolver(
        toolName: 'Perl',
        executableName: 'perl',
      ),
    ),
  );

  static Tool get nasm => Tool(
    name: 'NASM',
    defaultResolver: CliVersionResolver(
      wrappedResolver: PathToolResolver(
        toolName: 'NASM',
        executableName: 'nasm',
      ),
    ),
  );

  static Tool get make => Tool(
    name: 'Make',
    defaultResolver: CliVersionResolver(
      wrappedResolver: PathToolResolver(
        toolName: 'Make',
        executableName: 'make',
      ),
    ),
  );
}

extension ToolExt on Tool {
  Future<ToolInstance> resolve(ToolResolvingContext context) async {
    final resolver = ArgumentError.checkNotNull(defaultResolver, 'resolver');
    final toolInstances = await resolver.resolve(context);
    final toolInstance = toolInstances.firstWhere((e) => e.tool == this);
    return toolInstance;
  }
}
