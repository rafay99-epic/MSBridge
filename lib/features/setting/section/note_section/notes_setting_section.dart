import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/config/ai_model_choice.dart';
import 'package:msbridge/core/provider/auto_save_note_provider.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/core/services/network/internet_helper.dart';
import 'package:msbridge/core/services/sync/note_taking_sync.dart';
import 'package:msbridge/features/notes_taking/recyclebin/recycle.dart';
import 'package:msbridge/features/setting/section/note_section/ai_model_selection.dart';
import 'package:msbridge/features/setting/widgets/settings_section.dart';
import 'package:msbridge/features/setting/widgets/settings_tile.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:msbridge/widgets/warning_dialog_box.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/config/feature_flag.dart'; // Import FeatureFlag

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

  Future<void> _loadSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedModelName = prefs.getString(AIModelsConfig.selectedModelKey) ??
          'gemini-1.5-pro-latest';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final autoSaveProvider = Provider.of<AutoSaveProvider>(context);

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
        SettingsTile(
          title: "Reset Offline Notes",
          icon: Icons.restart_alt,
          onTap: () {
            showConfirmationDialog(
              context,
              theme,
              () async {
                final result = await HiveNoteTakingRepo.clearBox();
                if (result == false) {
                  CustomSnackBar.show(
                      context, "Sorry Error occured!! Notes didn't reset");
                } else {
                  CustomSnackBar.show(
                      context, "Offline notes reset successfully.");
                }
              },
              "Reset Offline Notes",
              "Are you sure you want to reset offline notes?",
            );
          },
        ),
        SettingsTile(
          title: "Sync Notes to Server",
          icon: LineIcons.server,
          onTap: () {
            showConfirmationDialog(
              context,
              theme,
              () async {
                final internetHelper = InternetHelper();
                try {
                  await internetHelper.checkInternet();
                  if (!internetHelper.connectivitySubject.value) {
                    if (context.mounted) {
                      CustomSnackBar.show(context, "No internet connection.");
                    }
                    return;
                  }

                  final syncService = SyncService();
                  try {
                    await syncService.syncLocalNotesToFirebase();
                    if (context.mounted) {
                      CustomSnackBar.show(
                          context, "Notes successfully synced to server");
                    }
                  } catch (e) {
                    if (context.mounted) {
                      CustomSnackBar.show(
                          context, "Failed to sync notes: ${e.toString()}");
                    }
                  }
                } finally {
                  internetHelper.dispose();
                }
              },
              "Sync Notes to Server",
              "Are you sure you want to sync notes to server?",
            );
          },
        ),
      ],
    );
  }
}
