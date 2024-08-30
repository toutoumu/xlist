import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xlist/generated_api.dart';
import 'package:xlist/pages/alist/contant/native_bridge.dart';


class AlistInfoLogic extends GetxController {
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

    // _password.value = await NativeBridge.android.getAdminPassword();
    // _userName.value = await NativeBridge.android.getAdminUsername();
    // _wIp.value = await NativeBridge.android.getOutboundIPString();
    // _port.value = await NativeBridge.android.getAListHttpPort();

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