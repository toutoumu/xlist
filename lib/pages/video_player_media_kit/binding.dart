import 'package:get/get.dart';

import 'index.dart';

class VideoPlayerMediaKitBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VideoPlayerMediaKitController>(() => VideoPlayerMediaKitController());
  }
}
