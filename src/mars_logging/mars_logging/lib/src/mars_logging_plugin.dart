import 'package:mars_logging_api/mars_logging_api.dart';

import 'xlog_impl.dart';

abstract final class MarsLoggingPlugin {
  static void registerWith() {
    XLogApi.instance = XLogImpl();
  }
}
