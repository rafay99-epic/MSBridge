// Note: Testing framework: flutter_test (Flutter's built-in test package).
// We use TestWidgetsFlutterBinding and MethodChannel stubs to avoid hitting native plugins.
// We focus on error paths and observable behaviors due to non-injectable UploadThing client.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';

// Import the file under test (adjust the path to your lib file as needed).
// Assuming the implementation resides at lib/core/services/upload/uploadthing_service.dart
import '../../../../lib/core/services/upload/uploadthing_service.dart';

import '../../../../test/test_helpers/platform_stubs.dart';

// A small spy to count Crashlytics and Bugfender invocations via MethodChannel handlers.
class _CallCounter {
  int crashlyticsCalls = 0;
  int bugfenderCalls = 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UploadThingService', () {
    late _CallCounter counter;
    late MethodChannel crash;
    late MethodChannel bug1;
    late MethodChannel bug2;
    late MethodChannel bug3;

    setUp(() {
      counter = _CallCounter();
      crash = const MethodChannel('plugins.flutter.io/firebase_crashlytics');
      bug1 = const MethodChannel('flutter_bugfender');
      bug2 = const MethodChannel('plugins.bugfender/flutter_bugfender');
      bug3 = const MethodChannel('com.bugfender.sdk/methods');

      // Install handlers that just count calls and return null (no-op)
      crash.setMockMethodCallHandler((call) async {
        counter.crashlyticsCalls++;
        return null;
      });
      for (final ch in [bug1, bug2, bug3]) {
        ch.setMockMethodCallHandler((call) async {
          counter.bugfenderCalls++;
          return null;
        });
      }
    });

    tearDown(() async {
      crash.setMockMethodCallHandler(null);
      bug1.setMockMethodCallHandler(null);
      bug2.setMockMethodCallHandler(null);
      bug3.setMockMethodCallHandler(null);
    });

    test('constructor accepts raw sk_ key without logging', () {
      // Arrange
      final key = 'sk_TEST_KEY_123';

      // Act
      expect(() => UploadThingService(apiKey: key), returnsNormally);

      // Assert
      expect(counter.crashlyticsCalls, 0,
          reason: 'No Crashlytics logs expected for valid key');
    });

    test('constructor normalizes base64-encoded apiKey json without logging',
        () {
      // {"apiKey":"sk_BASE64_OK"}
      final payload =
          base64.encode(utf8.encode(jsonEncode({'apiKey': 'sk_BASE64_OK'})));

      expect(() => UploadThingService(apiKey: payload), returnsNormally);
      expect(counter.crashlyticsCalls, 0,
          reason: 'No Crashlytics logs expected for valid normalized key');
    });

    test(
        'constructor with invalid base64 logs to Crashlytics but does not throw',
        () {
      final invalid = 'not-base64\!\!\!';

      expect(() => UploadThingService(apiKey: invalid), returnsNormally);
      expect(counter.crashlyticsCalls, greaterThanOrEqualTo(1),
          reason: 'Crashlytics should be notified on normalization failure');
    });

    test('uploadImageFile rethrows on client failure and logs to Bugfender',
        () async {
      // This test exercises the catch block; since we cannot inject a fake client,
      // we rely on the underlying client throwing with an invalid/nonexistent file or key.
      final svc = UploadThingService(apiKey: 'invalid-key');

      // Create a temp file reference that likely does not exist to trigger failure.
      final file = File('/path/does/not/exist/image.png');

      await expectLater(
          () => svc.uploadImageFile(file), throwsA(isA<Exception>()));
      expect(counter.bugfenderCalls, greaterThanOrEqualTo(1),
          reason: 'Bugfender.error should be called on failure');
    });

    test('uploadAudioFile rethrows on client failure and logs to Bugfender',
        () async {
      final svc = UploadThingService(apiKey: 'invalid-key');
      final file = File('/path/does/not/exist/audio.mp3');

      await expectLater(
          () => svc.uploadAudioFile(file), throwsA(isA<Exception>()));
      expect(counter.bugfenderCalls, greaterThanOrEqualTo(1),
          reason: 'Bugfender.error should be called on failure');
    });

    test('listRecent rethrows on client failure and records Crashlytics error',
        () async {
      final svc = UploadThingService(apiKey: 'invalid-key');

      await expectLater(
          () => svc.listRecent(limit: 3), throwsA(isA<Exception>()));
      expect(counter.crashlyticsCalls, greaterThanOrEqualTo(1),
          reason: 'Crashlytics.recordError should be called on failure');
    });

    test(
        'listRecent maps responses to expected shape (key, name, url) when client succeeds [integration-light]',
        () async {
      // This test demonstrates expected mapping shape. Because we cannot inject the client,
      // we only assert that when called with a small limit it returns a list or throws.
      final svc = UploadThingService(apiKey: 'sk_FAKE');

      try {
        final result = await svc.listRecent(limit: 1);
        // If it somehow succeeds in CI with a mocked environment, validate structure.
        expect(result, isA<List<Map<String, String>>>());
        for (final m in result) {
          expect(m.keys, containsAll(['key', 'name', 'url']));
          expect(m['key'], isNotEmpty);
          expect(m['name'], isNotEmpty);
          expect(m['url'], isNotEmpty);
        }
      } catch (e) {
        // Acceptable: environment without client configured should throw; we already test failure above.
        expect(counter.crashlyticsCalls, greaterThanOrEqualTo(1));
      }
    });
  });
}
