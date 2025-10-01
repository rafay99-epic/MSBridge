// Package imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelemetrySpan {
  final String name;
  final Stopwatch _watch = Stopwatch();
  final Map<String, String> context;

  TelemetrySpan(this.name, {Map<String, String>? data}) : context = data ?? {} {
    _watch.start();
    FirebaseCrashlytics.instance
        .log('[span:start] $name ${context.toString()}');
  }

  void end(
      {bool success = true,
      Object? error,
      StackTrace? stackTrace,
      Map<String, String>? data}) {
    _watch.stop();
    final durationMs = _watch.elapsedMilliseconds;
    final merged = {
      ...context,
      if (data != null) ...data,
      'durationMs': '$durationMs'
    };
    if (success && error == null) {
      FirebaseCrashlytics.instance
          .log('[span:end] $name success ${merged.toString()}');
    } else {
      FirebaseCrashlytics.instance.recordError(
        error ?? Exception('Span "$name" failed'),
        stackTrace ?? StackTrace.current,
        reason: '[span:end] $name failure ${merged.toString()}',
      );
    }
  }
}

class Telemetry {
  static TelemetrySpan start(String name, {Map<String, String>? data}) =>
      TelemetrySpan(name, data: data);

  static void log(String message) {
    FirebaseCrashlytics.instance.log(message);
  }

  static Future<bool> isKillSwitchOn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sync_kill_switch') ?? false;
  }

  static const String _lastActivityKey = 'ms_last_activity_at';

  static Future<void> touchLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());
  }

  static Future<Duration?> lastActivityAge() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_lastActivityKey);
    if (v == null) return null;
    try {
      final t = DateTime.parse(v);
      return DateTime.now().difference(t);
    } catch (_) {
      return null;
    }
  }
}
