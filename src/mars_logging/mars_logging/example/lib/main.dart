import 'dart:async';

import 'package:clover/clover.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:mars_logging/mars_logging.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path;

import 'view_models.dart';
import 'views.dart';

void main() {
  runZonedGuarded(onStartUp, onUncaughtError);
}

void onStartUp() async {
  WidgetsFlutterBinding.ensureInitialized();
  final filesDir = await path.getApplicationSupportDirectory();
  await XLog.open(
    mode: .async,
    level: kDebugMode ? .debug : .info,
    logsDir: path.join(filesDir.path, 'logs'),
    cacheDir: path.join(filesDir.path, 'cache'),
    cacheDays: 0,
    namePrefix: 'log',
    compressMode: .zstd,
    compressLevel: .level6,
    pubKey: 'f3d382d0bd7e33356d8dc497e1f4b3f93f8d4f96d0fdddda66e4eaf9abb50564ce356990d7af20a47cccfb8c3e4b9070c9a56fad0ffd07d0114238b950a36abc',
    useConsole: kDebugMode,
    maxFileSize: 10 * 1024 * 1024,
    maxAliveDuration: 30 * 24 * 60 * 60,
  );
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(XLog.onRecord);
  runApp(MyApp());
}

void onUncaughtError(Object error, StackTrace stackTrace) {
  Logger.root.shout('Uncaught error', error, stackTrace);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter routerConfig;

  @override
  void initState() {
    super.initState();
    routerConfig = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ViewModelBinding(
            viewBuilder: () => const HomeView(),
            viewModelBuilder: () => HomeViewModel(),
          ),
          routes: [
            GoRoute(
              path: 'logs',
              builder: (context, state) => ViewModelBinding(
                viewBuilder: () => const LogsView(),
                viewModelBuilder: () => LogsViewModel(),
              ),
              routes: [
                GoRoute(
                  path: ':logPath',
                  builder: (context, state) => ViewModelBinding(
                    viewBuilder: () => const LogView(),
                    viewModelBuilder: () {
                      final logPath = ArgumentError.checkNotNull(
                        state.pathParameters['logPath'],
                        'logPath',
                      );
                      return LogViewModel(logPath);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp.router(routerConfig: routerConfig);
  }

  @override
  void dispose() {
    routerConfig.dispose();
    super.dispose();
  }
}
