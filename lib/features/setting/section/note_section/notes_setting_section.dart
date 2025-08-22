import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/features/notes_taking/recyclebin/recycle.dart';
import 'package:msbridge/widgets/buildModernSettingsTile.dart';
import 'package:msbridge/widgets/buildSubsectionHeader.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/core/provider/share_link_provider.dart';
import 'package:msbridge/features/setting/section/note_section/shared_notes_page.dart';
import 'package:msbridge/core/repo/share_repo.dart';
import 'package:msbridge/core/services/backup_service.dart';
import 'package:msbridge/core/provider/sync_settings_provider.dart';
import 'package:msbridge/core/provider/note_version_provider.dart';
import 'package:msbridge/core/services/sync/note_taking_sync.dart';
import 'package:msbridge/core/services/sync/reverse_sync.dart';
import 'package:msbridge/core/services/sync/auto_sync_scheduler.dart';
import 'package:msbridge/features/setting/section/note_section/version_history_settings.dart';

class NotesSetting extends StatefulWidget {
  const NotesSetting({super.key});

  @override
  State<NotesSetting> createState() => _NotesSettingState();
}

class _NotesSettingState extends State<NotesSetting> {
  @override
  void initState() {
    super.initState();
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

  Future<bool> _getVersionHistoryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('version_history_enabled') ?? true;
  }

  Future<void> _setVersionHistoryEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('version_history_enabled', value);
  }

  @override
  Widget build(BuildContext context) {
    final shareProvider = Provider.of<ShareLinkProvider>(context);
    final syncSettings = Provider.of<SyncSettingsProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Version History
        buildSubsectionHeader(context, "Version History", LineIcons.history),
        const SizedBox(height: 12),

        // Version History Toggle
        Consumer<NoteVersionProvider>(
          builder: (context, versionProvider, _) {
            return buildModernSettingsTile(
              context,
              title: "Enable Version History",
              subtitle: "Automatically track changes to your notes",
              icon: LineIcons.history,
              trailing: FutureBuilder<bool>(
                future: _getVersionHistoryEnabled(),
                builder: (context, snapshot) {
                  final isEnabled = snapshot.data ?? true;
                  return Switch(
                    value: isEnabled,
                    onChanged: (value) async {
                      await _setVersionHistoryEnabled(value);
                      if (mounted) {
                        setState(() {});
                        CustomSnackBar.show(
                          context,
                          value
                              ? 'Version History enabled'
                              : 'Version History disabled',
                          isSuccess: true,
                        );
                      }
                    },
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        buildModernSettingsTile(
          context,
          title: "Version History Settings",
          subtitle: "Manage note version retention and cleanup",
          icon: LineIcons.cog,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const VersionHistorySettings(),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Sync & Cloud
        buildSubsectionHeader(context, "Sync & Cloud", LineIcons.cloud),
        const SizedBox(height: 12),
        buildModernSettingsTile(
          context,
          title: "Cloud Sync (Firebase)",
          subtitle: "Sync your notes across devices",
          icon: LineIcons.cloud,
          trailing: Switch(
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
                await syncSettings.setCloudSyncEnabled(false);
              } else {
                await syncSettings.setCloudSyncEnabled(true);
              }
            },
          ),
        ),
        // Only show sync options when cloud sync is enabled
        Consumer<SyncSettingsProvider>(
          builder: (context, syncSettings, _) {
            if (!syncSettings.cloudSyncEnabled) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                const SizedBox(height: 12),
                buildModernSettingsTile(
                  context,
                  title: "Push to Cloud",
                  subtitle: "Manually push notes to the cloud",
                  icon: LineIcons.syncIcon,
                  onTap: () async {
                    // Check if cloud sync is enabled before proceeding
                    if (!syncSettings.cloudSyncEnabled) {
                      CustomSnackBar.show(context,
                          'Please enable Cloud sync in Cloud Sync settings first',
                          isSuccess: false);
                      return;
                    }

                    try {
                      await SyncService().syncLocalNotesToFirebase();
                      if (mounted) {
                        CustomSnackBar.show(context, 'Synced successfully',
                            isSuccess: true);
                      }
                    } catch (e) {
                      if (mounted) {
                        FirebaseCrashlytics.instance.recordError(
                            e, StackTrace.current,
                            reason: "Failed to sync notes to cloud");
                        CustomSnackBar.show(context, 'Sync failed: $e',
                            isSuccess: false);
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                buildModernSettingsTile(
                  context,
                  title: "Pull from Cloud",
                  subtitle: "Manually download notes from cloud to this device",
                  icon: LineIcons.download,
                  onTap: () async {
                    // Check if cloud sync is enabled before proceeding
                    if (!syncSettings.cloudSyncEnabled) {
                      CustomSnackBar.show(context,
                          'Please enable Cloud sync in Cloud Sync settings first',
                          isSuccess: false);
                      return;
                    }

                    try {
                      await ReverseSyncService().syncDataFromFirebaseToHive();
                      if (mounted) {
                        CustomSnackBar.show(
                            context, 'Notes downloaded from cloud successfully',
                            isSuccess: true);
                      }
                    } catch (e) {
                      if (mounted) {
                        FirebaseCrashlytics.instance.recordError(
                            e, StackTrace.current,
                            reason: "Failed to download notes from cloud");
                        CustomSnackBar.show(context, 'Download failed: $e',
                            isSuccess: false);
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                buildModernSettingsTile(
                  context,
                  title: "Auto sync interval",
                  subtitle: "Choose how often to auto-sync (Off/15/30/60 min)",
                  icon: LineIcons.history,
                  onTap: () async {
                    // Check if cloud sync is enabled before proceeding
                    if (!syncSettings.cloudSyncEnabled) {
                      CustomSnackBar.show(context,
                          'Please enable Cloud sync in Cloud Sync settings first',
                          isSuccess: false);
                      return;
                    }

                    final minutes = await _pickInterval(context);
                    if (minutes == null) return;
                    await AutoSyncScheduler.setIntervalMinutes(minutes);
                    if (mounted) {
                      CustomSnackBar.show(
                          context,
                          minutes == 0
                              ? 'Auto sync disabled'
                              : 'Auto sync set to every $minutes min',
                          isSuccess: true);
                    }
                  },
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // Sharing & Collaboration
        buildSubsectionHeader(
            context, "Sharing & Collaboration", LineIcons.share),
        const SizedBox(height: 12),
        buildModernSettingsTile(
          context,
          title: "Shareable Links",
          subtitle: "Create shareable links for your notes",
          icon: LineIcons.shareSquare,
          trailing: Switch(
            value: shareProvider.shareLinksEnabled,
            onChanged: (bool value) async {
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
        ),
        if (shareProvider.shareLinksEnabled) ...[
          const SizedBox(height: 12),
          buildModernSettingsTile(
            context,
            title: "Shared Notes",
            subtitle: "Manage your shared notes and links",
            icon: LineIcons.share,
            onTap: () {
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

        const SizedBox(height: 24),

        // Data Management
        buildSubsectionHeader(context, "Data Management", LineIcons.database),
        const SizedBox(height: 12),
        buildModernSettingsTile(
          context,
          title: "Export Backup",
          subtitle: "Create a backup of all your notes",
          icon: LineIcons.download,
          onTap: () async {
            try {
              final filePath = await BackupService.exportAllNotes(context);
              if (mounted) {
                final detailedLocation =
                    BackupService.getDetailedFileLocation(filePath);

                // Show success message with detailed location (like PDF exporter)
                CustomSnackBar.show(context,
                    'Backup exported successfully to $detailedLocation',
                    isSuccess: true);
              }
            } catch (e) {
              if (mounted) {
                CustomSnackBar.show(context, 'Backup failed: $e');
              }
            }
          },
        ),
        const SizedBox(height: 12),
        buildModernSettingsTile(
          context,
          title: "Import Backup",
          subtitle: "Restore notes from a backup file",
          icon: LineIcons.upload,
          onTap: () async {
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
        buildModernSettingsTile(
          context,
          title: "Recycle Bin",
          subtitle: "View and restore deleted notes",
          icon: LineIcons.trash,
          onTap: () {
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
}
