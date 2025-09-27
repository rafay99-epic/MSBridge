import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/widgets/build_settings_tile.dart';
import 'package:page_transition/page_transition.dart';
import 'package:msbridge/features/voice_notes/screens/shared_voice_notes_screen.dart';

class VoiceNotesSettingsSection extends StatelessWidget {
  const VoiceNotesSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voice Notes Management
        _buildSubsectionHeader(
            context, "Voice Notes Management", LineIcons.microphone),
        const SizedBox(height: 12),

        buildSettingsTile(
          context,
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
      ],
    );
  }

  Widget _buildSubsectionHeader(
      BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
