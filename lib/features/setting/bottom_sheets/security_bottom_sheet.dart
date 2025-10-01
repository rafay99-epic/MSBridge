// features/setting/bottom_sheets/security_bottom_sheet.dart

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:msbridge/features/setting/bottom_sheets/components/bottom_sheet_base.dart';
import 'package:msbridge/features/setting/section/pin/pin_setting.dart';

class SecurityBottomSheet extends StatelessWidget {
  const SecurityBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const BottomSheetBase(
      title: "Security Settings",
      content: PinSetup(),
    );
  }
}
