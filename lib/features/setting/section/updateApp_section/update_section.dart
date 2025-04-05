import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/features/setting/widgets/settings_section.dart';
import 'package:msbridge/features/setting/widgets/settings_tile.dart';
import 'package:msbridge/features/update_app/update_app.dart';
import 'package:page_transition/page_transition.dart';

class AppUpdateSettingsSection extends StatelessWidget {
  const AppUpdateSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SettingsSection(
      title: "App Update Settings",
      children: [
        Divider(color: theme.colorScheme.primary),
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
      ],
    );
  }
}
