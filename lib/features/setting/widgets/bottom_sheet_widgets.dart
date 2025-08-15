import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/auto_save_note_provider.dart';
import 'package:msbridge/core/provider/chat_history_provider.dart';
import 'package:msbridge/core/provider/share_link_provider.dart';
import 'package:msbridge/core/provider/sync_settings_provider.dart';
import 'package:msbridge/features/setting/section/note_section/ai_model_selection.dart';
import 'package:msbridge/features/setting/section/user_section/user_settings_section.dart';
import 'package:msbridge/features/setting/pages/shared_notes_page.dart';
import 'package:msbridge/features/ai_chat/chat_page.dart';
import 'package:msbridge/core/repo/share_repo.dart';
import 'package:page_transition/page_transition.dart';

class BottomSheetWidgets {
  static Widget buildAISmartFeaturesBottomSheet(BuildContext context) {
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
          _buildDragHandle(colorScheme),
          const SizedBox(height: 20),
          _buildBottomSheetHeader(
              context, "AI & Smart Features", theme, colorScheme),
          const SizedBox(height: 20),
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

  static Widget buildSecurityBottomSheet(BuildContext context) {
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
          _buildDragHandle(colorScheme),
          const SizedBox(height: 20),
          _buildBottomSheetHeader(
              context, "Security Settings", theme, colorScheme),
          const SizedBox(height: 20),
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

  static Widget buildSyncBottomSheet(BuildContext context) {
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
          _buildDragHandle(colorScheme),
          const SizedBox(height: 20),
          _buildBottomSheetHeader(
              context, "Sync & Cloud Settings", theme, colorScheme),
          const SizedBox(height: 20),
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

  static Widget buildDataManagementBottomSheet(BuildContext context) {
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
          _buildDragHandle(colorScheme),
          const SizedBox(height: 20),
          _buildBottomSheetHeader(
              context, "Data Management", theme, colorScheme),
          const SizedBox(height: 20),
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

  static Widget buildNotesBottomSheet(BuildContext context) {
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
          _buildDragHandle(colorScheme),
          const SizedBox(height: 20),
          _buildBottomSheetHeader(
              context, "Notes & AI Settings", theme, colorScheme),
          const SizedBox(height: 20),
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

  static Widget _buildDragHandle(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.outline.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  static Widget _buildBottomSheetHeader(BuildContext context, String title,
      ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  static Widget _buildAISmartFeaturesContent(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

  static Widget _buildAIFeatureTile(
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

  static Widget _buildAIToggleTile(
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

  static Widget _buildSyncContent(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSyncSection(
          context,
          "Cloud Sync (Firebase)",
          "Sync your notes across devices",
          LineIcons.cloud,
          Consumer<SyncSettingsProvider>(
            builder: (context, syncSettings, _) {
              return Switch(
                value: syncSettings.cloudSyncEnabled ?? false,
                onChanged: (bool value) async {
                  // Sync logic implementation
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildSyncActionTile(
          context,
          "Sync Now",
          "Manually push notes to the cloud",
          LineIcons.syncIcon,
          () {
            // Sync now logic
          },
        ),
        const SizedBox(height: 12),
        _buildSyncActionTile(
          context,
          "Pull from Cloud",
          "Manually download notes from cloud to this device",
          LineIcons.download,
          () async {
            // Pull from cloud logic
          },
        ),
        const SizedBox(height: 12),
        _buildSyncActionTile(
          context,
          "Auto sync interval",
          "Choose how often to auto-sync (Off/15/30/60 min)",
          LineIcons.history,
          () async {
            // Auto sync interval logic
          },
        ),
      ],
    );
  }

  static Widget _buildSyncSection(
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

  static Widget _buildSyncActionTile(
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

  static Widget _buildDataManagementContent(BuildContext context) {
    return Column(
      children: [
        _buildDataManagementTile(
          context,
          "Export Backup",
          "Create a backup of all your notes",
          LineIcons.download,
          () {
            // Export backup logic
          },
        ),
        const SizedBox(height: 12),
        _buildDataManagementTile(
          context,
          "Import Backup",
          "Restore notes from a backup file",
          LineIcons.upload,
          () async {
            // Import backup logic
          },
        ),
        const SizedBox(height: 12),
        _buildDataManagementTile(
          context,
          "Recycle Bin",
          "View and restore deleted notes",
          LineIcons.trash,
          () {
            // Recycle bin logic
          },
        ),
      ],
    );
  }

  static Widget _buildDataManagementTile(
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

  static Widget _buildNotesContent(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                      if (confirm == true) {
                        await ShareRepository.disableAllShares();
                      }
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

  static Widget _buildNotesSectionHeader(
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

  static Widget _buildNotesActionTile(
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

  static Widget _buildNotesToggleTile(
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
}
