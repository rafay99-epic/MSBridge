// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:line_icons/line_icons.dart';
import 'package:page_transition/page_transition.dart';

// Project imports:
import 'package:msbridge/features/notes_taking/recyclebin/recycle.dart';
import 'package:msbridge/features/setting/widgets/settings_section.dart';
import 'package:msbridge/features/setting/widgets/settings_tile.dart';

class NotesSetting extends StatelessWidget {
  const NotesSetting({super.key});

  @override
  Widget build(BuildContext context) {
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
      ],
    );
  }
}
