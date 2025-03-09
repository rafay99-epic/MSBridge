import 'package:flutter/material.dart';
import 'package:msbridge/features/setting/section/app_info_settings_section.dart';
import 'package:msbridge/features/setting/section/appearance_section/appearance_settings_section.dart';
import 'package:msbridge/features/setting/section/connectivity_settings_section.dart';
import 'package:msbridge/widgets/appbar.dart';

class OfflineSetting extends StatelessWidget {
  const OfflineSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(title: "Settings"),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const AppearanceSettingsSection(),
          Divider(color: theme.colorScheme.primary),
          const ConnectivitySettingsSection(),
          Divider(color: theme.colorScheme.primary),
          const AppInfoSettingsSection()
        ],
      ),
    );
  }
}
