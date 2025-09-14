import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class PlatformStubs {
  static const MethodChannel _crashlytics =
      MethodChannel('plugins.flutter.io/firebase_crashlytics');
  // Bugfender channel name guess; we stub a wide net of likely names to no-op.
  static const MethodChannel _bugfender1 =
      MethodChannel('flutter_bugfender');
  static const MethodChannel _bugfender2 =
      MethodChannel('plugins.bugfender/flutter_bugfender');
  static const MethodChannel _bugfender3 =
      MethodChannel('com.bugfender.sdk/methods');

  static void install() {
    TestWidgetsFlutterBinding.ensureInitialized();

    _crashlytics.setMockMethodCallHandler((call) async {
      // Accept all calls and return sensible defaults.
      return null;
    });
    _bugfender1.setMockMethodCallHandler((call) async => null);
    _bugfender2.setMockMethodCallHandler((call) async => null);
    _bugfender3.setMockMethodCallHandler((call) async => null);
  }

}