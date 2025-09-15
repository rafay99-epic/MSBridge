import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:msbridge/features/notes_taking/create/create_note.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/streak_provider.dart';
import 'package:msbridge/widgets/snakbar.dart';

class StreakIntegrationService {
  static Future<void> onNoteCreated(BuildContext context) async {
    try {
      final streakProvider =
          Provider.of<StreakProvider>(context, listen: false);

      if (!streakProvider.streakEnabled) {
        return;
      }

      // Update the streak
      await streakProvider.updateStreakOnActivity();

      // Show success message (only for milestones)
      _showStreakUpdateMessage(context, streakProvider);
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to update streak on note creation: $e',
          StackTrace.current.toString());
    }
  }

  // Call this when a user creates a voice note to update their streak
  static Future<void> onVoiceNoteCreated(BuildContext context) async {
    try {
      final streakProvider =
          Provider.of<StreakProvider>(context, listen: false);

      if (!streakProvider.streakEnabled) {
        return;
      }

      await streakProvider.updateStreakOnActivity();
      _showStreakUpdateMessage(context, streakProvider);
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to update streak on voice note creation: $e',
          StackTrace.current.toString());
    }
  }

  // Show appropriate streak message (only for milestones, not every note)
  static void _showStreakUpdateMessage(
      BuildContext context, StreakProvider streakProvider) {
    try {
      final currentStreak = streakProvider.currentStreakCount;

      // Only show messages for significant milestones, not every note
      if (currentStreak == 1) {
        // First streak - show once
        CustomSnackBar.show(
          context,
          "🎉 First note of the day! Your streak begins!",
          isSuccess: true,
        );
      } else if (currentStreak % 7 == 0 &&
          currentStreak > streakProvider.currentStreak.currentStreak - 1) {
        // Week milestone - only show when first reaching it
        CustomSnackBar.show(
          context,
          "🔥 Amazing! $currentStreak-day streak milestone reached!",
          isSuccess: true,
        );
      } else if (currentStreak % 30 == 0 &&
          currentStreak > streakProvider.currentStreak.currentStreak - 1) {
        // Month milestone - only show when first reaching it
        CustomSnackBar.show(
          context,
          "🌟 Incredible! $currentStreak-day streak milestone reached!",
          isSuccess: true,
        );
      } else if (currentStreak % 100 == 0 &&
          currentStreak > streakProvider.currentStreak.currentStreak - 1) {
        // Century milestone - only show when first reaching it
        CustomSnackBar.show(
          context,
          " Legendary! $currentStreak-day streak milestone reached!",
          isSuccess: true,
        );
      }
      // No message for regular updates to avoid spam
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to show streak update message: $e',
          StackTrace.current.toString());
    }
  }

  // Check if user needs streak reminder
  static bool needsStreakReminder(BuildContext context) {
    try {
      final streakProvider =
          Provider.of<StreakProvider>(context, listen: false);

      // Check if streak feature and notifications are enabled
      if (!streakProvider.streakEnabled ||
          !streakProvider.notificationsEnabled) {
        return false;
      }

      return streakProvider.needsAttention;
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to check if streak reminder is needed: $e',
          StackTrace.current.toString());
      return false;
    }
  }

  // Get streak status for display
  static Map<String, dynamic> getStreakStatus(BuildContext context) {
    try {
      final streakProvider =
          Provider.of<StreakProvider>(context, listen: false);

      return {
        'currentStreak': streakProvider.currentStreakCount,
        'longestStreak': streakProvider.longestStreakCount,
        'needsAttention': streakProvider.needsAttention,
        'isStreakAboutToEnd': streakProvider.isStreakAboutToEnd,
        'hasStreakEnded': streakProvider.hasStreakEnded,
        'motivationalMessage': streakProvider.motivationalMessage,
        'streakEnabled': streakProvider.streakEnabled,
        'notificationsEnabled': streakProvider.notificationsEnabled,
      };
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to get streak status: $e', StackTrace.current.toString());
      return {
        'currentStreak': 0,
        'longestStreak': 0,
        'needsAttention': false,
        'isStreakAboutToEnd': false,
        'hasStreakEnded': false,
        'motivationalMessage': 'Start your streak today!',
        'streakEnabled': false,
        'notificationsEnabled': false,
      };
    }
  }

  // Show streak reminder dialog
  static void showStreakReminder(BuildContext context) {
    try {
      final streakStatus = getStreakStatus(context);

      // Don't show reminder if streak is disabled
      if (streakStatus['streakEnabled'] == false) {
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                streakStatus['isStreakAboutToEnd'] ? Icons.warning : Icons.info,
                color: streakStatus['isStreakAboutToEnd']
                    ? Colors.orange
                    : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                streakStatus['isStreakAboutToEnd']
                    ? 'Save Your Streak!'
                    : 'Streak Reminder',
              ),
            ],
          ),
          content: Text(
            streakStatus['motivationalMessage'],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to note creation
                // Navigate to note creation (align with app-wide pattern)
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: const CreateNote(),
                    duration: const Duration(milliseconds: 300),
                  ),
                );
              },
              child: const Text('Create Note'),
            ),
          ],
        ),
      );
    } catch (e) {
      FlutterBugfender.sendCrash(
        'Failed to show streak reminder dialog: $e',
        StackTrace.current.toString(),
      );
    }
  }

  // Check if streak feature is available
  static bool isStreakAvailable(BuildContext context) {
    try {
      final streakProvider =
          Provider.of<StreakProvider>(context, listen: false);
      return streakProvider.streakEnabled;
    } catch (e) {
      FlutterBugfender.sendCrash(
        'Failed to check if streak is available: $e',
        StackTrace.current.toString(),
      );
      return false;
    }
  }

  // Get streak summary for quick display
  static String getStreakSummary(BuildContext context) {
    try {
      final streakProvider =
          Provider.of<StreakProvider>(context, listen: false);

      if (!streakProvider.streakEnabled) {
        return "Streak disabled";
      }

      if (streakProvider.currentStreakCount == 0) {
        return "No streak yet";
      }

      return "${streakProvider.currentStreakCount} day${streakProvider.currentStreakCount == 1 ? '' : 's'}";
    } catch (e) {
      FlutterBugfender.sendCrash(
        'Failed to get streak summary: $e',
        StackTrace.current.toString(),
      );
      return "Error";
    }
  }

  // Force refresh streak data
  static Future<void> refreshStreakData(BuildContext context) async {
    try {
      final streakProvider =
          Provider.of<StreakProvider>(context, listen: false);
      await streakProvider.refreshStreak();
    } catch (e) {
      FlutterBugfender.sendCrash(
        'Failed to refresh streak data: $e',
        StackTrace.current.toString(),
      );
    }
  }
}
