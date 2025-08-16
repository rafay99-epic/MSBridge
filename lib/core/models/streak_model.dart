class StreakModel {
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActivityDate;
  final DateTime streakStartDate;
  final bool isActive;

  StreakModel({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityDate,
    required this.streakStartDate,
    required this.isActive,
  });

  factory StreakModel.initial() {
    final now = DateTime.now();
    return StreakModel(
      currentStreak: 0,
      longestStreak: 0,
      lastActivityDate: now,
      streakStartDate: now,
      isActive: false,
    );
  }

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastActivityDate: DateTime.parse(
          json['lastActivityDate'] ?? DateTime.now().toIso8601String()),
      streakStartDate: DateTime.parse(
          json['streakStartDate'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': lastActivityDate.toIso8601String(),
      'streakStartDate': streakStartDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  StreakModel copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    DateTime? streakStartDate,
    bool? isActive,
  }) {
    return StreakModel(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      streakStartDate: streakStartDate ?? this.streakStartDate,
      isActive: isActive ?? this.isActive,
    );
  }

  // Check if streak is about to end (missed yesterday)
  bool get isStreakAboutToEnd {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final lastActivity = DateTime(
        lastActivityDate.year, lastActivityDate.month, lastActivityDate.day);
    final yesterdayDate =
        DateTime(yesterday.year, yesterday.month, yesterday.day);

    return lastActivity.isBefore(yesterdayDate) && currentStreak > 0;
  }

  // Check if streak has ended (missed more than 1 day)
  bool get hasStreakEnded {
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    final lastActivity = DateTime(
        lastActivityDate.year, lastActivityDate.month, lastActivityDate.day);
    final twoDaysAgoDate =
        DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day);

    return lastActivity.isBefore(twoDaysAgoDate);
  }

  // Get days until streak ends
  int get daysUntilStreakEnds {
    if (currentStreak == 0) return 0;

    final now = DateTime.now();
    final lastActivity = DateTime(
        lastActivityDate.year, lastActivityDate.month, lastActivityDate.day);
    final today = DateTime(now.year, now.month, now.day);

    final difference = today.difference(lastActivity).inDays;
    return difference == 0 ? 0 : 1; // 1 day to save streak
  }
}
