import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/features/setting/settings_section.dart';
import 'package:msbridge/features/setting/settings_tile.dart';
import 'package:msbridge/features/setting/theme/theme_selector.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class OfflineSetting extends StatefulWidget {
  const OfflineSetting({super.key});

  @override
  State<OfflineSetting> createState() => _OfflineSettingState();
}

class _OfflineSettingState extends State<OfflineSetting> {
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(title: "Settings"),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SettingsSection(
            title: "Appearance",
            children: [
              SettingsTile(
                title: "Choose Theme",
                icon: LineIcons.palette,
                child: ThemeSelector(themeProvider: themeProvider),
              ),
            ],
          ),
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
          ]),
        ],
      ),
    );
  }
}
