import 'package:flutter/material.dart';
import 'package:xlist/pages/alist/models/log.dart';
import 'package:xlist/pages/alist/models/log_level.dart';

/// 日志列表
class LogListView extends StatefulWidget {
  const LogListView({super.key, required this.logs, this.controller});

  final List<Log> logs;
  final ScrollController? controller;

  @override
  State<LogListView> createState() => _LogListViewState();
}

class _LogListViewState extends State<LogListView> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.logs.length,
      controller: widget.controller,
      itemBuilder: (context, index) {
        final log = widget.logs[index];
        return ListTile(
          dense: true,
          title: SelectableText(log.content),
          subtitle: SelectableText(log.time),
          leading: LogLevelView(level: log.level),
        );
      },
    );
  }
}

// 日志项
class LogLevelView extends StatefulWidget {
  final int level;

  const LogLevelView({super.key, required this.level});

  @override
  State<LogLevelView> createState() => _LogLevelViewState();
}

class _LogLevelViewState extends State<LogLevelView> {
  @override
  Widget build(BuildContext context) {
    final s = LogLevel.toStr(widget.level);
    final c = LogLevel.toColor(widget.level);
    return Text(s, style: TextStyle(color: c));
  }
}
