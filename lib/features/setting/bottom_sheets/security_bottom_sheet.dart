// features/setting/bottom_sheets/security_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/bottom_sheet_base.dart';
import 'package:msbridge/features/setting/section/pin_lock/pin_setting.dart';

class SecurityBottomSheet extends StatelessWidget {
  const SecurityBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const BottomSheetBase(
      title: "Security Settings",
      content: PinSetting(),
    );
  }
}
