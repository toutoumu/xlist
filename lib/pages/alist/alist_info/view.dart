import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:xlist/common/utils.dart';
import 'package:xlist/pages/alist/alist/alist_controller.dart';
import 'package:xlist/pages/alist/widgets/pwd_edit_dialog.dart';
import 'package:xlist/routes/app_pages.dart';

import 'logic.dart';

/// AList 当前状态信息
class AListInfoPage extends StatefulWidget {
  const AListInfoPage({super.key});

  @override
  State<AListInfoPage> createState() {
    return _AListInfoPageState();
  }
}

class _AListInfoPageState extends State<AListInfoPage> {
  late AppLifecycleListener _lifecycleListener;

  final aListController = Get.find<AListController>();

  @override
  void initState() {
    _lifecycleListener = AppLifecycleListener(
      onResume: () async {
        final controller = Get.put(AlistInfoLogic());
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
    final controller = Get.put(AlistInfoLogic());
    final aListController = Get.find<AListController>();
    return CupertinoPageScaffold(
        navigationBar: _buildNavigationBar(),
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
                backgroundColor: CommonUtils.backgroundColor,
                dividerMargin: 20,
                additionalDividerMargin: 30,
                children: [
                  // 服务状态
                  _buildAListState(),
                ]),

            // 账号信息
            CupertinoListSection.insetGrouped(
                backgroundColor: CommonUtils.backgroundColor,
                dividerMargin: 20,
                additionalDividerMargin: 30,
                header: Container(
                  padding: const EdgeInsets.only(left: 15),
                  alignment: Alignment.centerLeft,
                  child: Text('账号信息', style: Get.textTheme.bodySmall),
                ),
                children: [
                  // 服务状态
                  Obx(() {
                    return _buildListTile(
                      title: "用户名",
                      icon: Icons.account_circle_outlined,
                      additionalInfo: aListController.adminUserName.value,
                    );
                  }),
                  Obx(() {
                    return _buildListTile(
                      title: "密码",
                      icon: Icons.account_circle_outlined,
                      additionalInfo: aListController.adminPassword.value,
                      onTap: () async {
                        showDialog(
                            context: context,
                            builder: (context) => PwdEditDialog(
                                  password: aListController.adminPassword.value,
                                  onConfirm: (pwd) {
                                    Get.showSnackbar(GetSnackBar(
                                        title: 'setAdminPassword'.tr,
                                        message: pwd,
                                        duration: const Duration(seconds: 1)));
                                    aListController.updateAdminPassword(pwd);
                                  },
                                ));
                      },
                    );
                  })
                ]),
            // WebDav信息
            CupertinoListSection.insetGrouped(
                backgroundColor: CommonUtils.backgroundColor,
                dividerMargin: 20,
                additionalDividerMargin: 30,
                header: Container(
                  padding: const EdgeInsets.only(left: 15),
                  alignment: Alignment.centerLeft,
                  child: Text('WebDav信息', style: Get.textTheme.bodySmall),
                ),
                children: [
                  // 服务状态
                  Obx(() {
                    return _buildListTile(
                      title: "服务器地址",
                      icon: Icons.account_circle_outlined,
                      additionalInfo: aListController.ipAddress.value,
                    );
                  }),
                  Obx(() {
                    return _buildListTile(
                      title: "端口",
                      icon: Icons.account_circle_outlined,
                      additionalInfo: aListController.port.value.toString(),
                    );
                  }),
                  _buildListTile(
                    title: "路径",
                    icon: Icons.account_circle_outlined,
                    additionalInfo: "dav",
                  ),
                  _buildListTile(
                    title: "用户名/密码",
                    icon: Icons.account_circle_outlined,
                    additionalInfo: "同\"账号信息\"",
                  )
                ]),
            CupertinoListSection.insetGrouped(
                backgroundColor: CommonUtils.backgroundColor,
                dividerMargin: 20,
                additionalDividerMargin: 30,
                header: Container(
                  padding: const EdgeInsets.only(left: 15),
                  alignment: Alignment.centerLeft,
                  child: Text('AList 版本号', style: Get.textTheme.bodySmall),
                ),
                children: [
                  // 服务状态
                  Obx(() {
                    return _buildListTile(
                      title: "AList 版本号",
                      icon: Icons.account_circle_outlined,
                      additionalInfo: aListController.aListVersion.value,
                    );
                  }),
                ])
          ],
        ));
  }

  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
        backgroundColor: Get.theme.scaffoldBackgroundColor,
        border: Border.all(width: 0, color: Colors.transparent),
        leading: CommonUtils.backButton,
        middle: const Text(
          "AList",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          // 日志
          CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                Get.toNamed(Routes.LOG);
              },
              child: const Icon(Icons.blur_linear_sharp)),
          // AList 设置
          CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                Get.toNamed(Routes.SETTING_ALIST);
              },
              child: const Icon(Icons.settings)),
        ]));
  }

  /// AList状态
  Obx _buildAListState() {
    return Obx(() {
      return _buildListTile(
        title:
            "服务状态: ${aListController.isLoading.value ? '启动中...' : aListController.isRunning.value ? '运行中' : '未运行'}",
        icon: Icons.perm_media_rounded,
        trailing: CupertinoSwitch(
            value: aListController.isRunning.value,
            onChanged: (value) {
              if (value) {
                aListController.start();
              } else {
                aListController.stop();
              }
            }),
      );
    });
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
