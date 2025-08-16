import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/core/models/streak_model.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class StreakRepo {
  static const String _streakKey = 'user_streak_data';

  // Get current streak data
  static Future<StreakModel> getStreakData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streakJson = prefs.getString(_streakKey);

      if (streakJson != null) {
        final Map<String, dynamic> data = json.decode(streakJson);
        return StreakModel.fromJson(data);
      }
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to get streak data',
        information: ['Returning initial streak data'],
      );
    }

    return StreakModel.initial();
  }

  // Save streak data
  static Future<void> saveStreakData(StreakModel streak) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streakJson = json.encode(streak.toJson());
      await prefs.setString(_streakKey, streakJson);
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to save streak data',
        information: [
          'Current streak: ${streak.currentStreak}',
          'Longest streak: ${streak.longestStreak}',
        ],
      );
      rethrow;
    }
  }

  // Update streak when user creates a note
  static Future<StreakModel> updateStreakOnActivity() async {
    try {
      final currentStreak = await getStreakData();
      final now = DateTime.now();

      // Check if this is the first activity of the day
      final lastActivityDate = DateTime(
        currentStreak.lastActivityDate.year,
        currentStreak.lastActivityDate.month,
        currentStreak.lastActivityDate.day,
      );

      final today = DateTime(now.year, now.month, now.day);

      if (lastActivityDate.isBefore(today)) {
        // Check if streak should continue or reset
        final yesterday = today.subtract(const Duration(days: 1));

        if (lastActivityDate.isAtSameMomentAs(yesterday)) {
          // Continue streak - this is the first note of a new day
          final newStreak = currentStreak.copyWith(
            currentStreak: currentStreak.currentStreak + 1,
            lastActivityDate: now,
            isActive: true,
          );

          // Update longest streak if needed
          if (newStreak.currentStreak > newStreak.longestStreak) {
            final updatedStreak = newStreak.copyWith(
              longestStreak: newStreak.currentStreak,
            );
            await saveStreakData(updatedStreak);
            return updatedStreak;
          }

          await saveStreakData(newStreak);
          return newStreak;
        } else if (lastActivityDate.isBefore(yesterday)) {
          // Streak broken, start new one
          final newStreak = currentStreak.copyWith(
            currentStreak: 1,
            lastActivityDate: now,
            streakStartDate: now,
            isActive: true,
          );

          await saveStreakData(newStreak);
          return newStreak;
        }
      }

      // Update last activity time for the same day (streak count doesn't change)
      final updatedStreak = currentStreak.copyWith(
        lastActivityDate: now,
        isActive: true,
      );

      await saveStreakData(updatedStreak);
      return updatedStreak;
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to update streak on activity',
        information: [
          'Current time: ${DateTime.now()}',
          'Error: $e',
        ],
      );
      rethrow;
    }
  }

  // Reset streak (for testing or user preference)
  static Future<void> resetStreak() async {
    try {
      final resetStreak = StreakModel.initial();
      await saveStreakData(resetStreak);
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to reset streak',
      );
      rethrow;
    }
  }

  // Get streak statistics
  static Future<Map<String, dynamic>> getStreakStats() async {
    final streak = await getStreakData();

    return {
      'currentStreak': streak.currentStreak,
      'longestStreak': streak.longestStreak,
      'daysUntilStreakEnds': streak.daysUntilStreakEnds,
      'isStreakAboutToEnd': streak.isStreakAboutToEnd,
      'hasStreakEnded': streak.hasStreakEnded,
      'streakStartDate': streak.streakStartDate,
      'lastActivityDate': streak.lastActivityDate,
    };
  }
}
