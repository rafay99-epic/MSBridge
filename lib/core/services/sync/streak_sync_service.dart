// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:msbridge/core/models/streak_model.dart';
import 'package:msbridge/core/repo/streak_repo.dart';

class StreakSyncService {
  static const String streakDocId = 'streak';
  static const String streakCloudToggleKey = 'streak_cloud_sync_enabled';
  static const String lastSyncYmdKey = 'streak_last_sync_ymd';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> _isGlobalCloudSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('cloud_sync_enabled') ?? true;
  }

  Future<bool> _isStreakCloudSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(streakCloudToggleKey) ?? true;
  }

  Future<User?> _getUser() async {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> pushLocalToCloud() async {
    try {
      if (!await _isGlobalCloudSyncEnabled() ||
          !await _isStreakCloudSyncEnabled()) {
        return;
      }
      final user = await _getUser();
      if (user == null) return;

      final streak = await StreakRepo.getStreakData();
      final data = streak.toJson();
      data['updatedAt'] = DateTime.now().toIso8601String();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meta')
          .doc(streakDocId)
          .set(data, SetOptions(merge: true));

      // mark daily sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(lastSyncYmdKey, _todayYmd());
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'Streak pushLocalToCloud failed');
      rethrow;
    }
  }

  Future<bool> pushTodayIfDue() async {
    if (!await _isGlobalCloudSyncEnabled() ||
        !await _isStreakCloudSyncEnabled()) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(lastSyncYmdKey);
    final today = _todayYmd();
    if (last == today) return false;
    await pushLocalToCloud();
    return true;
  }

  Future<void> pullCloudToLocal() async {
    try {
      if (!await _isGlobalCloudSyncEnabled() ||
          !await _isStreakCloudSyncEnabled()) {
        return;
      }
      final user = await _getUser();
      if (user == null) return;

      final local = await StreakRepo.getStreakData();
      final localUpdatedAt = _getUpdatedAtFromStreak(local);

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meta')
          .doc(streakDocId)
          .get();

      if (!doc.exists) return; // nothing in cloud yet

      final cloudData = doc.data() as Map<String, dynamic>;
      final cloudUpdatedAt = _parseUpdatedAt(cloudData['updatedAt']);

      // Conflict resolution: if cloud >= local keep cloud; else keep local
      if (!cloudUpdatedAt.isBefore(localUpdatedAt)) {
        // keep cloud
        final merged = StreakModel.fromJson(cloudData);
        await StreakRepo.saveStreakData(merged);
        FirebaseCrashlytics.instance.log(
            'Streak conflict resolved (kept cloud). cloud=$cloudUpdatedAt local=$localUpdatedAt');
      } else {
        // local newer → push local
        await pushLocalToCloud();
        FirebaseCrashlytics.instance.log(
            'Streak conflict resolved (kept local). cloud=$cloudUpdatedAt local=$localUpdatedAt');
      }
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'Streak pullCloudToLocal failed');
      rethrow;
    }
  }

  Future<bool> syncNow() async {
    try {
      if (!await _isGlobalCloudSyncEnabled() ||
          !await _isStreakCloudSyncEnabled()) {
        return false; // sync disabled
      }
      await pullCloudToLocal();
      // after pull, push at most once per day
      await pushTodayIfDue();
      return true;
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'Streak syncNow failed');
      return false;
    }
  }

  // Helpers
  DateTime _parseUpdatedAt(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime _getUpdatedAtFromStreak(StreakModel s) {
    // Use lastActivity as a good proxy for freshness
    return s.lastActivityDate;
  }

  String _todayYmd() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
