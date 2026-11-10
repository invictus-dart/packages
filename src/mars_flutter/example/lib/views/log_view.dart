import 'package:clover/clover.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mars_flutter/mars_flutter.dart';

import '../view_models.dart';

class LogView extends StatelessWidget {
  const LogView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModel.of<LogViewModel>(context);
    final logName = viewModel.logName;
    final logPath = viewModel.logPath;
    return Scaffold(
      appBar: AppBar(title: Text(logName)),
      body: SafeArea(
        child: SelectableRegion(
          selectionControls: MaterialTextSelectionControls(),
          child: XlogView(
            filePath: logPath,
            privKey: 'c030b50a82ac27f2b14b63781a4a18fe22d92ca456636d5401743fb375aefafe',
            padding: EdgeInsets.all(16.0),
            loadingBuilder: (context) =>
                Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}
