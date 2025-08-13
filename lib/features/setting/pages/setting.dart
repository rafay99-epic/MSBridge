import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/config/feature_flag.dart';
import 'package:msbridge/features/setting/pages/app_info_page.dart';
import 'package:msbridge/features/setting/section/admin_section/admin_settings_section.dart';
import 'package:msbridge/features/setting/section/appearance_section/appearance_settings_section.dart';
import 'package:msbridge/features/setting/section/danger_section/danger_settings_section.dart';
import 'package:msbridge/features/setting/section/note_section/notes_setting_section.dart';
import 'package:msbridge/features/setting/section/updateApp_section/update_section.dart';
import 'package:msbridge/features/setting/section/user_section/user_settings_section.dart';
import 'package:msbridge/features/setting/widgets/settings_tile.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:msbridge/features/setting/pages/shared_notes_page.dart';

class Setting extends StatelessWidget {
  const Setting({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(title: "Settings"),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const AppearanceSettingsSection(),
                Divider(color: theme.colorScheme.primary),
                const UserSettingsSection(),
                Divider(color: theme.colorScheme.primary),
                const NotesSetting(),
                Divider(color: theme.colorScheme.primary),
                const DangerSettingsSection(),
                if (FeatureFlag.enableInAppUpdate)
                  const AppUpdateSettingsSection(),
                Divider(color: theme.colorScheme.primary),
                SettingsTile(
                  title: "App Info",
                  icon: LineIcons.info,
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: const AppInfoPage(),
                      ),
                    );
                  },
                ),
                const AdminSettingsSection(),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '© Syntax Lab Technology ${DateTime.now().year}',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
