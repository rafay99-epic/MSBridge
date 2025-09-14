Testing library/framework: flutter_test (Flutter's test package).
- We use MethodChannel.setMockMethodCallHandler to stub native calls for FirebaseCrashlytics and Flutter Bugfender.
- Because UploadThingService constructs its client internally, we primarily validate:
  - Constructor key normalization side-effects (Crashlytics logging behaviors on invalid base64).
  - Failure paths for uploadImageFile/uploadAudioFile/listRecent: they should log and rethrow.
- If your project provides a DI seam for UploadThing, replace with a mock (e.g., mocktail) and expand success-path assertions.