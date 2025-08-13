import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/config/ai_model_choice.dart';
import 'package:msbridge/core/provider/auto_save_note_provider.dart';
import 'package:msbridge/features/notes_taking/recyclebin/recycle.dart';
import 'package:msbridge/features/setting/section/note_section/ai_model_selection.dart';
import 'package:msbridge/features/setting/widgets/settings_section.dart';
import 'package:msbridge/features/setting/widgets/settings_tile.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/config/feature_flag.dart'; // Import FeatureFlag
import 'package:msbridge/core/provider/share_link_provider.dart';
import 'package:msbridge/features/setting/pages/shared_notes_page.dart';
import 'package:msbridge/core/repo/share_repo.dart';
import 'package:msbridge/core/services/backup_service.dart';
import 'package:msbridge/core/provider/sync_settings_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msbridge/widgets/snakbar.dart';

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

  Future<void> _deleteAllCloudNotes(BuildContext context) async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user == null) return;
      final firestore = FirebaseFirestore.instance;
      final col = firestore.collection('users').doc(user.uid).collection('notes');
      final snap = await col.get();
      final batch = firestore.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    } catch (e) {
      if (mounted) CustomSnackBar.show(context, 'Failed to delete cloud notes: $e');
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

    return SettingsSection(
      title: "Notes Setting",
      children: [
        SettingsTile(
          title: "AI Summary Model",
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
        if (FeatureFlag.enableAutoSave) // Conditionally render Auto Save
          SettingsTile(
            title: "Auto Save Notes",
            icon: LineIcons.save,
            trailing: Switch(
              value: autoSaveProvider.autoSaveEnabled,
              onChanged: (bool value) {
                autoSaveProvider.autoSaveEnabled = value;
              },
            ),
          ),
        SettingsTile(
          title: "Cloud Sync (Firebase)",
          icon: LineIcons.cloudUploadAlt,
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
                      content: const Text('All notes currently in the cloud will be deleted. Local notes remain on this device.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Disable')),
                      ],
                    );
                  },
                );
                if (confirm != true) return;
                await _deleteAllCloudNotes(context);
                await syncSettings.setCloudSyncEnabled(false);
                if (mounted) CustomSnackBar.show(context, 'Cloud sync disabled. Cloud notes removed.', isSuccess: true);
              } else {
                await syncSettings.setCloudSyncEnabled(true);
                // Trigger a full sync up on enable
                try {
                  await SyncService().syncLocalNotesToFirebase();
                  if (mounted) CustomSnackBar.show(context, 'Cloud sync enabled. Notes synced to cloud.', isSuccess: true);
                } catch (e) {
                  if (mounted) CustomSnackBar.show(context, 'Sync failed: $e');
                }
              }
            },
          ),
        ),
        SettingsTile(
          title: "Shareable Links",
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
        if (shareProvider.shareLinksEnabled)
          SettingsTile(
            title: "Shared Notes",
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
        SettingsTile(
          title: "Export Backup",
          icon: LineIcons.download,
          onTap: () async {
            await BackupService.exportAllNotes();
            if (mounted) {
              // Use custom toast
              // ignore: use_build_context_synchronously
              CustomSnackBar.show(context, 'Backup exported', isSuccess: true);
            }
          },
        ),
        SettingsTile(
          title: "Import Backup",
          icon: LineIcons.upload,
          onTap: () async {
            final report = await BackupService.importFromFile();
            if (mounted) {
              // Use custom toast
              // ignore: use_build_context_synchronously
              CustomSnackBar.show(
                context,
                'Import: ${report.inserted} added, ${report.updated} updated, ${report.skipped} skipped',
                isSuccess: true,
              );
            }
          },
        ),
        SettingsTile(
          title: "Recycle Bin",
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
        // Removed syncing/local offline features as requested
      ],
    );
  }
}
