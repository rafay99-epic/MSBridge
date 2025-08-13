import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/config/feature_flag.dart';
import 'package:msbridge/features/setting/pages/app_info_page.dart';
import 'package:msbridge/features/setting/section/admin_section/admin_settings_section.dart';
import 'package:msbridge/features/setting/section/appearance_section/appearance_settings_section.dart';
import 'package:msbridge/features/setting/section/danger_section/danger_settings_section.dart';
import 'package:msbridge/features/setting/section/note_section/notes_setting_section.dart';
import 'package:msbridge/features/setting/section/user_section/user_settings_section.dart';
import 'package:msbridge/features/update_app/update_app.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/buildSectionHeader.dart';
import 'package:msbridge/widgets/buildSettingsTile.dart';
import 'package:page_transition/page_transition.dart';

class Setting extends StatelessWidget {
  const Setting({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(title: "Settings"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.secondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LineIcons.cog,
                      size: 32,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "App Configuration",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Customize your MS Bridge experience",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Personalization Section
            buildSectionHeader(context, "Personalization", LineIcons.user),
            const SizedBox(height: 16),
            const AppearanceSettingsSection(),
            const SizedBox(height: 16),
            const UserSettingsSection(),

            const SizedBox(height: 32),

            // Notes & Sync Section
            buildSectionHeader(context, "Notes & Sync", LineIcons.book),
            const SizedBox(height: 16),
            const NotesSetting(),

            const SizedBox(height: 32),

            // System Section
            buildSectionHeader(context, "System", LineIcons.cog),
            const SizedBox(height: 16),
            if (FeatureFlag.enableInAppUpdate)
              buildSettingsTile(
                context,
                title: "App Updates",
                icon: LineIcons.download,
                subtitle: "Download latest versions",
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
            if (FeatureFlag.enableInAppUpdate) const SizedBox(height: 16),
            buildSettingsTile(
              context,
              title: "App Information",
              icon: LineIcons.info,
              subtitle: "Version details and support",
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

            const SizedBox(height: 32),

            // Danger Zone Section
            buildSectionHeader(
                context, "Danger Zone", LineIcons.exclamationTriangle,
                isDanger: true),
            const SizedBox(height: 16),
            const DangerSettingsSection(),

            const SizedBox(height: 32),

            // Admin Section (if needed)
            if (true) // You can add a condition here
              Column(
                children: [
                  buildSectionHeader(
                      context, "Administration", LineIcons.userShield),
                  const SizedBox(height: 16),
                  const AdminSettingsSection(),
                  const SizedBox(height: 24),
                ],
              ),

            // Footer
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  '© Syntax Lab Technology ${DateTime.now().year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.primary.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
