import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/config/ai_model_choice.dart';
import 'package:msbridge/core/provider/auto_save_note_provider.dart';
import 'package:msbridge/features/notes_taking/recyclebin/recycle.dart';
import 'package:msbridge/features/setting/section/note_section/ai_model_selection.dart';
import 'package:msbridge/widgets/buildModernSettingsTile.dart';
import 'package:msbridge/widgets/buildSubsectionHeader.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/config/feature_flag.dart';
import 'package:msbridge/core/provider/share_link_provider.dart';
import 'package:msbridge/features/setting/pages/shared_notes_page.dart';
import 'package:msbridge/core/repo/share_repo.dart';
import 'package:msbridge/core/services/backup_service.dart';
import 'package:msbridge/core/provider/sync_settings_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msbridge/core/services/sync/note_taking_sync.dart';
import 'package:msbridge/core/services/sync/reverse_sync.dart';
import 'package:msbridge/features/ai_chat/chat_page.dart';
import 'package:msbridge/core/services/sync/auto_sync_scheduler.dart';
import 'package:msbridge/core/provider/chat_history_provider.dart';

class NotesSetting extends StatefulWidget {
  const NotesSetting({super.key});

  @override
  State<NotesSetting> createState() => _NotesSettingState();
}

class _NotesSettingState extends State<NotesSetting> {
  String? selectedModelName;

  @override
  void initState() {
    super.initState();
    _loadSelectedModel();
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
      if (mounted)
        CustomSnackBar.show(context, 'Failed to delete cloud notes: $e');
    }
  }

  Future<void> _loadSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedModelName = prefs.getString(AIModelsConfig.selectedModelKey) ??
          'gemini-1.5-pro-latest';
    });
  }

  @override
  Widget build(BuildContext context) {
    final autoSaveProvider = Provider.of<AutoSaveProvider>(context);
    final shareProvider = Provider.of<ShareLinkProvider>(context);
    final syncSettings = Provider.of<SyncSettingsProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI & Smart Features
        buildSubsectionHeader(context, "AI & Smart Features", LineIcons.robot),
        const SizedBox(height: 12),
        buildModernSettingsTile(
          context,
          title: "AI Summary Model",
          subtitle: "Choose your preferred AI model for note summaries",
          icon: LineIcons.robot,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const AIModelSelectionPage(),
              ),
            );
          },
        ),
        if (FeatureFlag.enableAutoSave) ...[
          const SizedBox(height: 12),
          buildModernSettingsTile(
            context,
            title: "Auto Save Notes",
            subtitle: "Automatically save notes as you type",
            icon: LineIcons.save,
            trailing: Switch(
              value: autoSaveProvider.autoSaveEnabled,
              onChanged: (bool value) {
                autoSaveProvider.autoSaveEnabled = value;
              },
            ),
          ),
        ],

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
                await _deleteAllCloudNotes(context);
                await syncSettings.setCloudSyncEnabled(false);
                if (mounted) {
                  CustomSnackBar.show(
                      context, 'Cloud sync disabled. Cloud notes removed.',
                      isSuccess: true);
                }
              } else {
                await syncSettings.setCloudSyncEnabled(true);
                try {
                  await SyncService().syncLocalNotesToFirebase();
                  if (mounted) {
                    CustomSnackBar.show(
                        context, 'Cloud sync enabled. Notes synced to cloud.',
                        isSuccess: true);
                  }
                } catch (e) {
                  if (mounted) CustomSnackBar.show(context, 'Sync failed: $e');
                }
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        buildModernSettingsTile(
          context,
          title: "Sync now",
          subtitle: "Manually push notes to the cloud",
          icon: LineIcons.syncIcon,
          onTap: () async {
            try {
              await SyncService().syncLocalNotesToFirebase();
              if (mounted) {
                CustomSnackBar.show(context, 'Synced successfully',
                    isSuccess: true);
              }
            } catch (e) {
              if (mounted) CustomSnackBar.show(context, 'Sync failed: $e');
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
            try {
              await ReverseSyncService().syncDataFromFirebaseToHive();
              if (mounted) {
                CustomSnackBar.show(
                    context, 'Notes downloaded from cloud successfully',
                    isSuccess: true);
              }
            } catch (e) {
              if (mounted) CustomSnackBar.show(context, 'Download failed: $e');
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

        const SizedBox(height: 24),

        // Ask AI
        buildSubsectionHeader(context, "Ask AI", LineIcons.comments),
        const SizedBox(height: 12),
        buildModernSettingsTile(
          context,
          title: "Ask AI",
          subtitle: "Chat over your notes and MS Notes",
          icon: LineIcons.comments,
          onTap: () {
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
            return buildModernSettingsTile(
              context,
              title: "Chat History",
              subtitle: historyProvider.isHistoryEnabled
                  ? "Chat history is being saved"
                  : "Chat history is disabled",
              icon: LineIcons.history,
              trailing: Switch(
                value: historyProvider.isHistoryEnabled,
                onChanged: (value) => historyProvider.toggleHistoryEnabled(),
              ),
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
