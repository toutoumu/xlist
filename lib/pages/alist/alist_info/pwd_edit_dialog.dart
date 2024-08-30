import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 密码编辑对话框
class PwdEditDialog extends StatefulWidget {
  final ValueChanged<String> onConfirm;
  final String? password;

  const PwdEditDialog({super.key, required this.onConfirm, this.password});

  @override
  State<PwdEditDialog> createState() {
    return _PwdEditDialogState();
  }
}

class _PwdEditDialogState extends State<PwdEditDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController pwdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    pwdController.text = widget.password ?? "";
  }

  @override
  void dispose() {
    pwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text("修改admin密码"),
      content: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoTextField(
              controller: pwdController,
              placeholder: "admin密码",
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
          },
          child: const Text("取消"),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            widget.onConfirm(pwdController.text);
          },
          child: const Text("确定"),
        ),
      ],
    );
  }
}
