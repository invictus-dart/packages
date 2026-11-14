import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:mars/mars.dart';

Widget _defaultLoadingBuilder(BuildContext context) => Offstage();

Widget _defaultEmptyBuilder(BuildContext context) => Offstage();

class XlogView extends StatefulWidget {
  final String filePath;
  final String privKey;
  final EdgeInsets? padding;
  final TextStyle? style;
  final WidgetBuilder loadingBuilder;
  final WidgetBuilder emptyBuilder;

  const XlogView({
    super.key,
    required this.filePath,
    this.privKey = '',
    this.padding,
    this.style,
    this.loadingBuilder = _defaultLoadingBuilder,
    this.emptyBuilder = _defaultEmptyBuilder,
  });

  @override
  State<XlogView> createState() => _XlogViewState();
}

class _XlogViewState extends State<XlogView> {
  late final ValueNotifier<List<String>?> lines;
  late final ValueNotifier<bool> isLoading;

  @override
  void initState() {
    super.initState();
    lines = ValueNotifier(null);
    isLoading = ValueNotifier(false);
    _load();
  }

  @override
  void didUpdateWidget(covariant XlogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filePath != oldWidget.filePath ||
        widget.privKey != oldWidget.privKey) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    return ListenableBuilder(
      listenable: Listenable.merge([lines, isLoading]),
      builder: (context, child) {
        final lines = this.lines.value;
        final isLoading = this.isLoading.value;
        if (isLoading) {
          return widget.loadingBuilder(context);
        } else if (lines == null || lines.isEmpty) {
          return widget.emptyBuilder(context);
        } else {
          return ListView.builder(
            padding: widget.padding,
            itemBuilder: (context, index) {
              final line = lines[index];
              return Text(line, style: style);
            },
            itemCount: lines.length,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    lines.dispose();
    isLoading.dispose();
    super.dispose();
  }

  void _load() async {
    isLoading.value = true;
    try {
      final file = File(widget.filePath);
      final input = await file.readAsBytes();
      final output = await xlog.decode(input, privKey: widget.privKey);
      final stream = Stream<List<int>>.value(output);
      final lineSplitter = LineSplitter();
      lines.value = await stream
          .transform(utf8.decoder)
          .transform(lineSplitter)
          .toList();
    } catch (e) {
      debugPrint('load failed: $e');
      lines.value = null;
    } finally {
      isLoading.value = false;
    }
  }
}
