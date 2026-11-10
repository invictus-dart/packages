import 'package:clover/clover.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;

import '../view_models.dart';

class LogsView extends StatelessWidget {
  const LogsView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModel.of<LogsViewModel>(context);
    final logs = viewModel.logs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            onPressed: () async {
              final log = await viewModel.openLog();
              if (log == null || !context.mounted) return;
              final logPath = log.path;
              context.go('/logs/${Uri.encodeComponent(logPath)}');
            },
            icon: Icon(Icons.folder),
          ),
        ],
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          final log = logs[index];
          final logPath = log.path;
          final title = path.basenameWithoutExtension(logPath);
          return ListTile(
            title: Text(title),
            onTap: () => context.go('/logs/${Uri.encodeComponent(logPath)}'),
          );
        },
        itemCount: logs.length,
      ),
    );
  }
}
