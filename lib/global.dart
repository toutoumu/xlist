import 'dart:io';
import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xlist/pages/alist/alist/alist_controller.dart';

import 'package:xlist/services/index.dart';
import 'package:xlist/storages/index.dart';
import 'package:xlist/constants/index.dart';

// 全局配置
class Global {
  static bool get isRelease => kReleaseMode;

  static bool get isProfile => kProfileMode;

  static bool get isDebug => kDebugMode;

  // 运行初始化
  static Future<void> init() async {
    // Init FlutterBinding
    WidgetsFlutterBinding.ensureInitialized();

    // Necessary initialization for package:media_kit.
    MediaKit.ensureInitialized();

    // HttpOverrides
    HttpOverrides.global = XlistHttpOverrides();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await ensureConfigDirectory();
    }

    // state
    await Get.put(AListController());

    // GetStorage
    await GetStorage.init();

    // Storage
    await Get.put(CommonStorage());
    await Get.putAsync(() => UserStorage().init());
    await Get.putAsync(() => PreferencesStorage().init());

    // Init Getx Service
    await Get.put(BrowserService());
    await Get.putAsync(() => DioService().init());
    await Get.putAsync(() => DatabaseService().init());
    await Get.putAsync(() => DownloadService().init());
    await Get.putAsync(() => DeviceInfoService().init());
    await Get.putAsync(() => PlayerNotificationService().init());

    // 读取设备第一次打开
    final isFirstOpen = Get.find<PreferencesStorage>().isFirstOpen;
    if (isFirstOpen.val == true) {
      isFirstOpen.val = false;

      // IOS 请求联网弹窗
      try {
        if (GetPlatform.isIOS) DioService.to.dio.get('https://xlist.site');
      } catch (e) {}
    }

    // Theme
    Get.changeThemeMode(ThemeModeMap[Get.find<CommonStorage>().themeMode.val]!);

    // android 状态栏为透明的沉浸
    if (GetPlatform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle =
          const SystemUiOverlayStyle(statusBarColor: Colors.transparent);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
  }

  /*
    背景：
    1. ios覆盖安装应用时，会创建一个新的Document目录，同时会把旧文件拷贝过去
    2. config文件中存储的日志文件、临时目录等路径都是绝对路径

    问题：由于Document目录已更新，但是config文件中存储的文件路径没有更新，服务启动后仍向旧的Document目录读写文件，会导致读写无权限

    解法：这里对config文件中存储的文件路径进行处理，替换为新的Document目录
     */
  static Future<void> ensureConfigDirectory() async {
    var documentDirectory = await getApplicationDocumentsDirectory();
    String dir = '${documentDirectory.path}/config.json';
    var configFile = File(dir);
    if (!await configFile.exists()) {
      return;
    }

    var configContent = await configFile.readAsString();
    if (configContent.contains(documentDirectory.path)) {
      return;
    }

    // Define the pattern for UUID.
    String patternString =
        r'\/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\/';
    RegExp regexPattern = RegExp(patternString);

    // Replace the pattern with the document directory path.
    String newConfigData = configContent.replaceAll(regexPattern,
        regexPattern.firstMatch(documentDirectory.path)?.group(0) ?? '');

    // Write the updated data back to the file.
    await configFile.writeAsString(newConfigData);
  }
}

class XlistHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // allowLegacyUnsafeRenegotiation
    final SecurityContext sc = SecurityContext();
    sc.allowLegacyUnsafeRenegotiation = true;

    return super.createHttpClient(sc)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
