// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports
// Update this import path if the widget file lives elsewhere in the repository.
// Try typical lib/ path first:
import 'package:msbridge/features/voice_notes/widgets/voice_recorder_widget.dart';

/// Test notes:
/// - Framework: flutter_test (WidgetTester) with platform channel mocking via MethodChannel.setMockMethodCallHandler.
/// - We do not introduce new dev_dependencies. We stub plugins (record, permission_handler, path_provider)
///   using MethodChannel mocks to keep tests hermetic and deterministic.
/// - We avoid exercising FirebaseAuth and VoiceNoteService paths that are not dependency-injected;
///   instead, we validate UI state changes, timing label formatting, and primary flows.
///
/// Covered scenarios:
///  1) Renders title input by default and respects initialTitle.
///  2) Hides title input when showTitleInput=false.
///  3) Happy path: start recording -> timer ticks -> stop recording -> "Recording Complete\!" panel appears.
///  4) Start pressed while plugin reports already recording -> remains in ready state.
///  5) Permission denied path: hasPermission=false and request() denied -> remains in ready state.
///  6) Start path when hasPermission=false but request() granted -> proceeds to recording.
///  7) Stop returns null path -> returns to non-completed state.
///
/// Helper: Channel stubs for:
///   - record:          'com.llfbandit.record'  (hasPermission, isRecording, start, stop, cancel, dispose)
///   - path_provider:   'plugins.flutter.io/path_provider' (getTemporaryDirectory)
///   - permission_handler: 'flutter.baseflow.com/permissions/methods' (requestPermissions)
///
/// Channel names are taken from upstream plugin sources/issues:
///   - record events channel examples and method channel logs: 'com.llfbandit.record' (GitHub issues #36, #379, #455)
///   - permission_handler method channel: 'flutter.baseflow.com/permissions/methods'
///   - path_provider: 'plugins.flutter.io/path_provider'
///
/// These tests assert visible UI text and buttons rather than internal private state.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const recordChannel = MethodChannel('com.llfbandit.record');
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const permissionChannel =
      MethodChannel('flutter.baseflow.com/permissions/methods');

  // Mutable stub state shared across tests
  bool stubHasPermission = true;
  bool stubIsRecording = false;
  String? lastStartPath;
  bool permissionRequestGrant = true;

  Future<void> _installCommonStubs() async {
    // Path provider: return a temp directory path
    pathProviderChannel.setMockMethodCallHandler((call) async {
      if (call.method == 'getTemporaryDirectory') {
        return Directory.systemTemp.path;
      }
      // Allow other calls to fall through if present
      return null;
    });

    // Permission handler: requestPermissions -> Map<int,int>
    // We'll treat microphone permission code dynamically by returning a single-entry map.
    permissionChannel.setMockMethodCallHandler((call) async {
      if (call.method == 'requestPermissions') {
        // Return microphone granted/denied. We can't rely on enum values here,
        // but the plugin expects a map<int, int>. The exact key isn't used by our app logic,
        // only the isGranted check in Permission.microphone.request().
        // We'll simulate "granted" with 1 and "denied" with 0 which matches common enum indices.
        return <int, int>{7: permissionRequestGrant ? 1 : 0}; // 7 ~ microphone in many versions
      }
      if (call.method == 'checkPermissionStatus') {
        // Return undetermined(0) or granted(1) loosely; our widget queries hasPermission via record.
        return 1;
      }
      return null;
    });

    // Record plugin stubs
    recordChannel.setMockMethodCallHandler((call) async {
      switch (call.method) {
        case 'hasPermission':
          return stubHasPermission;
        case 'isRecording':
          return stubIsRecording;
        case 'start':
          // Expect arguments to contain a 'path' we can capture
          final args = call.arguments;
          if (args is Map && args['path'] is String) {
            lastStartPath = args['path'] as String;
          } else {
            // Fallback path if not provided for any reason
            lastStartPath = '${Directory.systemTemp.path}/voice_note_test.m4a';
          }
          stubIsRecording = true;
          return null;
        case 'stop':
          // Return the same path used on start (widget sets _recordedFilePath to this)
          final p = lastStartPath;
          stubIsRecording = false;
          return p;
        case 'cancel':
          stubIsRecording = false;
          return null;
        case 'dispose':
          return null;
        default:
          return null;
      }
    });
  }

  Future<void> _resetStubs() async {
    stubHasPermission = true;
    stubIsRecording = false;
    lastStartPath = null;
    permissionRequestGrant = true;
  }

  Widget _wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  setUp(() async {
    await _resetStubs();
    await _installCommonStubs();
  });

  tearDown(() async {
    // Clear handlers to avoid leakage between tests
    pathProviderChannel.setMockMethodCallHandler(null);
    permissionChannel.setMockMethodCallHandler(null);
    recordChannel.setMockMethodCallHandler(null);
  });

  testWidgets('renders title input by default and uses initialTitle',
      (tester) async {
    await tester.pumpWidget(_wrap(const VoiceRecorderWidget(
      initialTitle: 'My Note',
    )));

    expect(find.text('Voice Note Title'), findsOneWidget);
    expect(find.text('My Note'), findsOneWidget);

    // Description input always present
    expect(find.text('Description (Optional)'), findsOneWidget);
  });

  testWidgets('hides title input when showTitleInput is false', (tester) async {
    await tester.pumpWidget(_wrap(const VoiceRecorderWidget(
      showTitleInput: false,
    )));

    expect(find.text('Voice Note Title'), findsNothing);
    expect(find.text('Description (Optional)'), findsOneWidget);
  });

  testWidgets(
      'happy path: start -> timer ticks -> stop -> shows "Recording Complete\!"',
      (tester) async {
    // Ensure permission path goes through record.hasPermission == true
    stubHasPermission = true;
    stubIsRecording = false;

    await tester.pumpWidget(_wrap(const VoiceRecorderWidget()));

    // Initially: Ready to Record UI
    expect(find.text('Ready to Record'), findsOneWidget);
    expect(find.text('Start Recording'), findsOneWidget);

    // Start recording
    await tester.tap(find.text('Start Recording'));
    await tester.pump(); // trigger async work
    await tester.pump(const Duration(milliseconds: 10));

    // UI should switch to recording state
    expect(find.text('Recording...'), findsOneWidget);
    expect(find.text('Stop Recording'), findsOneWidget);

    // Let the 1-second timer tick once
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);

    // Prepare a non-empty file at the captured path so _testRecordedFile sees content
    final path = lastStartPath ?? '${Directory.systemTemp.path}/voice_note_test.m4a';
    final f = File(path);
    await f.create(recursive: true);
    await f.writeAsBytes(List.filled(5, 1)); // 5 bytes

    // Stop recording
    await tester.tap(find.text('Stop Recording'));
    await tester.pump(); // process stop
    await tester.pump(const Duration(milliseconds: 50));

    // Completed UI is shown
    expect(find.text('Recording Complete\!'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Re-record'), findsOneWidget);
  });

  testWidgets('pressing start while already recording keeps ready UI',
      (tester) async {
    // Simulate plugin reporting already recording before start
    stubHasPermission = true;
    // On _startRecording(), widget calls _audioRecorder.isRecording(); return true to short-circuit
    stubIsRecording = true;

    await tester.pumpWidget(_wrap(const VoiceRecorderWidget()));
    await tester.tap(find.text('Start Recording'));
    await tester.pump();

    // Should remain in ready state (no "Recording..." text)
    expect(find.text('Recording...'), findsNothing);
    expect(find.text('Ready to Record'), findsOneWidget);
  });

  testWidgets('permission denied: hasPermission=false and request denied',
      (tester) async {
    stubHasPermission = false;
    permissionRequestGrant = false; // Permission.microphone.request() denied

    await tester.pumpWidget(_wrap(const VoiceRecorderWidget()));
    await tester.tap(find.text('Start Recording'));
    await tester.pump();

    // Should not enter recording state
    expect(find.text('Recording...'), findsNothing);
    expect(find.text('Ready to Record'), findsOneWidget);
  });

  testWidgets(
      'hasPermission=false but request granted -> proceeds to recording state',
      (tester) async {
    stubHasPermission = false;
    permissionRequestGrant = true; // Grant on request

    await tester.pumpWidget(_wrap(const VoiceRecorderWidget()));
    await tester.tap(find.text('Start Recording'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('Recording...'), findsOneWidget);
    expect(find.text('Stop Recording'), findsOneWidget);
  });

  testWidgets('stop returns null -> stays in pre-complete state', (tester) async {
    stubHasPermission = true;
    stubIsRecording = false;

    // Override stop to return null for this test
    const recordChannelLocal = MethodChannel('com.llfbandit.record');
    recordChannelLocal.setMockMethodCallHandler((call) async {
      switch (call.method) {
        case 'hasPermission':
          return true;
        case 'isRecording':
          return false;
        case 'start':
          final args = call.arguments;
          if (args is Map && args['path'] is String) {
            lastStartPath = args['path'] as String;
          }
          return null;
        case 'stop':
          return null; // <- return null path
      }
      return null;
    });

    await tester.pumpWidget(_wrap(const VoiceRecorderWidget()));
    await tester.tap(find.text('Start Recording'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('Recording...'), findsOneWidget);

    await tester.tap(find.text('Stop Recording'));
    await tester.pump();

    // Should not show "Recording Complete\!" since no file path
    expect(find.text('Recording Complete\!'), findsNothing);
    // Ready UI or input fields should be visible again
    expect(find.text('Ready to Record'), findsOneWidget);
  });
}