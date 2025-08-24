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
import 'package:msbridge/features/setting/bottom_sheets/components/sync_interval_dialog.dart';
import 'package:msbridge/widgets/buildSubsectionHeader.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/features/setting/pages/settings_sync_page.dart';
import 'package:page_transition/page_transition.dart';

class SyncBottomSheet extends StatefulWidget {
  const SyncBottomSheet({super.key});

  @override
  State<SyncBottomSheet> createState() => _SyncBottomSheetState();
}

class _SyncBottomSheetState extends State<SyncBottomSheet> {
  bool _isSyncingNotesToCloud = false;
  bool _isPullingFromCloud = false;
  bool _isTogglingCloud = false; // guard to prevent re-entrancy

  @override
  Widget build(BuildContext context) {
    return BottomSheetBase(
      title: "Sync & Cloud Settings",
      content: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
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
                  if (_isTogglingCloud) return; // atomic guard
                  _isTogglingCloud = true;
                  final prevEnabled = syncSettings.cloudSyncEnabled;
                  try {
                    // Persist toggle first (UI state follows provider)
                    await syncSettings.setCloudSyncEnabled(value);
                    final userSettings = context.read<UserSettingsProvider>();
                    await userSettings.setCloudSyncEnabled(value);

                    // Start/stop services atomically
                    if (value) {
                      await AutoSyncScheduler.initialize();
                      await SyncService().startListening();
                    } else {
                      await AutoSyncScheduler.setIntervalMinutes(0);
                      await SyncService().stopListening();
                    }

                    if (mounted) {
                      CustomSnackBar.show(
                        context,
                        value ? "Cloud sync enabled" : "Cloud sync disabled",
                        isSuccess: true,
                      );
                    }
                  } catch (e, s) {
                    // Roll back both provider and runtime services
                    FirebaseCrashlytics.instance
                        .recordError(e, s, reason: 'Toggle cloud sync failed');
                    try {
                      await syncSettings.setCloudSyncEnabled(prevEnabled);
                      final userSettings = context.read<UserSettingsProvider>();
                      await userSettings.setCloudSyncEnabled(prevEnabled);

                      if (prevEnabled) {
                        await AutoSyncScheduler.initialize();
                        await SyncService().startListening();
                      } else {
                        await AutoSyncScheduler.setIntervalMinutes(0);
                        await SyncService().stopListening();
                      }
                    } catch (_) {}

                    if (mounted) {
                      CustomSnackBar.show(
                        context,
                        'Failed to update cloud sync. Please try again.',
                        isSuccess: false,
                      );
                    }
                  } finally {
                    _isTogglingCloud = false;
                  }
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Settings Sync Section (moved to its own page)
        buildSubsectionHeader(context, "Settings Sync", LineIcons.cog),
        const SizedBox(height: 12),
        SettingActionTile(
          title: "Open Settings Sync",
          subtitle:
              "Advanced options: bidirectional sync, export/import, reset",
          icon: LineIcons.cog,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const SettingsSyncPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // Notes Sync Section
        buildSubsectionHeader(context, "Notes Sync", LineIcons.fileAlt),
        const SizedBox(height: 12),

        SettingActionTile(
          title: "Sync Now",
          subtitle: "Manually push notes to the cloud",
          icon: LineIcons.redo,
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
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
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary.withOpacity(0.6),
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

  // Notes sync methods
  Future<void> _syncNotesToCloud(BuildContext context) async {
    setState(() => _isSyncingNotesToCloud = true);

    try {
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
