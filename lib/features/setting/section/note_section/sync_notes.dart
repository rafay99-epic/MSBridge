import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/features/notes_taking/recyclebin/recycle.dart';
import 'package:msbridge/features/setting/widgets/settings_section.dart';
import 'package:msbridge/features/setting/widgets/settings_tile.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:msbridge/widgets/warning_dialog_box.dart';
import 'package:page_transition/page_transition.dart';

class NotesSetting extends StatelessWidget {
  const NotesSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SettingsSection(
      title: "Notes Setting",
      children: [
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
      ],
    );
  }
}
