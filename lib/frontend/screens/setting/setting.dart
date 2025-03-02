import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/frontend/screens/setting/logout/logout_dialog.dart';
import 'package:msbridge/frontend/screens/setting/settings_section.dart';
import 'package:msbridge/frontend/screens/setting/settings_tile.dart';

class Setting extends StatelessWidget {
  const Setting({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Settings"),
        automaticallyImplyLeading: false,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SettingsSection(title: "User Settings", children: [
            SettingsTile(
              title: "Logout",
              icon: LineIcons.alternateSignOut,
              onTap: () => showLogoutDialog(context),
            ),
            SettingsTile(
              title: "Change Password",
              icon: LineIcons.lock,
              onTap: () => {},
            ),
          ]),
          Divider(color: theme.colorScheme.primary),
          SettingsSection(title: "App Info", children: [
            const SettingsTile(title: "Environment", icon: LineIcons.cogs),
            const SettingsTile(
                title: "App Version: 1.0.0", icon: LineIcons.infoCircle),
            const SettingsTile(title: "App Build: 1001", icon: LineIcons.tools),
            SettingsTile(
              title: "Contact Us",
              icon: LineIcons.envelope,
              onTap: () => {},
            ),
          ]),
          Divider(color: theme.colorScheme.primary),
          SettingsSection(title: "Danger", children: [
            SettingsTile(
              title: "Delete Account",
              icon: LineIcons.trash,
              onTap: () => {},
            ),
          ]),
        ],
      ),
    );
  }
}
