import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/features/setting/section/danger_section/delete/delete.dart';
import 'package:msbridge/features/setting/widgets/settings_section.dart';
import 'package:msbridge/features/setting/widgets/settings_tile.dart';
import 'package:msbridge/widgets/warning_dialog_box.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

class DangerSettingsSection extends StatelessWidget {
  const DangerSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SettingsSection(
      title: "Danger",
      children: [
        SettingsTile(
          title: "Delete Account",
          icon: LineIcons.trash,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const DeleteAccountScreen(),
              ),
            );
          },
        ),
        SettingsTile(
          title: "Reset App Theme ",
          icon: Icons.palette_outlined,
          onTap: () {
            showConfirmationDialog(
              context,
              theme,
              () async {
                await themeProvider.resetTheme();
              },
              "Reset App Theme",
              "Are you sure you want to reset App Theme?",
            );
          },
        ),
      ],
    );
  }
}
