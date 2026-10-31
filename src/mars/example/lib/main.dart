import 'package:flutter/material.dart';
import 'package:mars/mars.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path;

void main() async {
  final filesDir = await path.getApplicationSupportDirectory();
  final logsDir = path.join(filesDir.path, 'logs');
  final cacheDir = path.join(logsDir, 'cache');
  Xlog.instance.open(logsDir: logsDir, cacheDir: cacheDir);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Xlog.instance.info('MyApp', 'INFO');
    Xlog.instance.flush(true);
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Mars (Native Assets)')),
        body: SingleChildScrollView(
          child: Container(
            padding: const .all(10),
            child: Column(
              children: [
                const Text(
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code is built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: .center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
