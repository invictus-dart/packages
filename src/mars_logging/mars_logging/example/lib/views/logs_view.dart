import 'package:clover/clover.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:mars_logging_example/view_models.dart';
import 'package:path/path.dart' as path;

class LogsView extends StatelessWidget {
  const LogsView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModel.of<LogsViewModel>(context);
    final logs = viewModel.logs;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Logs'),
        trailing: CupertinoButton(
          onPressed: () async {
            final log = await viewModel.openLog();
            if (log == null || !context.mounted) return;
            final logPath = log.path;
            context.go('/logs/${Uri.encodeComponent(logPath)}');
          },
          child: Icon(CupertinoIcons.folder),
        ),
      ),
      child: ListView.builder(
        itemBuilder: (context, index) {
          final log = logs[index];
          final logPath = log.path;
          final title = path.basenameWithoutExtension(logPath);
          return CupertinoListTile(
            title: Text(title),
            onTap: () {
              context.go('/logs/${Uri.encodeComponent(logPath)}');
            },
          );
        },
        itemCount: logs.length,
      ),
    );
  }
}
