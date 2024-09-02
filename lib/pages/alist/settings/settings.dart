import 'dart:developer';
import 'dart:ffi';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xlist/common/utils.dart';
import 'package:xlist/generated_api.dart';
import 'package:xlist/pages/alist/alist/alist_controller.dart';
import 'package:xlist/pages/alist/widgets/pwd_edit_dialog.dart';
import '../contant/native_bridge.dart';
import 'preference_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() {
    return _SettingsScreenState();
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    _lifecycleListener = AppLifecycleListener(
      onResume: () async {
        final controller = Get.put(_SettingsController());
        controller.updateData();
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_SettingsController());
    final aListController = Get.find<AListController>();
    return CupertinoPageScaffold(
        navigationBar: _buildNavigationBar(),
        child: Obx(
          // () => _buildListView(controller, context, aListController),
          () => _buildCupertinoListView(context, controller),
        ));
  }

  ListView _buildCupertinoListView(
      BuildContext context, _SettingsController controller) {
    return ListView(children: [
      CupertinoListSection.insetGrouped(
          backgroundColor: CommonUtils.backgroundColor,
          dividerMargin: 20,
          additionalDividerMargin: 30,
          children: [
            _buildListTile(
              title: 'wakeLock'.tr,
              subtitle: Text('wakeLockDesc'.tr),
              icon: Icons.screen_lock_portrait,
              trailing: CupertinoSwitch(
                  value: controller.wakeLock,
                  onChanged: (value) {
                    controller.wakeLock = value;
                  }),
            ),
            _buildListTile(
              title: 'bootAutoStartService'.tr,
              subtitle: Text('bootAutoStartServiceDesc'.tr),
              icon: Icons.power_settings_new,
              trailing: CupertinoSwitch(
                  value: controller.startAtBoot,
                  onChanged: (value) {
                    controller.startAtBoot = value;
                  }),
            ),
            _buildListTile(
              title: 'dataDirectory'.tr,
              subtitle: Text(controller._dataDir.value),
              icon: Icons.folder,
              onTap: () async {
                final path = await FilePicker.platform.getDirectoryPath();
                if (path == null) {
                  Get.showSnackbar(GetSnackBar(
                      message: 'setDefaultDirectory'.tr,
                      duration: const Duration(seconds: 3),
                      mainButton: TextButton(
                        onPressed: () {
                          controller.setDataDir("");
                          Get.back();
                        },
                        child: Text('confirm'.tr),
                      )));
                } else {
                  controller.setDataDir(path);
                }
              },
            )
          ])
    ]);
  }

  ListView _buildListView(_SettingsController controller, BuildContext context,
      AListController aListController) {
    return ListView(
      children: [
        // SizedBox(height: MediaQuery.of(context).padding.top),
        Visibility(
          visible: !controller._managerStorageGranted.value ||
              !controller._notificationGranted.value ||
              !controller._storageGranted.value,
          child: DividerPreference(title: 'importantSettings'.tr),
        ),

        // 所有文件访问权限 >= Android 11 (api 30)
        Visibility(
          visible: !controller._managerStorageGranted.value,
          child: BasicPreference(
            title: 'grantManagerStoragePermission'.tr,
            subtitle: 'grantStoragePermissionDesc'.tr,
            onTap: () {
              Permission.manageExternalStorage.request();
            },
          ),
        ),

        // 读写外置存储权限 < Android 11 (api 30)
        Visibility(
            visible: !controller._storageGranted.value,
            child: BasicPreference(
              title: 'grantStoragePermission'.tr,
              subtitle: 'grantStoragePermissionDesc'.tr,
              onTap: () {
                Permission.storage.request();
              },
            )),

        // 申请通知权限 > Android 12 (api 31)
        Visibility(
            visible: !controller._notificationGranted.value,
            child: BasicPreference(
              title: 'grantNotificationPermission'.tr,
              subtitle: 'grantNotificationPermissionDesc'.tr,
              onTap: () {
                Permission.notification.request();
              },
            )),

        DividerPreference(title: 'general'.tr),

        // 自动检查更新
        SwitchPreference(
          title: 'autoCheckForUpdates'.tr,
          subtitle: 'autoCheckForUpdatesDesc'.tr,
          icon: const Icon(Icons.system_update),
          value: controller.autoUpdate,
          onChanged: (value) {
            controller.autoUpdate = value;
          },
        ),

        // 唤醒屏幕
        SwitchPreference(
          title: 'wakeLock'.tr,
          subtitle: 'wakeLockDesc'.tr,
          icon: const Icon(Icons.screen_lock_portrait),
          value: controller.wakeLock,
          onChanged: (value) {
            controller.wakeLock = value;
          },
        ),

        // 开机自启动服务
        SwitchPreference(
          title: 'bootAutoStartService'.tr,
          subtitle: 'bootAutoStartServiceDesc'.tr,
          icon: const Icon(Icons.power_settings_new),
          value: controller.startAtBoot,
          onChanged: (value) {
            controller.startAtBoot = value;
          },
        ),

        // 将网页设置为打开首页
        SwitchPreference(
          title: 'autoStartWebPage'.tr,
          subtitle: 'autoStartWebPageDesc'.tr,
          icon: const Icon(Icons.open_in_browser),
          value: controller._autoStartWebPage.value,
          onChanged: (value) {
            controller.autoStartWebPage = value;
          },
        ),

        // AList data 文件夹路径
        BasicPreference(
          title: 'dataDirectory'.tr,
          subtitle: controller._dataDir.value,
          leading: const Icon(Icons.folder),
          onTap: () async {
            final path = await FilePicker.platform.getDirectoryPath();
            if (path == null) {
              Get.showSnackbar(GetSnackBar(
                  message: 'setDefaultDirectory'.tr,
                  duration: const Duration(seconds: 3),
                  mainButton: TextButton(
                    onPressed: () {
                      controller.setDataDir("");
                      Get.back();
                    },
                    child: Text('confirm'.tr),
                  )));
            } else {
              controller.setDataDir(path);
            }
          },
        ),

        DividerPreference(title: 'general'.tr),
        // 将网页设置为打开首页
        SwitchPreference(
          title: 'autoStartWebPage'.tr,
          subtitle: 'autoStartWebPageDesc'.tr,
          icon: const Icon(Icons.open_in_browser),
          value: aListController.isRunning.value,
          onChanged: (value) {
            NativeBridge.android.startService();
          },
        ),

        BasicPreference(
          title: "用户名",
          subtitle: controller._userName.value,
          leading: const Icon(Icons.folder),
          onTap: () async {},
        ),

        BasicPreference(
          title: "密码",
          subtitle: controller._password.value,
          leading: const Icon(Icons.folder),
          onTap: () async {
            showDialog(
                context: context,
                builder: (context) => PwdEditDialog(
                      onConfirm: (pwd) {
                        Get.showSnackbar(GetSnackBar(
                            title: 'setAdminPassword'.tr,
                            message: pwd,
                            duration: const Duration(seconds: 1)));
                        Android().setAdminPwd(pwd);
                      },
                      password: controller._password.value,
                    ));
          },
        ),

        BasicPreference(
          title: "服务地址",
          subtitle: "${controller._wIp.value}:${controller._port.value}",
          leading: const Icon(Icons.open_in_browser),
          onTap: () async {},
        ),

        // 界面
        DividerPreference(title: 'uiSettings'.tr),
        // 静默跳转APP
        SwitchPreference(
            icon: const Icon(Icons.pan_tool_alt_outlined),
            title: 'silentJumpApp'.tr,
            subtitle: 'silentJumpAppDesc'.tr,
            value: controller._silentJumpApp.value,
            onChanged: (value) {
              controller.silentJumpApp = value;
            })
      ],
    );
  }

  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      border: Border.all(width: 0, color: Colors.transparent),
      leading: CommonUtils.backButton,
      middle: const Text(
        "AList 设置",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// ListTile
  /// [title] 标题
  /// [icon] 图标
  /// [onTap] 点击事件
  /// [additionalInfo] 附加信息
  Widget _buildListTile({
    required String title,
    required IconData icon,
    double? iconSize,
    Color? iconColor,
    Function()? onTap,
    Widget? subtitle,
    Widget trailing = const CupertinoListTileChevron(),
    String additionalInfo = '',
  }) {
    return CupertinoListTile(
      title: Row(
        children: [
          Text(title, style: Get.textTheme.bodyLarge),
          const SizedBox(width: 10),
        ],
      ),
      padding: const EdgeInsets.only(left: 15, right: 10),
      leading: Icon(
        icon,
        size: iconSize ?? CommonUtils.navIconSize,
        color: iconColor ?? Get.theme.primaryColor,
      ),
      leadingToTitle: 5,
      subtitle: subtitle,
      additionalInfo: additionalInfo.isEmpty
          ? const SizedBox()
          : Container(
              width: 400.w,
              alignment: Alignment.centerRight,
              child: Text(
                additionalInfo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _SettingsController extends GetxController {
  final _password = "".obs;
  final _userName = "".obs;
  final _wIp = "".obs;
  final _port = 5244.obs;

  final _dataDir = "".obs;
  final _autoUpdate = true.obs;
  final _managerStorageGranted = true.obs;
  final _notificationGranted = true.obs;
  final _storageGranted = true.obs;

  setDataDir(String value) async {
    NativeBridge.appConfig.setDataDir(value);
    _dataDir.value = await NativeBridge.appConfig.getDataDir();
  }

  get dataDir => _dataDir.value;

  set autoUpdate(value) => {
        _autoUpdate.value = value,
        NativeBridge.appConfig.setAutoCheckUpdateEnabled(value)
      };

  get autoUpdate => _autoUpdate.value;

  final _wakeLock = true.obs;

  set wakeLock(value) => {
        _wakeLock.value = value,
        NativeBridge.appConfig.setWakeLockEnabled(value)
      };

  get wakeLock => _wakeLock.value;

  final _autoStart = true.obs;

  set startAtBoot(value) => {
        _autoStart.value = value,
        NativeBridge.appConfig.setStartAtBootEnabled(value)
      };

  get startAtBoot => _autoStart.value;

  final _autoStartWebPage = false.obs;

  set autoStartWebPage(value) => {
        _autoStartWebPage.value = value,
        NativeBridge.appConfig.setAutoOpenWebPageEnabled(value)
      };

  get autoStartWebPage => _autoStartWebPage.value;

  final _silentJumpApp = false.obs;

  get silentJumpApp => _silentJumpApp.value;

  set silentJumpApp(value) => {
        _silentJumpApp.value = value,
        NativeBridge.appConfig.setSilentJumpAppEnabled(value)
      };

  @override
  void onInit() async {
    updateData();

    super.onInit();
  }

  void updateData() async {
    final cfg = AppConfig();
    cfg.isAutoCheckUpdateEnabled().then((value) => autoUpdate = value);
    cfg.isWakeLockEnabled().then((value) => wakeLock = value);
    cfg.isStartAtBootEnabled().then((value) => startAtBoot = value);
    cfg.isAutoOpenWebPageEnabled().then((value) => autoStartWebPage = value);
    cfg.isSilentJumpAppEnabled().then((value) => silentJumpApp = value);

    _dataDir.value = await cfg.getDataDir();

    _password.value = await NativeBridge.android.getAdminPassword();
    _userName.value = await NativeBridge.android.getAdminUsername();
    _wIp.value = await NativeBridge.android.getOutboundIPString();
    _port.value = await NativeBridge.android.getAListHttpPort();

    final sdk = await NativeBridge.common.getDeviceSdkInt();
    // A11
    if (sdk >= 30) {
      _managerStorageGranted.value =
          await Permission.manageExternalStorage.isGranted;
    } else {
      _managerStorageGranted.value = true;
      _storageGranted.value = await Permission.storage.isGranted;
    }

    // A12
    if (sdk >= 32) {
      _notificationGranted.value = await Permission.notification.isGranted;
    } else {
      _notificationGranted.value = true;
    }
  }
}
