import 'package:clover/clover.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:go_router/go_router.dart';

import '../view_models.dart';

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
          child: const Icon(CupertinoIcons.ant),
        ),
      ),
      child: ListView.builder(
        itemBuilder: (context, index) {
          final level = levels[index];
          return CupertinoListTile(
            title: Text(level.name),
            onTap: () {
              viewModel.log(level);
            },
          );
        },
        itemCount: levels.length,
      ),
    );
  }
}
