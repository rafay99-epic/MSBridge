import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/config/ai_model_choice.dart';
import 'package:msbridge/core/provider/auto_save_note_provider.dart';
import 'package:msbridge/features/notes_taking/recyclebin/recycle.dart';
import 'package:msbridge/features/setting/section/note_section/ai_model_selection.dart';
import 'package:msbridge/features/setting/widgets/settings_section.dart';
import 'package:msbridge/features/setting/widgets/settings_tile.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/config/feature_flag.dart'; // Import FeatureFlag
import 'package:msbridge/core/provider/share_link_provider.dart';
import 'package:msbridge/features/setting/pages/shared_notes_page.dart';

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
    final autoSaveProvider = Provider.of<AutoSaveProvider>(context);
    final shareProvider = Provider.of<ShareLinkProvider>(context);

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
          title: "Shareable Links",
          icon: LineIcons.shareSquare,
          trailing: Switch(
            value: shareProvider.shareLinksEnabled,
            onChanged: (bool value) {
              shareProvider.shareLinksEnabled = value;
            },
          ),
        ),
        if (shareProvider.shareLinksEnabled)
          SettingsTile(
            title: "Shared Notes",
            icon: LineIcons.externalLinkAlt,
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
