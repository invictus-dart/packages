import 'package:clover/clover.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:mars_flutter/mars_flutter.dart';

import '../view_models.dart';

class LogView extends StatelessWidget {
  const LogView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final viewModel = ViewModel.of<LogViewModel>(context);
    final logName = viewModel.logName;
    final logPath = viewModel.logPath;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(logName)),
      child: SafeArea(
        child: SelectableRegion(
          selectionControls:
              defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS
              ? CupertinoTextSelectionControls()
              : CupertinoDesktopTextSelectionControls(),
          child: XlogView(
            filePath: logPath,
            privKey: 'c030b50a82ac27f2b14b63781a4a18fe22d92ca456636d5401743fb375aefafe',
            style: theme.textTheme.textStyle.copyWith(fontSize: 14.0),
            padding: EdgeInsets.all(16.0),
            loadingBuilder: (context) => CupertinoActivityIndicator(),
          ),
        ),
      ),
    );
  }
}
