import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    return AlertDialog(
      title: const Text("修改admin密码"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: pwdController,
            decoration: const InputDecoration(
              labelText: "admin密码",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {Get.back();},
          child: const Text("取消"),
        ),
        FilledButton(
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
