import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:xlist/common/utils.dart';
import 'package:xlist/database/entity/index.dart';
import 'package:xlist/helper/index.dart';
import 'package:xlist/models/index.dart';
import 'package:xlist/repositorys/index.dart';
import 'package:xlist/services/index.dart';
import 'package:xlist/storages/index.dart';

class VideoPlayerMediaKitController extends SuperController {
  final userInfo = UserModel().obs; // 用户信息
  final httpHeaders = <String, String>{}.obs;
  final serverId = Get.find<UserStorage>().serverId.val.obs;
  final isLoading = true.obs; // 是否正在加载
  final isAutoPaused = false.obs; // 是否自动暂停

  final timedTextTracks = <SubtitleTrack>[].obs; // 内置字幕
  final subtitleNameList = <String>[].obs; // 外置字幕文件名列表

  final audioTracks = <AudioTrack>[].obs; // 音轨

  final subtitleName = ''.obs; // 当前字幕文件名
  final currentObject = ObjectModel().obs; // 当前播放文件
  final currentName = ''.obs; // 当前播放文件名
  final currentIndex = 0.obs; // 当前播放文件下标

  final showPlaylist = false.obs; // 是否显示播放列表
  final buffering = true.obs; // 是否缓存中
  final thumbnail = ''.obs; // 视频缩略图
  final currentPos = const Duration(seconds: 0).obs; // 当前播放进度
  final duration = const Duration(seconds: 0).obs; // 视频长度

  // 自动播放
  final isAutoPlay = Get.find<PreferencesStorage>().isAutoPlay.val;

  // 后台播放
  final isBackgroundPlay = Get.find<PreferencesStorage>().isBackgroundPlay.val;

  // 播放模式
  final playMode = Get.find<PreferencesStorage>().playMode;

  // 获取参数
  final String path = Get.arguments['path'] ?? '';
  final String name = Get.arguments['name'] ?? '';
  List<ObjectModel> objects = Get.arguments['objects'] ?? [];

  // 下载页面点击
  final String file = Get.arguments['file'] ?? '';
  final int downloadId = Get.arguments['downloadId'] ?? 0;

  // 用于记录视频播放进度
  int _progressId = 0; // 进记录 ID
  int _currentPos = 0; // 当前播放进度
  int _duration = 0; // 视频长度

  // 播放器
  late final videoPlayer = Player();
  late final videoController = VideoController(videoPlayer);

  @override
  void onInit() async {
    super.onInit();

    // 过滤掉非视频文件
    objects = objects.where((o) => PreviewHelper.isVideo(o.name!)).toList();
    userInfo.value = await UserRepository.me(); // 获取用户信息

    // 当前播放文件名
    currentName.value = name;
    currentIndex.value = objects.indexWhere((o) => o.name == name); // 当前播放文件下标
    showPlaylist.value = objects.length > 1; // 是否显示播放列表

    // 获取服务器 id
    if (Get.arguments['serverId'] != null) {
      serverId.value = Get.arguments['serverId'] ?? 0;
    }

    // 获取视频播放地址
    try {
      if (file.isEmpty) {
        // 网盘文件
        currentObject.value = await ObjectRepository.get(path: '$path$name');
        // 获取同级目录下的字幕
        _updateSubtitleNameList(currentObject.value.related ?? []);
        thumbnail.value = currentObject.value.thumb ?? '';
      } else {
        // 本地下载的文件
        final download = await DatabaseService.to.database.downloadDao
            .findDownloadById(downloadId);
        currentObject.value = ObjectModel.fromJson({
          'name': download?.name,
          'type': download?.type,
          'size': download?.size,
          'raw_url': 'file://$file',
        });

        // 获取同级目录下的字幕
        var value = await ObjectRepository.get(path: '$path$name');
        _updateSubtitleNameList(value.related ?? []);
        thumbnail.value = value.thumb ?? '';
      }
    } catch (e) {
      SmartDialog.showToast('toast_get_object_fail'.tr);
      return;
    }

    // 获取当前播放文件的播放记录
    await _getViewingRecord();

    // 初始化播放器
    _initListener();
    if (objects.isNotEmpty) {
      _startPlay(objects);
    } else {
      // 本地文件
      _startPlay([currentObject.value]);
    }

    // 加入最近浏览
    await CommonUtils.addRecent(currentObject.value, path, name);

    // 绑定进度监听
    DownloadService.to.bindBackgroundIsolate((id, status, progress) {});

    isLoading.value = false; // 加载完成
  }

  // 初始视频状态化监听
  void _initListener() {
    videoPlayer.stream.playing.listen((plaing) {
      if (plaing) {
        _startTimer();
      } else {
        _stopTimer();
      }
    });
    // 当前视频播放完成监听
    videoPlayer.stream.completed.listen((completed) async {
      if (!completed) {
        return;
      }
      // 播放完成
      print('播放完成: $_progressId');

      _stopTimer();
      // 更新播放进度 - 重置
      await _saveViewingRecord(0, _duration);
    });
    // 当前播放的视频
    videoPlayer.stream.playlist.listen((event) async {
      print('当前播放的视频: ${event.index}');
      await _changePlaylist(event.index);
    });
    // 当前播放进度监听
    videoPlayer.stream.position.listen((event) {
      // 如果视频长度未获取到那么不处理
      _currentPos = event.inMilliseconds;
      // 更新当前播放进度
      currentPos.value = event;
    });
    // 视频长度监听
    videoPlayer.stream.duration.listen((event) {
      _duration = event.inMilliseconds;
      // 更新视频长度
      duration.value = event;
      print('视频长度: $_duration');
    });
    // 视频缓存监听
    videoPlayer.stream.buffering.listen((event) {
      buffering.value = event;
      print('缓存中: $buffering');
    });
    // 音轨,字幕监听
    videoPlayer.stream.tracks.listen((event) async {
      // 内置字幕
      timedTextTracks.value = event.subtitle.where((o) {
        return o.id != 'auto' && o.id != 'no';
      }).toList();
      // 内置音频
      audioTracks.value = event.audio.where((o) {
        return o.id != 'auto' && o.id != 'no';
      }).toList();
    });
  }

  /// 初始化播放文件
  void _startPlay(List<ObjectModel> objects) async {
    if (objects.isEmpty) {
      return;
    }
    // 组织播放列表
    var playList = <Media>[];
    // 注意不要用 forEach 循环，不会同步执行
    for (var element in objects) {
      // 查询文件信息
      var object = await ObjectRepository.get(path: '$path${element.name}');
      if (object.rawUrl != null) {
        // 获取请求头
        var httpHeaders =
            DriverHelper.getHeaders(object.provider, object.rawUrl);
        // 查询文件上次播放到的位置
        final progress = await DatabaseService.to.database.progressDao
            .findProgressByServerIdAndPath(
                serverId.value, path, object.name ?? '');
        var start = Duration(milliseconds: progress?.currentPos ?? 0);
        playList
            .add(Media(object.rawUrl!, httpHeaders: httpHeaders, start: start));
      }
    }
    // 播放
    final playable = Playlist(playList, index: currentIndex.value);
    await videoPlayer.open(playable, play: isAutoPlay);
  }

  /// 切换播放列表文件
  /// [index] 下标
  Future _changePlaylist(int index) async {
    final newObject = objects[index];
    if (newObject.name == currentName.value) {
      // SmartDialog.showToast('toast_current_play_file'.tr);
      return;
    }
    currentObject.value = ObjectModel();
    // 获取视频播放地址
    SmartDialog.showLoading(
      builder: (context) =>
          const CupertinoActivityIndicator(color: Colors.white, radius: 20),
    );

    ObjectModel tempObj;
    try {
      tempObj = await ObjectRepository.get(path: '$path${newObject.name}');
      thumbnail.value = tempObj.thumb ?? '';
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast(e.toString());
      return;
    }

    // 更新初始化信息
    currentIndex.value = index;
    currentName.value = newObject.name!;
    isAutoPaused.value = false;
    audioTracks.clear();
    timedTextTracks.clear();
    subtitleNameList.clear();

    // 获取字幕文件名列表
    _updateSubtitleNameList(tempObj.related ?? []);

    // 重置播放器信息
    SmartDialog.dismiss();

    await _getViewingRecord(); // 更新播放进度

    // 加入最近浏览
    await CommonUtils.addRecent(tempObj, path, newObject.name!);

    currentObject.value = tempObj;
    SmartDialog.showToast('toast_switch_success'.tr);
  }

  /// 切换音轨
  void changeAudioTrack({String? value}) async {
    value ??= await showModalActionSheet(
      context: Get.overlayContext!,
      title: 'video_switch_audio'.tr,
      actions: [
        ...audioTracks.map(
          (v) => SheetAction(
            label: '${v.title}(${v.language})',
            key: v.id,
          ),
        ),
      ],
      cancelLabel: 'cancel'.tr,
    );

    if (value != null) {
      var itemIndex = audioTracks.indexWhere((element) {
        return element.id == value;
      });
      await videoController.player.setAudioTrack(audioTracks[itemIndex]);
      // SmartDialog.showToast('toast_current_audio_track'.tr);
      SmartDialog.showToast('toast_switch_success'.tr);
    }
  }

  /// 切换字幕
  void changeSubtitle({String? value}) async {
    value ??= await showModalActionSheet(
      context: Get.overlayContext!,
      materialConfiguration: const MaterialModalActionSheetConfiguration(),
      title: 'video_switch_subtitle'.tr,
      actions: [
        // 外置字幕
        ...subtitleNameList.map(
          (v) => SheetAction(label: v, key: v),
        ),
        // 内置字幕
        ...timedTextTracks.map(
          (v) => SheetAction(
            label: '${v.title ?? "未知"}(${v.language ?? "未知"})',
            key: 'internal::${v.id}',
          ),
        ),
        // 关闭字幕
        SheetAction(
          label: 'fijkplayer_subtitle_close'.tr,
          key: 'close',
          isDestructiveAction: true,
        ),
      ],
      cancelLabel: 'cancel'.tr,
    );
    if (value == null) return;

    // 关闭字幕
    if (value == 'close') {
      await videoController.player.setSubtitleTrack(SubtitleTrack.no());
      SmartDialog.showToast('toast_subtitle_closed'.tr);
      return;
    }

    // 切换内置字幕
    if (value.startsWith('internal::')) {
      final itemId = value.replaceAll('internal::', '');
      var itemIndex = timedTextTracks.indexWhere((element) {
        return element.id == itemId;
      });
      await videoController.player.setSubtitleTrack(timedTextTracks[itemIndex]);
      // SmartDialog.showToast('toast_current_subtitle'.tr);
      SmartDialog.showToast('toast_switch_success'.tr);
      return;
    }

    // 外挂字幕
    try {
      SmartDialog.showLoading(msg: 'toast_switch_loading'.tr);

      final outSubtitleObject = await ObjectRepository.get(path: '$path$value');
      final subtitle = SubtitleTrack.uri(outSubtitleObject.rawUrl ?? '');
      await videoController.player.setSubtitleTrack(subtitle);

      SmartDialog.dismiss();
      SmartDialog.showToast('toast_switch_success'.tr);
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('toast_switch_subtitle_fail'.tr);
    }
  }

  /// 收藏
  void favorite() async {
    await CommonUtils.addFavorite(
      currentObject.value,
      path,
      currentName.value,
    );
  }

  /// 复制链接
  void copyLink() {
    Clipboard.setData(ClipboardData(
      text: CommonUtils.getDownloadLink(
        path,
        object: currentObject.value,
        userInfo: userInfo.value,
      ),
    ));
    SmartDialog.showToast('toast_copy_success'.tr);
  }

  /// 下载文件
  void download() async {
    DownloadHelper.file(
      path,
      currentName.value,
      currentObject.value.type!,
      currentObject.value.size!,
    );
  }

  /// 修改播放模式
  void changePlayMode(int index) {
    // static const LIST_LOOP = 0;
    // static const SINGLE_LOOP = 1;
    // static const PLAY_PAUSE = 2;
    // static const SHUFFLE = 3;
    switch (index) {
      case 0:
        videoPlayer.setPlaylistMode(PlaylistMode.loop); // 列表循环
      case 1:
        videoPlayer.setPlaylistMode(PlaylistMode.single); // 单个循环
      default:
        videoPlayer.setPlaylistMode(PlaylistMode.none); // 列表播一次
    }
  }

  @override
  void onPaused() {
    // 播放中且配置不允许后台播放才暂停
    if (videoPlayer.state.playing && !isBackgroundPlay) {
      isAutoPaused.value = true;
      videoPlayer.pause();
    }
  }

  @override
  void onResumed() {
    videoPlayer.play();
    videoPlayer.seek(Duration(milliseconds: _currentPos));
  }

  @override
  void onInactive() {}

  @override
  void onDetached() {}

  @override
  void onHidden() {}

  @override
  void onClose() {
    super.onClose();
    videoPlayer.dispose();
    _stopTimer();

    DownloadService.to.unbindBackgroundIsolate();
    WakelockPlus.disable();
  }

  /// 更新外挂字幕文件名列表
  void _updateSubtitleNameList(List<ObjectModel> related) {
    subtitleNameList.clear();
    for (var v in related) {
      final ext = p.extension(v.name!).toLowerCase();
      if (ext == '.vtt' || ext == '.srt' || ext == '.ass') {
        subtitleNameList.add(v.name!);
      }
    }
  }

  Timer? _timer;

  /// 定时器,定时更新播放进度
  void _startTimer() async {
    // 每五秒记录一下播放进度
    print('开始记录播放进度');
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      print('每五秒记录一下播放进度: $_currentPos');
      await _saveViewingRecord(_currentPos, _duration);
    });
  }

  /// 停止定时器
  void _stopTimer() async {
    _timer?.cancel();
    _timer = null;
    print('停止记录播放进度');
  }

  /// 获取播放记录(ID)
  Future<void> _getViewingRecord() async {
    final progress = await DatabaseService.to.database.progressDao
        .findProgressByServerIdAndPath(serverId.value, path, currentName.value);

    if (progress != null) {
      _progressId = progress.id!;
      return;
    }
    // 如果不存在则插入, 返回自增ID
    _progressId = await DatabaseService.to.database.progressDao.insertProgress(
      ProgressEntity(
        serverId: serverId.value,
        path: path,
        name: currentName.value,
        currentPos: 0,
      ),
    );
  }

  /// 保存播放位置
  Future<void> _saveViewingRecord(int currentPos, int duration) async {
    await DatabaseService.to.database.progressDao.updateProgress(
      ProgressEntity(
        id: _progressId,
        serverId: serverId.value,
        path: path,
        name: currentName.value,
        currentPos: currentPos,
      ),
    );
  }
}
