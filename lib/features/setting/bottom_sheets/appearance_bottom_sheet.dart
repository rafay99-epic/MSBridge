// features/setting/bottom_sheets/appearance_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/bottom_sheet_base.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_action_tile.dart';
import 'package:msbridge/features/setting/section/appearance_section/appearance_settings_page.dart';
import 'package:msbridge/features/setting/section/appearance_section/font_selection_page.dart';
import 'package:page_transition/page_transition.dart';

class AppearanceBottomSheet extends StatelessWidget {
  const AppearanceBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomSheetBase(
      title: "Appearance & Fonts",
      content: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Appearance Option
        SettingActionTile(
          title: "Appearance",
          subtitle: "Customize themes, colors, and visual preferences",
          icon: LineIcons.palette,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const AppearanceSettingsPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Font Option
        SettingActionTile(
          title: "Font",
          subtitle: "Choose your preferred font family",
          icon: LineIcons.font,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const FontSelectionPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}
