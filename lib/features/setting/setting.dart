import 'package:flutter/material.dart';
import 'package:msbridge/features/setting/section/admin_settings_section.dart';
import 'package:msbridge/features/setting/section/app_info_settings_section.dart';
import 'package:msbridge/features/setting/section/appearance_section/appearance_settings_section.dart';
import 'package:msbridge/features/setting/section/connectivity_settings_section.dart';
import 'package:msbridge/features/setting/section/danger_section/danger_settings_section.dart';
import 'package:msbridge/features/setting/section/notes_setting_section.dart';
import 'package:msbridge/features/setting/section/user_section/user_settings_section.dart';
import 'package:msbridge/widgets/appbar.dart';

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
                const ConnectivitySettingsSection(),
                const AdminSettingsSection(),
                Divider(color: theme.colorScheme.primary),
                const DangerSettingsSection(),
                Divider(color: theme.colorScheme.primary),
                const AppInfoSettingsSection(),
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
