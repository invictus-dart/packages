import 'package:hooks/hooks.dart';

extension HookInputUserDefinesExt on HookInputUserDefines {
  T getValue<T>(String key, T defaultValue) {
    final value = this[key];
    return value is T && value != null ? value : defaultValue;
  }
}
