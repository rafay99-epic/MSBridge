// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:msbridge/core/provider/note_summary_ai_provider.dart';
import 'package:msbridge/features/ai_summary/ai_summary_bottome_sheet.dart';
import 'package:msbridge/widgets/snakbar.dart';

class AISummaryManager {
  static Future<void> generateAiSummary(
    BuildContext context,
    String title,
    String content,
  ) async {
    final aiProvider = Provider.of<NoteSummaryProvider>(context, listen: false);

    if (title.isEmpty && content.isEmpty) {
      CustomSnackBar.show(context, 'Please add some content to summarize',
          isSuccess: false);
      return;
    }

    try {
      await aiProvider.summarizeNote('$title\n\n$content');
      if (context.mounted) {
        showAiSummaryBottomSheet(context);
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to generate AI summary: $e', StackTrace.current.toString());
      if (context.mounted) {
        CustomSnackBar.show(context, 'Failed to generate summary: $e',
            isSuccess: false);
      }
    }
  }

  static Widget buildAIButton(BuildContext context, VoidCallback onPressed) {
    return IconButton(
      tooltip: 'AI Summary',
      icon: const Icon(LineIcons.robot, size: 22),
      onPressed: onPressed,
    );
  }
}
