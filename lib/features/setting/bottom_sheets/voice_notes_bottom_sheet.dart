// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:line_icons/line_icons.dart';
import 'package:page_transition/page_transition.dart';

// Project imports:
import 'package:msbridge/features/setting/bottom_sheets/components/bottom_sheet_base.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_action_tile.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_section_header.dart';
import 'package:msbridge/features/voice_notes/screens/shared_voice_notes_screen.dart';
import 'package:msbridge/features/voice_notes/screens/voice_note_settings_screen.dart';

class VoiceNotesBottomSheet extends StatelessWidget {
  const VoiceNotesBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomSheetBase(
      title: "Voice Notes Settings",
      content: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voice Notes Management
        const SettingSectionHeader(
          title: "Voice Notes Management",
          icon: LineIcons.microphone,
        ),
        const SizedBox(height: 12),

        SettingActionTile(
          title: "Shared Voice Notes",
          subtitle: "View and manage your shared voice notes",
          icon: LineIcons.share,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const SharedVoiceNotesScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        SettingActionTile(
          title: "Voice Note Settings",
          subtitle: "Configure voice recording and sharing preferences",
          icon: LineIcons.cog,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const VoiceNoteSettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}
