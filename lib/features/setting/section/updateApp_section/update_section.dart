import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/features/setting/pages/app_info_page.dart';
import 'package:msbridge/features/setting/widgets/settings_section.dart';
import 'package:msbridge/features/setting/widgets/settings_tile.dart';
import 'package:msbridge/features/update_app/update_app.dart';
import 'package:page_transition/page_transition.dart';

class AppUpdateSettingsSection extends StatelessWidget {
  const AppUpdateSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: "App Update Settings",
      children: [
        SettingsTile(
          title: "Update App",
          icon: LineIcons.arrowCircleDown,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const UpdateApp(),
              ),
            );
          },
        ),
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
      ],
    );
  }
}
