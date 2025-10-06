import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

Future<void> saveKeepAwake(bool value, String keepAwakePrefKey) async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keepAwakePrefKey, value);
    await WakelockPlus.toggle(enable: value);
    FlutterBugfender.log('ReadMode: wakelock saved and applied -> $value');
  } catch (e) {
    FlutterBugfender.sendCrash(
        'Error saving keep awake: $e', StackTrace.current.toString());
  }
}
