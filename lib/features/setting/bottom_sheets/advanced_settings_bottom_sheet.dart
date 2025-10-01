// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:line_icons/line_icons.dart';
import 'package:page_transition/page_transition.dart';

// Project imports:
import 'package:msbridge/features/setting/bottom_sheets/components/bottom_sheet_base.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_action_tile.dart';
import 'package:msbridge/features/setting/pages/settings_sync_page.dart';

class AdvancedSettingsBottomSheet extends StatelessWidget {
  const AdvancedSettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomSheetBase(
      title: 'Advanced Settings',
      content: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingActionTile(
          title: 'Settings Sync',
          subtitle:
              'Manage syncing of app settings (cloud, force sync, export/import)',
          icon: LineIcons.cloud,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const SettingsSyncPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}
