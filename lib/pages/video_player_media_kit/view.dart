import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:audio_wave/audio_wave.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xlist/gen/index.dart';
import 'package:xlist/helper/index.dart';
import 'package:xlist/common/index.dart';
import 'package:media_kit_video/media_kit_video_controls/media_kit_video_controls.dart';

import 'index.dart';

class VideoPlayerMediaKitPage extends GetView<VideoPlayerMediaKitController> {
  const VideoPlayerMediaKitPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // navigationBar: _buildNavigationBar(),
      // backgroundColor: CommonUtils.backgroundColor,
      backgroundColor: Colors.transparent,
      child: Obx(() => Stack(children: [
            _buildPageInfo(context),
          ])),
    );
  }

  /// 构建页面信息
  Widget _buildPageInfo(BuildContext context) {
    final showLoading = controller.currentObject.value.rawUrl == null ||
        controller.buffering.isTrue;

    // 视频加载中
    // if (controller.currentObject.value.rawUrl == null ||
    //     controller.buffering.isTrue) {
    return Stack(
      children: [
        // 播放器
        _buildVideoPlayer(context),

        // 封面
        /*Obx(() {
          final showCover = controller.buffering.isTrue &&
              controller.thumbnail.value.isNotEmpty;
          return showCover
              ? CachedNetworkImage(
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  imageUrl: controller.thumbnail.value,
                  httpHeaders: controller.httpHeaders,
                )
              : const SizedBox();
        }),*/
        // 加载中
        showLoading
            ? const Center(
                child:
                    CupertinoActivityIndicator(color: Colors.white, radius: 20),
              )
            : const SizedBox(),
      ],
    );
    // }

    /*
    final videoPlayer = _buildVideoPlayer(context);
    return OrientationBuilder(
      builder: (context, orientation) {
        return Obx(
          () => orientation == Orientation.portrait
              ? DefaultTabController(
                  length: 2,
                  child: _buildPortraitInfo(videoPlayer),
                )
              : _buildLandscapeInfo(videoPlayer),
        );
      },
    );*/
  }

  /// 构建下拉按钮
  Widget _buildPullDownButton() {
    return Obx(() {
      List<PullDownMenuEntry> items = [];

      // 收藏
      items.add(PullDownMenuItem(
        title: 'favorite'.tr,
        onTap: () => controller.favorite(),
      ));

      // 切换字幕
      if (controller.subtitleNameList.isNotEmpty ||
          controller.timedTextTracks.isNotEmpty) {
        items.add(PullDownMenuItem(
          title: 'video_switch_subtitle'.tr,
          onTap: () => controller.changeSubtitle(),
        ));
      }

      // 切换音轨
      if (controller.audioTracks.isNotEmpty &&
          controller.audioTracks.length > 1) {
        items.add(PullDownMenuItem(
          title: 'video_switch_audio'.tr,
          onTap: () => controller.changeAudioTrack(),
        ));
      }

      items.addAll([
        // 复制链接
        PullDownMenuItem(
          title: 'pull_down_copy_link'.tr,
          onTap: () => controller.copyLink(),
        ),
        // 下载文件
        PullDownMenuItem(
          title: 'pull_down_download_file'.tr,
          onTap: () => controller.download(),
        ),
      ]);

      /*return PullDownButton(
      itemBuilder: (context) => items,
      buttonBuilder: (context, showMenu) => CupertinoButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        alignment: Alignment.centerRight,
        child: Icon(
          CupertinoIcons.ellipsis_circle,
          size: CommonUtils.navIconSize,
        ),
      ),
    );*/
      return PullDownButton(
        itemBuilder: (context) => items,
        buttonBuilder: (context, showMenu) => IconButton(
          icon: const Icon(CupertinoIcons.ellipsis_circle),
          iconSize: IconTheme.of(context).size ?? 114,
          color: Colors.white,
          onPressed: showMenu,
        ),
      );
    });
  }

  // NavigationBar
  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      border: Border.all(width: 0, color: Colors.transparent),
      leading: CommonUtils.backButton,
      middle: Obx(
        () => Text(
          CommonUtils.formatFileNme(controller.currentName.value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Obx(() => _buildPullDownButton()),
    );
  }

  // 视频播放器
  Widget _buildVideoPlayer(BuildContext context) {
    // 移动端播放器配置
    if (Platform.isAndroid || Platform.isIOS) {
      return _buildMobilePlayer(context);
    }
    // 桌面端播放器配置
    return _buildComputerPlayer(context);
  }

  /// 移动端播放器
  Widget _buildMobilePlayer(BuildContext context) {
    return MaterialVideoControlsTheme(
      key: const ObjectKey("mobile"),
      normal: MaterialVideoControlsThemeData(
        seekGesture: true,
        volumeGesture: true,
        brightnessGesture: true,
        seekOnDoubleTap: true,
        speedUpOnLongPress: true,
        visibleOnMount: true,
        verticalGestureSensitivity: 200,
        horizontalGestureSensitivity: 1000,
        controlsHoverDuration: const Duration(seconds: 5),
        bufferingIndicatorBuilder: (context) =>
            const CupertinoActivityIndicator(color: Colors.white, radius: 20),
        primaryButtonBar: [
          // 播放列表
          Obx(() {
            return controller.showPlaylist.isTrue
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.list),
                      iconSize: IconTheme.of(context).size ?? 114,
                      color: Colors.white,
                      onPressed: () => {
                        BottomSheetHelper.showBottomSheet(_buildPlayList(),
                            expand: false),
                      },
                    ),
                  )
                : const Spacer();
          }),
          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(15),
            ),
            child: _buildPullDownButton(),
          )
        ],
        buttonBarHeight: 100,
        bottomButtonBarMargin:
            const EdgeInsets.only(left: 20.0, right: 20, bottom: 45),
        bottomButtonBar: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
              // 设置背景色会遮挡触摸事件
              /*decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(15),
              ),*/
              child: Column(
                children: [
                  // 进度条两边的时间
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Obx(() {
                        return Text(
                          '${controller.currentPos.value.label(reference: controller.currentPos.value)} ',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        );
                      }),
                      // const Spacer(),
                      Obx(() {
                        return Text(
                          '${controller.duration.value.label(reference: controller.duration.value)} ',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        );
                      }),
                    ],
                  ),
                  // 播放控制按钮
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Spacer(flex: 2),
                      MaterialSkipPreviousButton(),
                      Spacer(),
                      MaterialPlayOrPauseButton(iconSize: 48.0),
                      Spacer(),
                      MaterialSkipNextButton(),
                      Spacer(flex: 2),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],

        seekBarMargin: const EdgeInsets.only(bottom: 120, left: 80, right: 80),
        seekBarContainerHeight: 36,
        // seekBarHeight: 5,
        topButtonBarMargin:
            EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 30),
        topButtonBar: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                // 关闭
                IconButton(
                  icon: const Icon(Icons.close_sharp),
                  iconSize: IconTheme.of(context).size ?? 114,
                  color: Colors.white,
                  onPressed: () => {
                    Get.back(),
                  },
                ),
                // 全屏
                MaterialFullscreenButton(
                  icon: const Icon(Icons.fullscreen),
                  iconSize: IconTheme.of(context).size ?? 14,
                  iconColor: Colors.white,
                ),
              ],
            ),
          ),
          const Spacer(),
          // 更多信息
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              iconSize: IconTheme.of(context).size ?? 114,
              color: Colors.white,
              onPressed: () => {
                BottomSheetHelper.showBottomSheet(_buildDescription(),
                    expand: false),
              },
            ),
          ),

          /*Expanded(
            child: Obx(() {
              return Padding(
                padding: const EdgeInsets.only(right: 18.0),
                child: Text(
                  // _videoTitle.value,
                  CommonUtils.formatFileNme(controller.currentName.value),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          )*/
        ],
      ),
      fullscreen: MaterialVideoControlsThemeData(
        seekGesture: true,
        volumeGesture: true,
        brightnessGesture: true,
        seekOnDoubleTap: true,
        speedUpOnLongPress: true,
        verticalGestureSensitivity: 200,
        horizontalGestureSensitivity: 1000,
        controlsHoverDuration: const Duration(seconds: 5),
        // topBar
        topButtonBarMargin:
            EdgeInsets.only(left: MediaQuery.of(context).padding.left, top: 0),
        topButtonBar: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                // 关闭
                IconButton(
                  icon: const Icon(Icons.close_sharp),
                  iconSize: IconTheme.of(context).size ?? 114,
                  color: Colors.white,
                  onPressed: () => {
                    Get.back(),
                  },
                ),
                // 全屏
                MaterialFullscreenButton(
                  icon: const Icon(Icons.fullscreen),
                  iconSize: IconTheme.of(context).size ?? 14,
                  iconColor: Colors.white,
                ),
              ],
            ),
          ),
          const Spacer(),
          // 更多信息
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            margin:
                EdgeInsets.only(right: MediaQuery.of(context).padding.right),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              iconSize: IconTheme.of(context).size ?? 114,
              color: Colors.white,
              onPressed: () => {
                BottomSheetHelper.showBottomSheet(_buildDescription(),
                    expand: false),
              },
            ),
          ),
        ],

        // 播放列表
        primaryButtonBar: [
          // 播放列表
          Obx(() {
            return controller.showPlaylist.isTrue
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    margin: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).padding.left),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.list),
                      iconSize: IconTheme.of(context).size ?? 114,
                      color: Colors.white,
                      onPressed: () => {
                        BottomSheetHelper.showBottomSheet(_buildPlayList(),
                            expand: false),
                      },
                    ),
                  )
                : const Spacer();
          }),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            margin: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).padding.right),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(15),
            ),
            child: _buildPullDownButton(),
          )
        ],
        // bottomBar
        buttonBarHeight: 96,
        bottomButtonBarMargin: EdgeInsets.only(
            left: MediaQuery.of(context).padding.left,
            right: MediaQuery.of(context).padding.right,
            bottom: 0),
        bottomButtonBar: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
              // 设置背景色会遮挡触摸事件
              /*decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(15),
              ),*/
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Obx(() {
                        return Text(
                          '${controller.currentPos.value.label(reference: controller.currentPos.value)} ',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        );
                      }),
                      Obx(() {
                        return Text(
                          '${controller.duration.value.label(reference: controller.duration.value)} ',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        );
                      }),
                    ],
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Spacer(flex: 2),
                      MaterialSkipPreviousButton(),
                      Spacer(),
                      MaterialPlayOrPauseButton(iconSize: 48.0),
                      Spacer(),
                      MaterialSkipNextButton(),
                      Spacer(flex: 2),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
        // seekBar
        seekBarMargin: EdgeInsets.only(
            bottom: 72,
            left: MediaQuery.of(context).padding.left + 80,
            right: MediaQuery.of(context).padding.right + 80),
        seekBarContainerHeight: 36,
      ),
      child: PopScope(
        canPop: !isFullscreen(context),
        onPopInvokedWithResult: (didPop, result) {
          if (isFullscreen(context)) {
            exitFullscreen(context);
          }
        },
        child: Scaffold(
          body: Video(
            controller: controller.videoController,
            controls: MaterialVideoControls,
          ),
        ),
      ),
    );
  }

  // 简介
  Widget _buildDescription() {
    // 去除最后一个 /
    String path = controller.path;
    if (path != '/' && controller.path.endsWith('/')) {
      path = controller.path.substring(0, controller.path.length - 1);
    }

    // 文件大小
    final filesize =
        CommonUtils.formatFileSize(controller.currentObject.value.size!);

    // 文件类型
    final fileType = p
        .extension(controller.currentName.value)
        .replaceAll('.', '')
        .toUpperCase();

    // 格式化时间
    final modified = controller.currentObject.value.modified == null
        ? '-'
        : Jiffy.parseFromDateTime(controller.currentObject.value.modified!)
            .format(pattern: 'yyyy/MM/dd');

    // 挂载类型
    final provider = controller.currentObject.value.provider ?? '-';

    // 是否是横屏
    final isLandscape =
        MediaQuery.of(Get.context!).orientation == Orientation.landscape;

    return SingleChildScrollView(
      child: CupertinoPageScaffold(
        backgroundColor: CommonUtils.backgroundColor,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: CommonUtils.backgroundColor,
          transitionBetweenRoutes: false,
          border: Border.all(width: 0, color: Colors.transparent),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            child: Text('close'.tr),
            onPressed: () => Get.back(),
          ),
          middle: Text(
            CommonUtils.formatFileNme(controller.currentName.value),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Get.textTheme.bodyLarge,
          ),
        ),
        child: CupertinoListSection.insetGrouped(
          backgroundColor: CommonUtils.backgroundColor,
          dividerMargin: 0.w,
          additionalDividerMargin: 0.w,
          margin: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 10.w : 20, vertical: 20)
              .copyWith(bottom: 150.h),
          hasLeading: false,
          children: [
            _buildListTile(title: 'directory'.tr, additionalInfo: path),
            _buildListTile(title: 'mount_type'.tr, additionalInfo: provider!),
            _buildListTile(title: 'modify_time'.tr, additionalInfo: modified),
            _buildListTile(title: 'file_type'.tr, additionalInfo: fileType),
            _buildListTile(title: 'file_size'.tr, additionalInfo: filesize),
          ],
        ),
      ),
    );
  }

  // 播放列表
  Widget _buildPlayList() {
    return CupertinoPageScaffold(
      backgroundColor: CommonUtils.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CommonUtils.backgroundColor,
        transitionBetweenRoutes: false,
        border: Border.all(width: 0, color: Colors.transparent),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          child: Text('close'.tr),
          onPressed: () => Get.back(),
        ),
        middle: Text(
          'video_tab_playlist'.tr,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Get.textTheme.bodyLarge,
        ),
      ),
      child: SizedBox(
        height: 400,
        child: ListView.separated(
          shrinkWrap: true,
          separatorBuilder: (context, index) => Divider(
            height: 0.5,
            indent: CommonUtils.isPad ? 10 : 30.w,
            endIndent: CommonUtils.isPad ? 10 : 30.w,
          ),
          itemCount: controller.objects.length,
          itemBuilder: (context, index) {
            final object = controller.objects[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 播放模式按钮切换
                index == 0 && controller.showPlaylist.isTrue
                    ? _buildPlayModeButton()
                    : SizedBox.shrink(),
                CupertinoListTile(
                  title: Container(
                    width: 800.w,
                    child: Text(
                      CommonUtils.formatFileNme(object.name!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Get.textTheme.bodyLarge,
                    ),
                  ),
                  trailing: index == controller.currentIndex.value
                      ? _buildPlayIcon()
                      : null,
                  onTap: () {
                    Get.back();
                    controller.videoPlayer.jump(index);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 播放模式按钮 - 列表循环, 单集循环, 播完暂停
  Widget _buildPlayModeButton() {
    final isLandscape =
        MediaQuery.of(Get.context!).orientation == Orientation.landscape;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: CommonUtils.isPad ? 0 : 30.w,
        vertical: isLandscape ? 20.h : 30.h,
      ),
      child: ToggleSwitch(
        customWidths: const [50, 50, 50],
        inactiveBgColor: CommonUtils.backgroundColor,
        cornerRadius: 15,
        initialLabelIndex: controller.playMode.val,
        totalSwitches: 3,
        labels: const ['', '', ''],
        customIcons: const [
          Icon(
            CupertinoIcons.repeat,
            size: 20,
          ),
          Icon(CupertinoIcons.repeat_1, size: 20),
          Icon(CupertinoIcons.stop_circle, size: 20),
        ],
        onToggle: (index) {
          controller.playMode.val = index!;
          controller.changePlayMode(index);
        },
      ),
    );
  }

  /// ListTile
  /// [title] 标题
  /// [additionalInfo] 右侧信息
  Widget _buildListTile({
    required String title,
    required String additionalInfo,
  }) {
    return CupertinoListTile(
      title: Text(title, style: Get.textTheme.bodyLarge),
      padding: CommonUtils.isPad
          ? EdgeInsets.only(left: 10, right: 10)
          : EdgeInsets.only(left: 40.w, right: 30.w),
      additionalInfo: Container(
        width: MediaQuery.of(Get.context!).orientation == Orientation.portrait
            ? 500.w
            : 150.w,
        alignment: Alignment.centerRight,
        child: Text(
          additionalInfo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Get.textTheme.bodyLarge?.copyWith(color: Colors.grey),
        ),
      ),
    );
  }

  // 正在播放动画
  Widget _buildPlayIcon() {
    bar(f) => AudioWaveBar(heightFactor: f, color: Get.theme.primaryColor);

    // 是否是横屏
    final isLandscape =
        MediaQuery.of(Get.context!).orientation == Orientation.landscape;

    return AudioWave(
      height: 60.r,
      width: 60.r,
      spacing: CommonUtils.isPad && !isLandscape ? 3.5 : 1.5,
      animationLoop: 3,
      beatRate: const Duration(milliseconds: 150),
      bars: [bar(0.0), bar(0.3), bar(0.5), bar(0.3), bar(0.7), bar(0.2)],
    );
  }

  // 竖屏信息
  Widget _buildPortraitInfo(Widget videoPlayer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16.0 / 9.0,
          child: videoPlayer,
        ),
        // Container(
        //   height: CommonUtils.isPad ? 700.h : 520.h,
        //   child: videoPlayer,
        // ),
        Container(
          constraints: BoxConstraints.expand(height: 120.h),
          child: TabBar(
            tabs: [
              Tab(text: 'video_tab_introduction'.tr),
              Tab(text: 'video_tab_playlist'.tr),
            ],
            labelColor: Get.textTheme.bodyLarge?.color,
            unselectedLabelColor: Get.textTheme.bodyLarge?.color,
            indicatorColor: Get.theme.primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 5.r,
            labelStyle: Get.textTheme.titleMedium,
            unselectedLabelStyle: Get.textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              _buildDescription(),
              _buildPlayList(),
            ],
          ),
        ),
      ],
    );
  }

  /// 桌面端播放器配置
  Widget _buildComputerPlayer(BuildContext context) {
    return MaterialDesktopVideoControlsTheme(
      key: const ObjectKey("mac"),
      normal: MaterialDesktopVideoControlsThemeData(
        visibleOnMount: true,
        controlsHoverDuration: const Duration(seconds: 5),
        topButtonBar: [
          MaterialCustomButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            iconSize: IconTheme.of(context).size ?? 14,
            iconColor: Colors.white,
            onPressed: () => Get.back(),
          ),
          /*Expanded(
            child: Obx(() {
              return Padding(
                padding: const EdgeInsets.only(right: 18.0),
                child: Text(
                  _videoTitle.value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          )*/
        ],
      ),
      fullscreen: MaterialDesktopVideoControlsThemeData(
        visibleOnMount: true,
        controlsHoverDuration: const Duration(seconds: 5),
        topButtonBar: [
          MaterialFullscreenButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            iconSize: IconTheme.of(context).size ?? 14,
            iconColor: Colors.white,
          ),
          /*Expanded(
            child: Obx(() {
              return Padding(
                padding: const EdgeInsets.only(right: 18.0),
                child: Text(
                  _videoTitle.value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ),*/
        ],
      ),
      child: PopScope(
        canPop: !isFullscreen(context),
        onPopInvoked: (didPop) {
          if (isFullscreen(context)) {
            exitFullscreen(context);
          }
        },
        child: Scaffold(
          body: Video(
            key: const ObjectKey("video"),
            controller: controller.videoController,
            // controls: CupertinoVideoControls,
            controls: MaterialDesktopVideoControls,
            // width: MediaQuery.of(context).size.width,
            // height: MediaQuery.of(context).size.height,
          ),
        ),
      ),
    );
  }

  /// 横屏页面信息
  Widget _buildLandscapeInfo(Widget videoPlayer) {
    return Row(
      children: [
        Container(width: 780.w, child: videoPlayer),
        Expanded(
          child: Column(
            children: [
              SizedBox(height: 30.h),
              _buildDescription(),
              Divider(height: 1.r, indent: 10, endIndent: 10),
              SizedBox(height: 20.h),
              Expanded(child: _buildPlayList()),
            ],
          ),
        ),
      ],
    );
  }
}
