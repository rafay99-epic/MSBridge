import 'package:flutter/material.dart';
import 'package:msbridge/features/offline/setting/sections/connectivity_section/connectivity_section.dart';
import 'package:msbridge/features/setting/section/appinfo_section/app_info_settings_section.dart';
import 'package:msbridge/features/setting/section/appearance_section/appearance_settings_section.dart';
import 'package:msbridge/features/setting/section/note_section/notes_setting_section.dart';
import 'package:msbridge/widgets/appbar.dart';

class OfflineSetting extends StatelessWidget {
  const OfflineSetting({super.key});

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
                const NotesSetting(),
                Divider(color: theme.colorScheme.primary),
                const OfflineConnectivity(),
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
