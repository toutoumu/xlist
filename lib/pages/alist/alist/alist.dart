import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:xlist/common/repository.dart';
import 'package:xlist/generated_api.dart';
import 'package:xlist/pages/alist/models/log.dart';

/// AList 全局状态
class AListController extends GetxController {
  // 服务是否正在运行中
  var isRunning = false.obs;

  // 是否正在启动中
  var isLoading = false.obs;

  // 用户名
  var adminUserName = "".obs;

  // 密码
  var adminPassword = "".obs;

  // ip地址
  var ipAddress = "".obs;

  // 端口号
  var port = 0.obs;

  // 版本号
  var aListVersion = "".obs;

  // 日志
  var logs = <Log>[].obs;

  late StreamSubscription listen;

  @override
  Future<void> onInit() async {
    // 运行状态,日志监听
    Event.setup(
      // 状态监听
      MyEventReceiver(
        logCb: (log) => addLog(log),
        statusCb: (bool running) async {
          log("statusCb");
          isRunning.value = await Android().isRunning();
          isLoading.value = false;
        },
        processExitCb: () async {
          log("processExitCb");
          isRunning.value = await Android().isRunning();
          isLoading.value = false;
        },
        shutdownCb: () async {
          log("shutdownCb");
          isRunning.value = await Android().isRunning();
          isLoading.value = false;
        },
        startErrorCb: () async {
          log("startErrorCb");
          isRunning.value = await Android().isRunning();
          isLoading.value = false;
        },
      ),
    );

    // 监听运行状态
    listen = isRunning.listen((isRunning) async {
      if (isRunning) {
        // 如果已经开始运行, 更新本地用户名密码
        updateAdminInfo();
      }
    });

    // 运行状态
    Android().isRunning().then((value) => isRunning.value = value);
    // 版本号, ip, 端口号
    Android().getAListVersion().then((value) => aListVersion.value = value);
    Android().getOutboundIPString().then((value) => ipAddress.value = value);
    Android().getAListHttpPort().then((value) => port.value = value);
    // 如果设置了开机启动，则启动服务
    if (await AppConfig().isStartAtBootEnabled() &&
        !await Android().isRunning()) {
      log("启动 AList...");
      Android().startService();
    }
    super.onInit();
  }

  @override
  void onClose() {
    listen.cancel();
  }

  void clearLog() {
    logs.clear();
  }

  void addLog(Log logContent) {
    logs.add(logContent);

    // _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Future<void> start() async {
    // android 这些逻辑判断放到原生里做
    if (Platform.isAndroid) {
      isLoading.value = true;
      await Android().startService();
      return;
    }

    if (isRunning.value) {
      return;
    }
    isLoading.value = true;
    try {
      await Android().startService();
      // 服务启动需要时间，这里做一个延时检测
      await Future.delayed(const Duration(seconds: 10));
      await Repository.get(
        'http://127.0.0.1:5244/ping',
        options: Options(
            sendTimeout: const Duration(milliseconds: 1000),
            receiveTimeout: const Duration(milliseconds: 1000)),
      );
      isRunning.value = await Android().isRunning();
    } catch (e) {
      print(e);
    }
    isLoading.value = false;
  }

  Future<void> stop() async {
    if (!isRunning.value) {
      return;
    }
    try {
      isLoading.value = true;
      await Android().startService();
      // isRunning.value = await Android().isRunning();
    } catch (e) {
      print(e);
    }
  }

// const updateAdminInfo = useCallback(async () => {
//     const pwd = await Alist.getAdminPassword()
//     const username = await Alist.getAdminUsername()
//     if (!pwd) {
//       // 只有首次启动服务会获取不到密码，那么直接设置初始密码为admin
//       await changePassword(DEFAULT_PASSWORD)
//       setAdminPwd(DEFAULT_PASSWORD)
//     } else {
//       setAdminPwd(pwd)
//     }
//     setAdminUsername(username)
//   }
  void updateAdminInfo() async {
    adminPassword.value = await Android().getAdminPassword();
    adminUserName.value = await Android().getAdminUsername();
    // 只有首次启动服务会获取不到密码，那么直接设置初始密码为admin
    if (adminPassword.value == null || adminPassword.value.isEmpty) {
      await Android().setAdminPwd("123456");
    }
  }

  Future<void> updateAdminPassword(String pwd) async {
    await Android().setAdminPwd(pwd);
    updateAdminInfo();
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
