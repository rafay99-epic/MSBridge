import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/features/setting/section/danger_section/delete/delete.dart';
import 'package:msbridge/widgets/buildSettingsTile.dart';
import 'package:msbridge/widgets/warning_dialog_box.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

class DangerSettingsSection extends StatelessWidget {
  const DangerSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account Management
        buildSubsectionHeader(context, "Account Management", LineIcons.trash),
        const SizedBox(height: 12),
        buildSettingsTile(
          context,
          title: "Delete Account",
          subtitle: "Permanently remove your account and all data",
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

        const SizedBox(height: 24),

        // App Reset
        buildSubsectionHeader(context, "App Reset", LineIcons.redo),
        const SizedBox(height: 12),
        buildSettingsTile(
          context,
          title: "Reset App Theme",
          subtitle: "Restore default theme settings",
          icon: Icons.palette_outlined,
          onTap: () {
            showConfirmationDialog(
              context,
              Theme.of(context),
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

  Widget buildSubsectionHeader(
      BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}
