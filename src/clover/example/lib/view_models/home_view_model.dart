import 'package:clover/clover.dart';
import 'package:flutter/widgets.dart';

/// The home view model.
class HomeViewModel extends ViewModel {
  final String _title;
  int _count;

  HomeViewModel() : _title = 'Home View', _count = 0;

  /// Get the title.
  String get title => _title;

  /// Get the count listenable.
  int get count => _count;

  /// Increase the count.
  void increase() {
    _count++;
    notifyListeners();
  }

  /// Decrease the count.
  void decrease() {
    _count--;
    notifyListeners();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('didChangeDependencies');
  }

  @override
  void activate() {
    super.activate();
    debugPrint('activate');
  }

  @override
  void deactivate() {
    super.deactivate();
    debugPrint('deactivate');
  }

  @override
  void reassemble() {
    super.reassemble();
    debugPrint('reassemble');
  }

  @override
  void dispose() {
    debugPrint('dispose');
    super.dispose();
  }
}
