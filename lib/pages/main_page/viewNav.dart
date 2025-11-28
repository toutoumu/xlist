import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:subtitle_wrapper_package/bloc/bloc.dart';
import 'package:xlist/pages/alist/alist_info/view.dart';
import 'package:xlist/pages/homepage/index.dart';
import 'package:xlist/pages/setting/about/index.dart';
import 'package:xlist/pages/setting/download/index.dart';
import 'package:xlist/pages/setting/favorite/index.dart';
import 'package:xlist/pages/setting/index.dart';
import 'package:xlist/pages/setting/recent/index.dart';
import 'package:xlist/pages/setting/server/index.dart';

import 'drawer_user_controller.dart';
import 'home_drawer.dart';

class MainPageNav extends GetView<HomepageController> {
  MainPageNav({super.key});

  final screenView = Rx<Widget>(const Homepage(showNavIcon: false));
  final drawerIndex = Rx<DrawerIndex>(DrawerIndex.home);
  final _currentIndex = RxInt(0);
  late final List<DrawerList> drawerList = <DrawerList>[
    DrawerList(
      index: DrawerIndex.home,
      labelName: 'Home'.tr,
      icon: const Icon(Icons.home),
    ),
    DrawerList(
      index: DrawerIndex.server,
      labelName: 'server'.tr,
      // isAssetsImage: true,
      icon: const Icon(Icons.cloud),
    ),
    /*DrawerList(
      index: DrawerIndex.favorite,
      labelName: 'favorite'.tr,
      // isAssetsImage: true,
      icon: const Icon(Icons.star_rounded),
    ),*/
    /*DrawerList(
      index: DrawerIndex.history,
      labelName: 'recent'.tr,
      // isAssetsImage: true,
      icon: const Icon(Icons.history_rounded),
    ),*/
    DrawerList(
      index: DrawerIndex.download,
      labelName: 'download_manager'.tr,
      icon: const Icon(Icons.download),
    ),
    DrawerList(
      index: DrawerIndex.alist,
      labelName: 'appName'.tr,
      icon: const Icon(Icons.storage_rounded),
    ),
    /*DrawerList(
      index: DrawerIndex.about,
      labelName: 'About',
      icon: const Icon(Icons.info),
    ),*/
    DrawerList(
      index: DrawerIndex.setting,
      labelName: 'setting'.tr,
      icon: const Icon(Icons.settings),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => HomepageController());
    return Obx(() {
      return Scaffold(
          body: screenView.value,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex.value,
            unselectedItemColor: Theme.of(context).unselectedWidgetColor,
            selectedItemColor: Theme.of(context).primaryColor,
            type: BottomNavigationBarType.fixed,
            items: drawerList
                .map((e) => BottomNavigationBarItem(
                      icon: e.icon!,
                      label: e.labelName,
                    ))
                .toList(),
            onTap: (int index) {
              _currentIndex.value = index;
              changeIndex(drawerList[index].index);
            },
          ));
    });
  }

  void changeIndex(DrawerIndex drawerIndexdata) {
    /*if (drawerIndex.value != drawerIndexdata) {
      drawerIndex.value = drawerIndexdata;
    }
    switch (drawerIndexdata) {
      case DrawerIndex.alist:
        Get.toNamed(Routes.ALIST);
        break;
      case DrawerIndex.server:
        Get.lazyPut(() => SettingController());
        Get.lazyPut(() => ServerController());
        Get.toNamed(Routes.SETTING_SERVER);
      case DrawerIndex.favorite:
        Get.lazyPut(() => FavoriteController());
        Get.toNamed(Routes.SETTING_FAVORITE);
      case DrawerIndex.recent:
        Get.lazyPut(() => RecentController());
        Get.toNamed(Routes.SETTING_RECENT);
      case DrawerIndex.download:
        Get.lazyPut(() => DownloadController());
        Get.toNamed(Routes.SETTING_DOWNLOAD);
      case DrawerIndex.about:
        Get.lazyPut(() => AboutController());
        Get.toNamed(Routes.SETTING_ABOUT);
    }*/
    if (drawerIndex.value != drawerIndexdata) {
      drawerIndex.value = drawerIndexdata;
      /*switch (drawerIndex.value) {
        case DrawerIndex.alist:
          screenView.value = const Homepage();
          break;
        case DrawerIndex.server:
          Get.lazyPut(() => SettingController());
          screenView.value = const SettingPage();
          break;
        case DrawerIndex.download:
          Get.lazyPut(() => AboutController());
          screenView.value = const AboutPage();
          break;
        case DrawerIndex.invite:
          Get.lazyPut(() => AlistInfoLogic());
          screenView.value = const AListInfoPage();
          break;
        default:
          break;
      }*/
      switch (drawerIndexdata) {
        case DrawerIndex.home:
          Get.lazyPut(() => HomepageController());
          screenView.value = const Homepage(showNavIcon: false);
          break;
        case DrawerIndex.alist:
          // Get.toNamed(Routes.ALIST);
          screenView.value = const AListInfoPage(showNavIcon: false);
          break;
        case DrawerIndex.server:
          Get.lazyPut(() => SettingController());
          Get.lazyPut(() => ServerController());
          // Get.toNamed(Routes.SETTING_SERVER);
          screenView.value = const ServerPage(showNavIcon: false);
        case DrawerIndex.favorite:
          Get.lazyPut(() => FavoriteController());
          // Get.toNamed(Routes.SETTING_FAVORITE);
          screenView.value = const FavoritePage(showNavIcon: false);
        case DrawerIndex.history:
          Get.lazyPut(() => RecentController());
          // Get.toNamed(Routes.SETTING_RECENT);
          screenView.value = const RecentPage(showNavIcon: false);
        case DrawerIndex.download:
          Get.lazyPut(() => DownloadController());
          // Get.toNamed(Routes.SETTING_DOWNLOAD);
          screenView.value = const DownloadPage(showNavIcon: false);
        case DrawerIndex.about:
          Get.lazyPut(() => AboutController());
          // Get.toNamed(Routes.SETTING_ABOUT);
          screenView.value = const AboutPage(showNavIcon: false);
        case DrawerIndex.setting:
          Get.lazyPut(() => SettingController());
          // Get.toNamed(Routes.SETTING_ABOUT);
          screenView.value = const SettingPage(showNavIcon: false);
      }
    }
  }
}
