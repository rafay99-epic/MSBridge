// features/setting/bottom_sheets/ai_features_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/bottom_sheet_base.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_action_tile.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_toggle_tile.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/auto_save_note_provider.dart';
import 'package:msbridge/core/provider/chat_history_provider.dart';
import 'package:msbridge/features/setting/section/note_section/ai_model_selection.dart';
import 'package:msbridge/features/ai_chat/chat_page.dart';
import 'package:page_transition/page_transition.dart';

class AIFeaturesBottomSheet extends StatelessWidget {
  const AIFeaturesBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomSheetBase(
      title: "AI & Smart Features",
      content: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingActionTile(
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
        const SizedBox(height: 12),
        Consumer<AutoSaveProvider>(
          builder: (context, autoSaveProvider, _) {
            return SettingToggleTile(
              title: "Auto Save Notes",
              subtitle: "Automatically save notes as you type",
              icon: LineIcons.save,
              value: autoSaveProvider.autoSaveEnabled,
              onChanged: (value) {
                autoSaveProvider.autoSaveEnabled = value;
              },
            );
          },
        ),
        const SizedBox(height: 12),
        SettingActionTile(
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
        Consumer<ChatHistoryProvider>(
          builder: (context, historyProvider, _) {
            return SettingToggleTile(
              title: "Chat History",
              subtitle: historyProvider.isHistoryEnabled
                  ? "Chat history is being saved"
                  : "Chat history is disabled",
              icon: LineIcons.history,
              value: historyProvider.isHistoryEnabled,
              onChanged: (value) => historyProvider.toggleHistoryEnabled(),
            );
          },
        ),
      ],
    );
  }
}
