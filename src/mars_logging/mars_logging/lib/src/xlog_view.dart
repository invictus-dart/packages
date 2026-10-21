import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';

import 'xlog.dart';

Widget _defaultLoadingBuilder(BuildContext context) {
  return Center(child: CircularProgressIndicator.adaptive());
}

Widget _defaultEmptyBuilder(BuildContext context) {
  return Offstage();
}

class XLogView extends StatefulWidget {
  final String xlogPath;
  final String privKey;
  final TextStyle? style;
  final EdgeInsets? padding;
  final WidgetBuilder loadingBuilder;
  final WidgetBuilder emtpyBuilder;

  const XLogView({
    super.key,
    required this.xlogPath,
    this.privKey = '',
    this.style,
    this.padding,
    this.emtpyBuilder = _defaultEmptyBuilder,
    this.loadingBuilder = _defaultLoadingBuilder,
  });

  @override
  State<XLogView> createState() => _XLogViewState();
}

class _XLogViewState extends State<XLogView> {
  late final ValueNotifier<List<String>?> lines;
  late final ValueNotifier<bool> isLoading;

  @override
  void initState() {
    super.initState();
    lines = ValueNotifier(null);
    isLoading = ValueNotifier(false);
    _loadLines();
  }

  @override
  void didUpdateWidget(covariant XLogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.xlogPath != oldWidget.xlogPath ||
        widget.privKey != oldWidget.privKey) {
      _loadLines();
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
          return widget.emtpyBuilder(context);
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

  void _loadLines() async {
    isLoading.value = true;
    try {
      final xlog = XFile(widget.xlogPath);
      final xlogBytes = await xlog.readAsBytes();
      final logBytes = await XLog.decode(xlogBytes, privKey: widget.privKey);
      final logStream = Stream<List<int>>.value(logBytes);
      final lineSplitter = LineSplitter();
      lines.value =
          await logStream
              .transform(utf8.decoder)
              .transform(lineSplitter)
              .toList();
    } catch (e) {
      lines.value = null;
    } finally {
      isLoading.value = false;
    }
  }
}
