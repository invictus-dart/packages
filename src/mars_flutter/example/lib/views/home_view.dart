import 'package:clover/clover.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../view_models.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModel.of<HomeViewModel>(context);
    final levels = viewModel.levels;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mars'),
        actions: [
          IconButton(
            onPressed: () => context.go('/logs'),
            icon: const Icon(Icons.adb),
          ),
        ],
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          final level = levels[index];
          return ListTile(
            title: Text(level.name),
            onTap: () => viewModel.log(level),
          );
        },
        itemCount: levels.length,
      ),
    );
  }
}
