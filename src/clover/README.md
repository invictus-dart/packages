# clover

[![pub package](https://img.shields.io/pub/v/clover.svg)](https://pub.dev/packages/clover)

A lightweight MVVM framework for Flutter. It provides a `ViewModel` base
class and a `ViewModelBinding` widget that bind a view to its view model
and rebuild the view when the view model notifies changes.

## Features

- `ViewModel` — a `ChangeNotifier` base class with `context` and `mounted`
  access, plus lifecycle forwarding from the hosting State
  (`didChangeDependencies`, `activate`, `deactivate`, `reassemble`).
- `ViewModelBinding` — creates and holds the view model, exposes it to the
  view through an `InheritedNotifier`, and rebuilds the view on
  `notifyListeners`.
- `ViewModel.of<T>(context)` — obtains the closest ancestor view model of
  type `T` and subscribes the calling widget to its changes.
- `InheritedViewModel` — wraps an existing view model in an inherited widget
  for advanced setups where the view model is created outside a binding.

## Usage

Define a view model by extending `ViewModel` and notifying listeners on
changes:

```dart
import 'package:clover/clover.dart';

class CounterViewModel extends ViewModel {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}
```

Consume it in a view with `ViewModel.of`, and bind the two together with
`ViewModelBinding`:

```dart
import 'package:clover/clover.dart';

class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModel.of<CounterViewModel>(context);
    return Text('Count: ${viewModel.count}');
  }
}

ViewModelBinding(
  viewBuilder: () => const CounterView(),
  viewModelBuilder: () => CounterViewModel(),
);
```

The binding creates the view model in `initState` and disposes it when the
binding is unmounted. While mounted, the view model also receives the
hosting State's lifecycle events and can access `context` to use
`Theme.of`, `Navigator`, and other inherited APIs.

## Example

A complete counter app is available in [`example/`](example/).

## Bugs and feedback

Please file issues in the
[bug tracker](https://github.com/invictus-dart/packages/issues).
