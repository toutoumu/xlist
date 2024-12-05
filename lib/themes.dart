import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/services.dart';

class Themes {
  // Light
  static final light = FlexThemeData.light(
    useMaterial3: true,
    scheme: FlexScheme.blueM3,
    // primary: Color(0xFF7778dc),
    // secondary: Color(0xFF81aad3),
  ).copyWith(
    // splashColor: Colors.transparent,
    // highlightColor: Colors.transparent,
    // splashFactory: NoSplash.splashFactory,
    cupertinoOverrideTheme: const CupertinoThemeData(
      textTheme: CupertinoTextThemeData(),
    ),
    // 启用侧滑返回
    platform: TargetPlatform.iOS,
    // 转场动画
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  // Dark
  static final dark = FlexThemeData.dark(
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    scheme: FlexScheme.amber,
    // primary: Color(0xFF7778dc),
    // secondary: Color(0xFF81aad3),
  ).copyWith(
    // splashColor: Colors.transparent,
    // highlightColor: Colors.transparent,
    // splashFactory: NoSplash.splashFactory,
    cupertinoOverrideTheme: const CupertinoThemeData(
      textTheme: CupertinoTextThemeData(),
    ),
    // 启用侧滑返回
    platform: TargetPlatform.iOS,
    // 转场动画
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}


ThemeData themeData(Brightness brightness, BuildContext context) {
  var theme = ThemeData(brightness: brightness);
  if (brightness == Brightness.light) {
    // 亮色模式
    theme = theme.copyWith(
      bottomSheetTheme: theme.bottomSheetTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 14,
        clipBehavior: Clip.antiAliasWithSaveLayer, // 拥有清晰的边缘
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      ),
    );
  } else {
    // 暗色模式
    theme = theme.copyWith(
      bottomSheetTheme: theme.bottomSheetTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        elevation: 14,
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        modalBarrierColor: CupertinoColors.secondarySystemBackground.resolveFrom(context).withOpacity(0.8),
      ),
    );
  }
  var iconColor = CupertinoColors.systemBlue.resolveFrom(context);
  // 两种主题公共的部分
  return theme.copyWith(
    // light 文字状态栏图标为 深色 dark 文字状态栏为 浅色
    brightness: brightness,
    primaryColor: iconColor,
    scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
    cardColor: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
    iconTheme: theme.iconTheme.copyWith(size: 24, color: iconColor),
    // 弹出菜单
    popupMenuTheme: theme.popupMenuTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 5,
      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
      position: PopupMenuPosition.under,
    ),
    // 折叠展开面板
    expansionTileTheme: theme.expansionTileTheme.copyWith(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      collapsedBackgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      shape: BorderDirectional(
        top: BorderSide(color: CupertinoColors.systemGroupedBackground.resolveFrom(context), width: 0),
        bottom: BorderSide(color: CupertinoColors.systemGroupedBackground.resolveFrom(context), width: 0),
      ),
      collapsedShape: BorderDirectional(
        top: BorderSide(color: CupertinoColors.systemGroupedBackground.resolveFrom(context), width: 0),
        bottom: BorderSide(color: CupertinoColors.systemGroupedBackground.resolveFrom(context), width: 0),
      ),
    ),
    // IOS 控件主题
    cupertinoOverrideTheme: CupertinoThemeData(brightness: brightness).copyWith(
      applyThemeToAll: true,
      brightness: brightness,
      barBackgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      primaryColor: iconColor,
      primaryContrastingColor: CupertinoColors.systemGreen.resolveFrom(context),
      scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(color: CupertinoColors.label.resolveFrom(context), fontSize: 14),
      ),
    ),
    // 标题栏样式,cupertino 没用到这个
    appBarTheme: theme.appBarTheme.copyWith(
      // appBar 状态栏,标题栏颜色
      color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      // 状态栏文字颜色 dark 白色 light 黑色
      // brightness: Brightness.dark,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: brightness,
      ),
      // appBar下面阴影高度
      elevation: 14,
      // appBar文字样式
      titleTextStyle: TextStyle(color: CupertinoColors.label.resolveFrom(context), fontSize: 18),
      toolbarTextStyle: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
      // appBar 图标(返回按钮)样式
      iconTheme: theme.primaryIconTheme.copyWith(
        // opacity: 1,
        color: CupertinoColors.systemBlue.resolveFrom(context),
        size: 24,
      ),
    ),
    // 启用侧滑返回
    platform: TargetPlatform.iOS,
    // 转场动画
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}