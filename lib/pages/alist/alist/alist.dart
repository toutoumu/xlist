import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xlist/generated/l10n.dart';
import 'package:xlist/generated_api.dart';
import 'package:xlist/pages/alist/app_update_dialog.dart';
import 'package:xlist/pages/setting/server/controller.dart';

import '../widgets/switch_floating_action_button.dart';
import 'about_dialog.dart';
import 'log_list_view.dart';
import 'pwd_edit_dialog.dart';

class AListScreen extends GetView<ServerController> {
  const AListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final ui = Get.put(AListController());
    final ui = Get.find<AListController>();
    /*Timer? timer;
    ui.logs.listen((event) {
      if (timer != null) {
        timer!.cancel();
      }
      timer = Timer(const Duration(milliseconds: 1000), () {
        ui._scrollController.animateTo(
          ui._scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    });*/

    return Scaffold(
        appBar: AppBar(
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
            ]),
        floatingActionButton: Obx(
          () => SwitchFloatingButton(
              isSwitch: ui.isRunning.value,
              onSwitchChange: (s) async {
                ui.clearLog();
                // ui.isSwitch.value = s;
                Android().startService();
              }),
        ),
        body: Obx(() => LogListView(
              logs: ui.logs.value,
              controller: ui._scrollController,
            )));
  }
}

class MyEventReceiver extends Event {
  Function(Log log) logCb;
  Function(bool isRunning) statusCb;
  Function() processExitCb;
  Function() shutdownCb;
  Function() startErrorCb;

  MyEventReceiver({
    required this.statusCb,
    required this.logCb,
    required this.processExitCb,
    required this.shutdownCb,
    required this.startErrorCb,
  });

  @override
  void onServiceStatusChanged(bool isRunning) {
    statusCb(isRunning);
  }

  @override
  void onServerLog(int level, String time, String log) {
    logCb(Log(level, time, log));
  }

  @override
  void onProcessExit(int var1) {
    processExitCb();
  }

  @override
  void onShutdown(String var1) {
    shutdownCb();
  }

  @override
  void onStartError(String var1, String var2) {
    startErrorCb();
  }
}

class AListController extends GetxController {
  final ScrollController _scrollController = ScrollController();
  var isRunning = false.obs;
  var aListVersion = "".obs;

  var logs = <Log>[].obs;

  void clearLog() {
    logs.clear();
  }

  void addLog(Log logContent) {
    logs.add(logContent);
    // _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Future<void> onInit() async {
    // 运行状态,日志监听
    Event.setup(
      // 状态监听
      MyEventReceiver(
        // statusCb: (isRunning) => isSwitch.value = isRunning,
        logCb: (log) => addLog(log),
        statusCb: (bool running) async {
          log("statusCb");
          isRunning.value = await Android().isRunning();
        },
        processExitCb: () async {
          log("processExitCb");
          isRunning.value = await Android().isRunning();
        },
        shutdownCb: () async {
          log("shutdownCb");
          isRunning.value = await Android().isRunning();
        },
        startErrorCb: () async {
          log("startErrorCb");
          isRunning.value = await Android().isRunning();
        },
      ),
    );
    // 版本号
    Android().getAListVersion().then((value) => aListVersion.value = value);
    Android().isRunning().then((value) => isRunning.value = value);

    // 如果设置了开机启动，则启动服务
    if (await AppConfig().isStartAtBootEnabled() &&
        !await Android().isRunning()) {
      log("启动 AList...");
      Android().startService();
    }
    super.onInit();
  }
}
