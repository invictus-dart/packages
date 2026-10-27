import 'package:flutter/material.dart';
import 'package:mars/src/mars.g.dart';

void main() {
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
    // Keep a few FFI bindings alive so the record_use compiler pass records
    // them; the link hook then treeshakes the dylib to only these symbols.
    mars_xlog_xlogger_set_level(MarsLogLevel.kMarsLogLevelInfo.value);
    mars_xlog_xlogger_level();
    mars_xlog_appender_close();
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
