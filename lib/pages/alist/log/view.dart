import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xlist/common/utils.dart';
import 'package:xlist/generated/l10n.dart';
import 'package:xlist/generated_api.dart';
import 'package:xlist/pages/alist/alist/about_dialog.dart';
import 'package:xlist/pages/alist/alist/alist_controller.dart';
import 'package:xlist/pages/alist/widgets/pwd_edit_dialog.dart';
import 'package:xlist/pages/alist/app_update_dialog.dart';
import 'package:xlist/pages/alist/log/log_list_view.dart';
import 'package:xlist/pages/alist/log/logic.dart';

/// AList 日志页面
class AListLogPage extends StatefulWidget {
  const AListLogPage({super.key});

  @override
  State<AListLogPage> createState() => _AListLogPageState();
}

class _AListLogPageState extends State<AListLogPage> {
  final logic = Get.put(LogLogic());
  final ui = Get.find<AListController>();
  final ScrollController scrollController = ScrollController();
  Timer? timer;
  StreamSubscription? listen;

  @override
  void initState() {
    // 监听日志变更, 自动滚动到底部
    listen = ui.logs.listen((event) {
      if (timer != null) {
        timer!.cancel();
      }
      timer = Timer(const Duration(milliseconds: 1000), () {
        _scrollToBottom();
      });
    });

    // 在这里设置状态更新后的回调，确保滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    super.initState();
  }

  void _scrollToBottom() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: _buildNavigationBar(ui),
        // appBar: _buildAppBar(context, ui),
        child: Obx(() => LogListView(
              logs: ui.logs.value,
              controller: scrollController,
            )));
  }

  CupertinoNavigationBar _buildNavigationBar(AListController ui) {
    return CupertinoNavigationBar(
        backgroundColor: Get.theme.scaffoldBackgroundColor,
        border: Border.all(width: 0, color: Colors.transparent),
        leading: CommonUtils.backButton,
        middle: const Text(
          "日志",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          // 清空日志
          CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                ui.clearLog();
              },
              child: const Icon(Icons.delete_forever)),
        ]));
  }

  AppBar _buildAppBar(BuildContext context, AListController ui) {
    return AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Obx(() => Text("AList - ${ui.aListVersion.value}")),
        actions: [
          IconButton(
            tooltip: S.of(context).desktopShortcut,
            onPressed: () async {
              Android().addShortcut();
            },
            icon: const Icon(Icons.add_home),
          ),
          IconButton(
            tooltip: S.current.setAdminPassword,
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) => PwdEditDialog(onConfirm: (pwd) {
                        Get.showSnackbar(GetSnackBar(
                            title: S.current.setAdminPassword,
                            message: pwd,
                            duration: const Duration(seconds: 1)));
                        Android().setAdminPwd(pwd);
                      }));
            },
            icon: const Icon(Icons.password),
          ),
          PopupMenuButton(
            tooltip: S.of(context).moreOptions,
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 1,
                  onTap: () async {
                    AppUpdateDialog.checkUpdateAndShowDialog(context, (b) {
                      if (!b) {
                        Get.showSnackbar(GetSnackBar(
                            message: S.of(context).currentIsLatestVersion,
                            duration: const Duration(seconds: 2)));
                      }
                    });
                  },
                  child: Text(S.of(context).checkForUpdates),
                ),
                PopupMenuItem(
                  value: 2,
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: ((context) {
                          return const AppAboutDialog();
                        }));
                  },
                  child: Text(S.of(context).about),
                ),
              ];
            },
            icon: const Icon(Icons.more_vert),
          )
        ]);
  }

  @override
  void dispose() {
    Get.delete<LogLogic>();
    listen?.cancel();
    scrollController.dispose();
    super.dispose();
  }
}
