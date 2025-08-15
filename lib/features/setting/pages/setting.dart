import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/config/feature_flag.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/features/setting/pages/app_info_page.dart';
import 'package:msbridge/features/setting/section/admin_section/admin_settings_section.dart';
import 'package:msbridge/features/setting/section/appearance_section/appearance_settings_page.dart';
import 'package:msbridge/features/setting/section/danger_section/danger_settings_section.dart';

import 'package:msbridge/features/setting/section/user_section/user_settings_section.dart';
import 'package:msbridge/features/update_app/update_app.dart';
import 'package:msbridge/features/profile/profile_edit_page.dart';
import 'package:msbridge/features/ai_chat/chat_page.dart';
import 'package:msbridge/core/services/sync/note_taking_sync.dart';
import 'package:msbridge/core/services/backup_service.dart';
import 'package:msbridge/features/notes_taking/recyclebin/recycle.dart';
import 'package:msbridge/core/provider/sync_settings_provider.dart';
import 'package:msbridge/core/services/sync/reverse_sync.dart';
import 'package:msbridge/core/services/sync/auto_sync_scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:msbridge/core/provider/auto_save_note_provider.dart';
import 'package:msbridge/core/provider/chat_history_provider.dart';
import 'package:msbridge/core/provider/share_link_provider.dart';
import 'package:msbridge/features/setting/section/note_section/ai_model_selection.dart';
import 'package:msbridge/features/setting/pages/shared_notes_page.dart';
import 'package:msbridge/core/repo/share_repo.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: const CustomAppBar(title: "Settings"),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Profile Header Section
              _buildProfileHeader(context, theme, colorScheme),

              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(context, theme, colorScheme),

              const SizedBox(height: 24),

              // Main Settings Sections
              _buildSettingsSection(
                context,
                "Account & Security",
                [
                  _buildSettingsTile(
                    context,
                    title: "Profile",
                    subtitle: "Edit your personal information",
                    icon: LineIcons.user,
                    onTap: () => _navigateToProfile(context),
                  ),
                  _buildSettingsTile(
                    context,
                    title: "Security",
                    subtitle: "PIN lock, fingerprint, and password",
                    icon: LineIcons.userShield,
                    onTap: () => _navigateToSecurity(context),
                  ),
                  _buildSettingsTile(
                    context,
                    title: "Theme & Appearance",
                    subtitle: "Customize app colors and style",
                    icon: LineIcons.palette,
                    onTap: () => _navigateToAppearance(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildSettingsSection(
                context,
                "Notes & Sharing",
                [
                  _buildSettingsTile(
                    context,
                    title: "AI & Smart Features",
                    subtitle: "AI models, auto-save, and summaries",
                    icon: LineIcons.robot,
                    onTap: () => _navigateToAISmartFeatures(context),
                  ),
                  _buildSettingsTile(
                    context,
                    title: "Notes & Sharing",
                    subtitle: "Chat history and shareable links",
                    icon: LineIcons.comments,
                    onTap: () => _navigateToNotesSettings(context),
                  ),
                  _buildSettingsTile(
                    context,
                    title: "Sync & Cloud",
                    subtitle: "Firebase sync and backup options",
                    icon: LineIcons.cloud,
                    onTap: () => _navigateToSyncSettings(context),
                  ),
                  _buildSettingsTile(
                    context,
                    title: "Data Management",
                    subtitle: "Export, import, and recycle bin",
                    icon: LineIcons.database,
                    onTap: () => _navigateToDataManagement(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildSettingsSection(
                context,
                "System",
                [
                  if (FeatureFlag.enableInAppUpdate)
                    _buildSettingsTile(
                      context,
                      title: "App Updates",
                      subtitle: "Download latest versions",
                      icon: LineIcons.download,
                      onTap: () => _navigateToUpdateApp(context),
                    ),
                  _buildSettingsTile(
                    context,
                    title: "App Information",
                    subtitle: "Version details and support",
                    icon: LineIcons.info,
                    onTap: () => _navigateToAppInfo(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Danger Zone
              _buildDangerSection(context, theme, colorScheme),

              const SizedBox(height: 24),

              // Admin Section
              _buildAdminSection(context, theme, colorScheme),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withOpacity(0.1),
                colorScheme.secondary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LineIcons.user,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "MS Bridge",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Customize your experience",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: themeProvider.dynamicColorsEnabled
                            ? colorScheme.primary.withOpacity(0.2)
                            : colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: themeProvider.dynamicColorsEnabled
                              ? colorScheme.primary.withOpacity(0.3)
                              : colorScheme.secondary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            themeProvider.dynamicColorsEnabled
                                ? Icons.auto_awesome
                                : Icons.palette,
                            size: 14,
                            color: themeProvider.dynamicColorsEnabled
                                ? colorScheme.primary
                                : colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            themeProvider.effectiveThemeName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: themeProvider.dynamicColorsEnabled
                                  ? colorScheme.primary
                                  : colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionTile(
              context,
              "Ask AI",
              LineIcons.robot,
              colorScheme.primary,
              () => _navigateToAI(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionTile(
              context,
              "Sync Now",
              LineIcons.syncIcon,
              colorScheme.secondary,
              () => _syncNow(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionTile(
              context,
              "Backup",
              LineIcons.download,
              colorScheme.primary,
              () => _createBackup(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
      BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: children.asMap().entries.map((entry) {
                final index = entry.key;
                final child = entry.value;
                final isLast = index == children.length - 1;

                return Column(
                  children: [
                    child,
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.outline.withOpacity(0.1),
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colorScheme.primary.withOpacity(0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerSection(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "Danger Zone",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const DangerSettingsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSection(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "Administration",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.secondary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: const AdminSettingsSection(),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: const ProfileEditPage(),
      ),
    );
  }

  void _navigateToSecurity(BuildContext context) {
    // Show security options in a bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildSecurityBottomSheet(context),
    );
  }

  void _navigateToAppearance(BuildContext context) {
    // Navigate to appearance settings page
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: const AppearanceSettingsPage(),
      ),
    );
  }

  void _navigateToNotesSettings(BuildContext context) {
    // Show notes settings in a bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNotesBottomSheet(context),
    );
  }

  void _navigateToSyncSettings(BuildContext context) {
    // Show sync options in a bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildSyncBottomSheet(context),
    );
  }

  void _navigateToDataManagement(BuildContext context) {
    // Show data management options in a bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildDataManagementBottomSheet(context),
    );
  }

  void _navigateToUpdateApp(BuildContext context) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: const UpdateApp(),
      ),
    );
  }

  void _navigateToAppInfo(BuildContext context) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: const AppInfoPage(),
      ),
    );
  }

  void _navigateToAI(BuildContext context) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: const ChatAssistantPage(),
      ),
    );
  }

  void _navigateToAISmartFeatures(BuildContext context) {
    // Show AI & Smart Features in a bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildAISmartFeaturesBottomSheet(context),
    );
  }

  Widget _buildAISmartFeaturesBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "AI & Smart Features",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildAISmartFeaturesContent(context, theme, colorScheme),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAISmartFeaturesContent(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Summary Model
        _buildAIFeatureTile(
          context,
          "AI Summary Model",
          "Choose your preferred AI model for note summaries",
          LineIcons.robot,
          () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const AIModelSelectionPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // Auto Save Notes
        Consumer<AutoSaveProvider>(
          builder: (context, autoSaveProvider, _) {
            return _buildAIToggleTile(
              context,
              "Auto Save Notes",
              "Automatically save notes as you type",
              LineIcons.save,
              autoSaveProvider.autoSaveEnabled,
              (value) {
                autoSaveProvider.autoSaveEnabled = value;
              },
            );
          },
        ),

        const SizedBox(height: 12),

        // AI Chat Access
        _buildAIFeatureTile(
          context,
          "Ask AI",
          "Chat over your notes and MS Notes",
          LineIcons.comments,
          () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const ChatAssistantPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // Chat History Toggle
        Consumer<ChatHistoryProvider>(
          builder: (context, historyProvider, _) {
            return _buildAIToggleTile(
              context,
              "Chat History",
              historyProvider.isHistoryEnabled
                  ? "Chat history is being saved"
                  : "Chat history is disabled",
              LineIcons.history,
              historyProvider.isHistoryEnabled,
              (value) => historyProvider.toggleHistoryEnabled(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAIFeatureTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.primary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIToggleTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void _syncNow(BuildContext context) async {
    try {
      // Import the sync service
      await SyncService().syncLocalNotesToFirebase();
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Synced successfully',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Sync failed: $e',
          isSuccess: false,
        );
      }
    }
  }

  void _createBackup(BuildContext context) async {
    try {
      final filePath = await BackupService.exportAllNotes(context);
      if (mounted) {
        final detailedLocation =
            BackupService.getDetailedFileLocation(filePath);
        CustomSnackBar.show(
          context,
          'Backup exported successfully to $detailedLocation',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Backup failed: $e',
          isSuccess: false,
        );
      }
    }
  }

  Widget _buildSecurityBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Security Settings",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Scrollable content
          const Flexible(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: UserSettingsSection(),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSyncBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Sync & Cloud Settings",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSyncContent(context, theme, colorScheme),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSyncContent(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cloud Sync Section
        _buildSyncSection(
          context,
          "Cloud Sync (Firebase)",
          "Sync your notes across devices",
          LineIcons.cloud,
          Consumer<SyncSettingsProvider>(
            builder: (context, syncSettings, _) {
              return Switch(
                value: syncSettings.cloudSyncEnabled,
                onChanged: (bool value) async {
                  if (!value) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) {
                        final theme = Theme.of(ctx);
                        return AlertDialog(
                          backgroundColor: theme.colorScheme.surface,
                          title: const Text('Disable cloud sync?'),
                          content: const Text(
                              'All notes currently in the cloud will be deleted. Local notes remain on this device.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Disable')),
                          ],
                        );
                      },
                    );
                    if (confirm != true) return;
                    try {
                      await _deleteAllCloudNotes(context);
                      await syncSettings.setCloudSyncEnabled(false);
                      if (mounted) {
                        CustomSnackBar.show(
                          context,
                          'Cloud sync disabled. Cloud notes removed.',
                          isSuccess: true,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        CustomSnackBar.show(
                          context,
                          'Failed to disable sync: $e',
                          isSuccess: false,
                        );
                      }
                    }
                  } else {
                    try {
                      await syncSettings.setCloudSyncEnabled(true);
                      await SyncService().syncLocalNotesToFirebase();
                      if (mounted) {
                        CustomSnackBar.show(
                          context,
                          'Cloud sync enabled. Notes synced to cloud.',
                          isSuccess: true,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        CustomSnackBar.show(
                          context,
                          'Failed to enable sync: $e',
                          isSuccess: false,
                        );
                      }
                    }
                  }
                },
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Manual Sync Actions
        _buildSyncActionTile(
          context,
          "Sync Now",
          "Manually push notes to the cloud",
          LineIcons.syncIcon,
          () => _syncNow(context),
        ),

        const SizedBox(height: 12),

        _buildSyncActionTile(
          context,
          "Pull from Cloud",
          "Manually download notes from cloud to this device",
          LineIcons.download,
          () async {
            try {
              await ReverseSyncService().syncDataFromFirebaseToHive();
              if (mounted) {
                CustomSnackBar.show(
                  context,
                  'Notes downloaded from cloud successfully',
                  isSuccess: true,
                );
              }
            } catch (e) {
              if (mounted) {
                CustomSnackBar.show(
                  context,
                  'Download failed: $e',
                  isSuccess: false,
                );
              }
            }
          },
        ),

        const SizedBox(height: 12),

        _buildSyncActionTile(
          context,
          "Auto sync interval",
          "Choose how often to auto-sync (Off/15/30/60 min)",
          LineIcons.history,
          () async {
            final minutes = await _pickInterval(context);
            if (minutes == null) return;
            try {
              await AutoSyncScheduler.setIntervalMinutes(minutes);
              if (mounted) {
                CustomSnackBar.show(
                  context,
                  minutes == 0
                      ? 'Auto sync disabled'
                      : 'Auto sync set to every $minutes min',
                  isSuccess: true,
                );
              }
            } catch (e) {
              if (mounted) {
                CustomSnackBar.show(
                  context,
                  'Failed to set sync interval: $e',
                  isSuccess: false,
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildSyncSection(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget trailing,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSyncActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.primary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataManagementBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Data Management",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildDataManagementContent(context),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNotesBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Notes & AI Settings",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildNotesContent(context, theme, colorScheme),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNotesContent(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ask AI Section
        _buildNotesSectionHeader(context, "Ask AI", LineIcons.comments),
        const SizedBox(height: 12),

        _buildNotesActionTile(
          context,
          "Ask AI",
          "Chat over your notes and MS Notes",
          LineIcons.comments,
          () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const ChatAssistantPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        Consumer<ChatHistoryProvider>(
          builder: (context, historyProvider, _) {
            return _buildNotesToggleTile(
              context,
              "Chat History",
              historyProvider.isHistoryEnabled
                  ? "Chat history is being saved"
                  : "Chat history is disabled",
              LineIcons.history,
              historyProvider.isHistoryEnabled,
              (value) => historyProvider.toggleHistoryEnabled(),
            );
          },
        ),

        const SizedBox(height: 24),

        // Sharing & Collaboration Section
        _buildNotesSectionHeader(
            context, "Sharing & Collaboration", LineIcons.share),
        const SizedBox(height: 12),

        Consumer<ShareLinkProvider>(
          builder: (context, shareProvider, _) {
            return Column(
              children: [
                _buildNotesToggleTile(
                  context,
                  "Shareable Links",
                  "Create shareable links for your notes",
                  LineIcons.shareSquare,
                  shareProvider.shareLinksEnabled,
                  (value) async {
                    if (!value) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) {
                          final theme = Theme.of(ctx);
                          return AlertDialog(
                            backgroundColor: theme.colorScheme.surface,
                            title: const Text('Disable shareable links?'),
                            content: const Text(
                                'This will disable all existing shared notes. You can re-enable sharing later.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Disable'),
                              ),
                            ],
                          );
                        },
                      );
                      if (confirm != true) return;
                      await ShareRepository.disableAllShares();
                    }
                    shareProvider.shareLinksEnabled = value;
                  },
                ),
                if (shareProvider.shareLinksEnabled) ...[
                  const SizedBox(height: 12),
                  _buildNotesActionTile(
                    context,
                    "Shared Notes",
                    "Manage your shared notes and links",
                    LineIcons.share,
                    () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: const SharedNotesPage(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotesSectionHeader(
      BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.primary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesToggleTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementContent(BuildContext context) {
    return Column(
      children: [
        _buildDataManagementTile(
          context,
          "Export Backup",
          "Create a backup of all your notes",
          LineIcons.download,
          () => _createBackup(context),
        ),
        const SizedBox(height: 12),
        _buildDataManagementTile(
          context,
          "Import Backup",
          "Restore notes from a backup file",
          LineIcons.upload,
          () async {
            final report = await BackupService.importFromFile();
            if (mounted) {
              CustomSnackBar.show(
                context,
                'Import: ${report.inserted} added, ${report.updated} updated, ${report.skipped} skipped',
                isSuccess: true,
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _buildDataManagementTile(
          context,
          "Recycle Bin",
          "View and restore deleted notes",
          LineIcons.trash,
          () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const DeletedNotes(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDataManagementTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.primary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAllCloudNotes(BuildContext context) async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user == null) return;
      final firestore = FirebaseFirestore.instance;
      final col =
          firestore.collection('users').doc(user.uid).collection('notes');
      final snap = await col.get();
      final batch = firestore.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete cloud notes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<int?> _pickInterval(BuildContext context) async {
    final items = <int>[0, 15, 30, 60];
    int current = await AutoSyncScheduler.getIntervalMinutes();
    return showModalBottomSheet<int>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in items)
                ListTile(
                  title: Text(m == 0 ? 'Off' : 'Every $m minutes'),
                  trailing: current == m ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(ctx).pop(m),
                )
            ],
          ),
        );
      },
    );
  }
}
