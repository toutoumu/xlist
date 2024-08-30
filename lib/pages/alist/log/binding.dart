import 'package:get/get.dart';

import 'logic.dart';

class LogBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LogLogic());
  }
}
