import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/frontend/screens/changePassword/change_password.dart';
import 'package:msbridge/frontend/screens/contact/contact.dart';
import 'package:msbridge/frontend/screens/setting/delete/delete.dart';
import 'package:msbridge/frontend/screens/setting/logout/logout_dialog.dart';
import 'package:msbridge/frontend/screens/setting/settings_section.dart';
import 'package:msbridge/frontend/screens/setting/settings_tile.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:page_transition/page_transition.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  String appVersion = "Loading...";
  String buildVersion = "Loading...";

  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        appVersion = packageInfo.version;
        buildVersion = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        appVersion = 'Not available';
        buildVersion = 'Not available';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

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
              onTap: () => {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: const Changepassword(),
                  ),
                )
              },
            ),
          ]),
          Divider(color: theme.colorScheme.primary),
          SettingsSection(title: "App Info", children: [
            const SettingsTile(
                title: "Environment:",
                versionNumber: "Production",
                icon: LineIcons.cogs),
            SettingsTile(
              title: "App Version:",
              icon: LineIcons.infoCircle,
              versionNumber: appVersion,
            ),
            SettingsTile(
              title: "App Build: ",
              icon: LineIcons.tools,
              versionNumber: buildVersion,
            ),
            SettingsTile(
              title: "Contact Us",
              icon: LineIcons.envelope,
              onTap: () => {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: ContactPage(),
                  ),
                )
              },
            ),
          ]),
          Divider(color: theme.colorScheme.primary),
          SettingsSection(title: "Danger", children: [
            SettingsTile(
              title: "Delete Account",
              icon: LineIcons.trash,
              onTap: () => {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: const DeleteAccountScreen(),
                  ),
                )
              },
            ),
          ]),
        ],
      ),
    );
  }
}
