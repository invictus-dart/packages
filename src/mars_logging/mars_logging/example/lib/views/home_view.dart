import 'package:clover/clover.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:mars_logging_example/view_models.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModel.of<HomeViewModel>(context);
    final levels = viewModel.levels;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('mars_logging'),
        trailing: CupertinoButton(
          onPressed: () => context.go('/logs'),
          child: const Icon(CupertinoIcons.tray),
        ),
      ),
      child: Column(
        mainAxisSize: .max,
        mainAxisAlignment: .center,
        crossAxisAlignment: .stretch,
        children: levels
            .map(
              (level) => CupertinoButton(
                child: Text(level.name),
                onPressed: () {
                  viewModel.log(level);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}
