// features/setting/bottom_sheets/sync_bottom_sheet.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/provider/sync_settings_provider.dart';
import 'package:msbridge/core/provider/user_settings_provider.dart';
import 'package:msbridge/core/services/sync/auto_sync_scheduler.dart';
import 'package:msbridge/core/services/sync/note_taking_sync.dart';
import 'package:msbridge/core/services/sync/reverse_sync.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/bottom_sheet_base.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_action_tile.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_section_header.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/sync_interval_dialog.dart';
import 'package:msbridge/features/setting/utils/time_formatter.dart';
import 'package:msbridge/widgets/buildSubsectionHeader.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:provider/provider.dart';

class SyncBottomSheet extends StatefulWidget {
  const SyncBottomSheet({Key? key}) : super(key: key);

  @override
  State<SyncBottomSheet> createState() => _SyncBottomSheetState();
}

class _SyncBottomSheetState extends State<SyncBottomSheet> {
  bool _isSyncingSettingsToCloud = false;
  bool _isDownloadingSettingsFromCloud = false;
  bool _isBidirectionalSettingsSync = false;
  bool _isSyncingNotesToCloud = false;
  bool _isPullingFromCloud = false;

  @override
  Widget build(BuildContext context) {
    return BottomSheetBase(
      title: "Sync & Cloud Settings",
      content: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                value: syncSettings.cloudSyncEnabled,
                onChanged: (bool value) async {
                  final prev = syncSettings.cloudSyncEnabled;
                  try {
                    await syncSettings.setCloudSyncEnabled(value);

                    // Persist to full user settings as well
                    final userSettings = context.read<UserSettingsProvider>();
                    await userSettings.setCloudSyncEnabled(value);

                    if (value) {
                      // Enable/start sync
                      await AutoSyncScheduler.initialize();
                      await SyncService().startListening();
                    } else {
                      // Disable background timer immediately
                      await AutoSyncScheduler.setIntervalMinutes(0);
                    }

                    if (context.mounted) {
                      CustomSnackBar.show(
                        context,
                        value ? "Cloud sync enabled" : "Cloud sync disabled",
                        isSuccess: true,
                      );
                    }
                  } catch (e, s) {
                    FirebaseCrashlytics.instance
                        .recordError(e, s, reason: 'Toggle cloud sync failed');
                    // Revert UI state
                    await syncSettings.setCloudSyncEnabled(prev);
                    final userSettings = context.read<UserSettingsProvider>();
                    await userSettings.setCloudSyncEnabled(prev);

                    if (context.mounted) {
                      CustomSnackBar.show(
                        context,
                        'Failed to update cloud sync. Please try again.',
                        isSuccess: false,
                      );
                    }
                  }
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Settings Sync Section
        buildSubsectionHeader(context, "Settings Sync", LineIcons.cog),
        const SizedBox(height: 12),

        // Sync Status Indicator
        Consumer<UserSettingsProvider>(
          builder: (context, userSettings, _) {
            final isInSync = userSettings.isInSync;
            final lastSynced = userSettings.lastSyncedAt;

            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isInSync
                    ? colorScheme.primary.withOpacity(0.05)
                    : colorScheme.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isInSync
                      ? colorScheme.primary.withOpacity(0.2)
                      : colorScheme.error.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isInSync ? Icons.check_circle : Icons.warning,
                    size: 16,
                    color: isInSync ? colorScheme.primary : colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isInSync
                          ? "Settings are in sync with cloud"
                          : "Settings need to be synced",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            isInSync ? colorScheme.primary : colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (lastSynced != null)
                    Text(
                      "Last: ${TimeFormatter.formatTimeAgo(lastSynced)}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            (isInSync ? colorScheme.primary : colorScheme.error)
                                .withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        SettingActionTile(
          title: "Sync Settings to Cloud",
          subtitle: "Upload your app settings to Firebase",
          icon: LineIcons.upload,
          isLoading: _isSyncingSettingsToCloud,
          onTap: () => _syncSettingsToCloud(context),
        ),
        const SizedBox(height: 12),

        SettingActionTile(
          title: "Download Settings from Cloud",
          subtitle: "Get your settings from Firebase",
          icon: LineIcons.download,
          isLoading: _isDownloadingSettingsFromCloud,
          onTap: () => _downloadSettingsFromCloud(context),
        ),
        const SizedBox(height: 12),

        SettingActionTile(
          title: "Bidirectional Settings Sync",
          subtitle: "Smart sync that resolves conflicts",
          icon: LineIcons.syncIcon,
          isLoading: _isBidirectionalSettingsSync,
          onTap: () => _bidirectionalSettingsSync(context),
        ),
        const SizedBox(height: 24),

        // Notes Sync Section
        buildSubsectionHeader(context, "Notes Sync", LineIcons.fileAlt),
        const SizedBox(height: 12),

        SettingActionTile(
          title: "Sync Now",
          subtitle: "Manually push notes to the cloud",
          icon: LineIcons.syncIcon,
          isLoading: _isSyncingNotesToCloud,
          isDisabled: !context.watch<SyncSettingsProvider>().cloudSyncEnabled,
          onTap: () => _syncNotesToCloud(context),
        ),
        const SizedBox(height: 12),

        SettingActionTile(
          title: "Pull from Cloud",
          subtitle: "Manually download notes from cloud to this device",
          icon: LineIcons.download,
          isLoading: _isPullingFromCloud,
          isDisabled: !context.watch<SyncSettingsProvider>().cloudSyncEnabled,
          onTap: () => _pullFromCloud(context),
        ),
        const SizedBox(height: 12),

        SettingActionTile(
          title: "Auto sync interval",
          subtitle: "Choose how often to auto-sync (Off/15/30/60 min)",
          icon: LineIcons.history,
          isDisabled: !context.watch<SyncSettingsProvider>().cloudSyncEnabled,
          onTap: () => _showAutoSyncIntervalDialog(context),
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

  // Settings sync methods
  Future<void> _syncSettingsToCloud(BuildContext context) async {
    setState(() => _isSyncingSettingsToCloud = true);

    try {
      final userSettings =
          Provider.of<UserSettingsProvider>(context, listen: false);
      final success = await userSettings.syncToFirebase();

      if (context.mounted) {
        if (success) {
          CustomSnackBar.show(
            context,
            "Settings synced to cloud successfully!",
            isSuccess: true,
          );
        } else {
          CustomSnackBar.show(
            context,
            "Failed to sync settings to cloud",
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          "Error syncing settings: $e",
          isSuccess: false,
        );
      }
    } finally {
      setState(() => _isSyncingSettingsToCloud = false);
    }
  }

  Future<void> _downloadSettingsFromCloud(BuildContext context) async {
    setState(() => _isDownloadingSettingsFromCloud = true);

    try {
      final userSettings =
          Provider.of<UserSettingsProvider>(context, listen: false);
      final success = await userSettings.syncFromFirebase();

      if (context.mounted) {
        if (success) {
          CustomSnackBar.show(
            context,
            "Settings downloaded from cloud successfully!",
            isSuccess: true,
          );
        } else {
          CustomSnackBar.show(
            context,
            "Failed to download settings from cloud",
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          "Error downloading settings: $e",
          isSuccess: false,
        );
      }
    } finally {
      setState(() => _isDownloadingSettingsFromCloud = false);
    }
  }

  Future<void> _bidirectionalSettingsSync(BuildContext context) async {
    setState(() => _isBidirectionalSettingsSync = true);

    try {
      final userSettings =
          Provider.of<UserSettingsProvider>(context, listen: false);
      final success = await userSettings.forceSync();

      if (context.mounted) {
        if (success) {
          CustomSnackBar.show(
            context,
            "Settings synced bidirectionally successfully!",
            isSuccess: true,
          );
        } else {
          CustomSnackBar.show(
            context,
            "Failed to sync settings bidirectionally",
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          "Error syncing settings bidirectionally: $e",
          isSuccess: false,
        );
      }
    } finally {
      setState(() => _isBidirectionalSettingsSync = false);
    }
  }

  // Notes sync methods
  Future<void> _syncNotesToCloud(BuildContext context) async {
    setState(() => _isSyncingNotesToCloud = true);

    try {
      // Use the actual sync service
      final syncService = SyncService();
      await syncService.syncLocalNotesToFirebase();

      if (context.mounted) {
        CustomSnackBar.show(
          context,
          "Notes synced to cloud successfully!",
          isSuccess: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          "Error syncing notes: $e",
          isSuccess: false,
        );
      }
    } finally {
      setState(() => _isSyncingNotesToCloud = false);
    }
  }

  Future<void> _pullFromCloud(BuildContext context) async {
    setState(() => _isPullingFromCloud = true);

    try {
      // Use the actual reverse sync service
      final reverseSyncService = ReverseSyncService();
      await reverseSyncService.syncDataFromFirebaseToHive();

      if (context.mounted) {
        CustomSnackBar.show(
          context,
          "Successfully pulled data from cloud!",
          isSuccess: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          "Error pulling from cloud: $e",
          isSuccess: false,
        );
      }
    } finally {
      setState(() => _isPullingFromCloud = false);
    }
  }

  Future<void> _showAutoSyncIntervalDialog(BuildContext context) async {
    final minutes = await SyncIntervalDialog.show(context);

    if (minutes != null) {
      await AutoSyncScheduler.setIntervalMinutes(minutes);
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          minutes == 0
              ? 'Auto sync turned off'
              : 'Auto sync set to every $minutes minutes',
          isSuccess: true,
        );
      }
    }
  }
}
