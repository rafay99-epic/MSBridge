import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/features/setting/widgets/settings_section.dart';
import 'package:msbridge/features/setting/widgets/settings_tile.dart';
import 'package:msbridge/features/setting/section/appearance_section/theme/theme_selector.dart';
import 'package:provider/provider.dart';

class AppearanceSettingsSection extends StatelessWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SettingsSection(
      title: "Appearance",
      children: [
        SettingsTile(
          title: "Choose Theme",
          icon: LineIcons.palette,
          child: ThemeSelector(themeProvider: themeProvider),
        ),
      ],
    );
  }
}
