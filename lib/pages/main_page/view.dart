import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

class MainPage extends GetView<HomepageController> {
  MainPage({super.key});

  final screenView = Rx<Widget>(const Homepage(showNavIcon: false));
  final drawerIndex = Rx<DrawerIndex>(DrawerIndex.home);

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => HomepageController());
    return Obx(() {
      return DrawerUserController(
        screenIndex: drawerIndex.value,
        drawerWidth: MediaQuery.of(context).size.width * 0.75,
        onDrawerCall: (DrawerIndex drawerIndexdata) {
          changeIndex(drawerIndexdata);
          //callback from drawer for replace screen as user need with passing DrawerIndex(Enum index)
        },
        screenView: screenView.value,
        //we replace screen view as we need on navigate starting screens like MyHomePage, HelpScreen, FeedbackScreen, etc...
      );
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
          screenView.value = const SettingPage(showNavIcon: false);
      }
    }
  }
}
