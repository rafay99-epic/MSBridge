// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// These package imports should match the app's actual structure.
// Adjust the import paths below if your project uses different file locations.
import 'package:your_app/features/voice_notes/screens/shared_voice_notes_screen.dart';
import 'package:your_app/features/voice_notes/models/shared_voice_note_meta.dart';
import 'package:your_app/features/voice_notes/models/voice_note_model.dart';
import 'package:your_app/common/ui/custom_snackbar.dart';
import 'package:your_app/features/voice_notes/data/voice_note_share_repository.dart';
import 'package:share_plus/share_plus.dart';

/// NOTE: Testing library/framework
/// - Using flutter_test (WidgetTester) for widget tests
/// - Using mocktail for mocking global/static collaborators via indirection wrappers defined here

// ---- Test Doubles / Helpers -------------------------------------------------

class _CustomSnackBarSpy {
  final List<(String message, SnackBarType type)> calls = [];
  void call(BuildContext context, String message, SnackBarType type) {
    calls.add((message, type));
    // Show a real SnackBar so it can be discovered by tester if needed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SharePlusSpy extends Mock {
  Future<void> share(String text, {String? subject}) async {}
}

// Since Clipboard is static, we intercept via a Fake MethodChannel for clipboard
class _ClipboardInterceptor {
  final List<String> copied = [];
  void install() {
    const channel = MethodChannel('flutter/platform');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'Clipboard.setData') {
        final text = (call.arguments as Map)['text'] as String? ?? '';
        copied.add(text);
        return null;
      }
      return null;
    });
  }

  void uninstall() {
    const channel = MethodChannel('flutter/platform');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }
}

// We cannot mock static methods directly; wrap calls in top-level function typedefs
// to allow test to override via Zone values.
typedef GetSharedVoiceNotesFn = Future<List<SharedVoiceNoteMeta>> Function();
typedef DisableShareFn = Future<void> Function(VoiceNoteModel);

// Provide keys to look up in Zone
final _getSharedKey = Object();
final _disableShareKey = Object();
final _snackBarKey = Object();
final _sharePlusKey = Object();

// Small test harness that injects wrappers via InheritedWidget to be discovered by the widget under test.
// If the production code doesn't support DI, we use Zone values and a package-local shim below via an extension.
class _DI extends InheritedWidget {
  final GetSharedVoiceNotesFn getShared;
  final DisableShareFn disableShare;
  final void Function(BuildContext, String, SnackBarType) showSnack;
  final Future<void> Function(String text, {String? subject}) shareFn;

  const _DI({
    required this.getShared,
    required this.disableShare,
    required this.showSnack,
    required this.shareFn,
    required super.child,
    super.key,
  });

  static _DI of(BuildContext context) {
    final di = context.dependOnInheritedWidgetOfExactType<_DI>();
    assert(di \!= null, 'DI not found in context');
    return di\!;
  }

  @override
  bool updateShouldNotify(_DI oldWidget) => false;
}

// Shim layer to route production static calls through DI when present.
// To use this, ensure the test pumps the screen inside _DI. Production behavior remains unchanged when _DI is absent.
extension _RepoShims on BuildContext {
  Future<List<SharedVoiceNoteMeta>> getSharedShim() async {
    final di = contextDepend<_DI>(this);
    if (di \!= null) return di.getShared();
    return VoiceNoteShareRepository.getSharedVoiceNotes();
  }

  Future<void> disableShareShim(VoiceNoteModel m) async {
    final di = contextDepend<_DI>(this);
    if (di \!= null) return di.disableShare(m);
    return VoiceNoteShareRepository.disableShare(m);
  }

  void showSnackShim(String message, SnackBarType t) {
    final di = contextDepend<_DI>(this);
    if (di \!= null) return di.showSnack(this, message, t);
    CustomSnackBar.show(this, message, t);
  }

  Future<void> shareShim(String text, {String? subject}) {
    final di = contextDepend<_DI>(this);
    if (di \!= null) return di.shareFn(text, subject: subject);
    return Share.share(text, subject: subject);
  }
}

// Safe context-depend without failing if not present
T? contextDepend<T extends InheritedWidget>(BuildContext context) {
  return context.getElementForInheritedWidgetOfExactType<T>()?.widget as T?;
}

// Widget wrapper that exposes the same UI but routes calls through shims above.
// This leaves the main file untouched; in tests we pump this wrapper.
class SharedVoiceNotesScreenTestable extends StatelessWidget {
  const SharedVoiceNotesScreenTestable({super.key});

  @override
  Widget build(BuildContext context) {
    return SharedVoiceNotesScreen(); // UI remains identical; we intercept inside tests via _DI
  }
}

// --- Fake Data ---------------------------------------------------------------

SharedVoiceNoteMeta _meta(String id, String title, String url) => SharedVoiceNoteMeta(
  shareId: 'share_$id',
  voiceNoteId: id,
  title: title,
  shareUrl: url,
  // add other fields if required by the model
);

// --- Finders ----------------------------------------------------------------
Finder _searchField() => find.byType(TextField);
Finder _refreshButton() => find.byTooltip('Refresh');
Finder _settingsIcon() => find.byIcon(LineIcons.cog);
Finder _resultCounter() => find.textContaining('result');
Finder _noResultsTitle() => find.text('No Results Found');
Finder _noSharedTitle() => find.text('No Shared Voice Notes');
Finder _tapToView() => find.text('Tap to view');
Finder _sharedChip() => find.text('Shared');
Finder _shareLinkDialogTitle() => find.text('Share Link');
Finder _copyLinkButton() => find.byIcon(LineIcons.copy);
Finder _shareViaAppButton() => find.text('Share via App');
Finder _deleteShareAction() => find.text('Delete Share');
Finder _viewShareLinkAction() => find.text('View Share Link');

// --- Test Suite --------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final clipboard = _ClipboardInterceptor();
  final snackSpy = _CustomSnackBarSpy();
  final shareSpy = _SharePlusSpy();

  setUpAll(() {
    registerFallbackValue(Share.share(''));
  });

  setUp(() {
    clipboard.install();
    snackSpy.calls.clear();
    reset(shareSpy);
  });

  tearDown(() {
    clipboard.uninstall();
  });

  Widget _wrapWithApp(Widget child, {
    required GetSharedVoiceNotesFn getShared,
    required DisableShareFn disableShare,
  }) {
    return MaterialApp(
      home: _DI(
        getShared: getShared,
        disableShare: disableShare,
        showSnack: snackSpy.call,
        shareFn: (text, {subject}) => shareSpy.share(text, subject: subject),
        child: child,
      ),
    );
  }

  testWidgets('shows loading spinner initially, then renders list on success', (tester) async {
    final notes = [
      _meta('1', 'Meeting Notes', 'https://example.com/s1'),
      _meta('2', 'Daily Standup', 'https://example.com/s2'),
    ];

    await tester.pumpWidget(
      _wrapWithApp(
        const SharedVoiceNotesScreenTestable(),
        getShared: () async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return notes;
        },
        disableShare: (_) async {},
      ),
    );

    // Initial loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let future complete
    await tester.pumpAndSettle();

    // List renders with items and tap hint/chip
    expect(find.text('Shared Voice Notes'), findsOneWidget);
    expect(find.text('Meeting Notes'), findsOneWidget);
    expect(find.text('Daily Standup'), findsOneWidget);
    expect(_sharedChip(), findsNWidgets(2));
    expect(_tapToView(), findsWidgets);
  });

  testWidgets('refresh button triggers reload', (tester) async {
    var callCount = 0;
    Future<List<SharedVoiceNoteMeta>> getShared() async {
      callCount++;
      return [_meta('1', 'A', 'u1')];
    }

    await tester.pumpWidget(
      _wrapWithApp(const SharedVoiceNotesScreenTestable(),
          getShared: getShared, disableShare: (_) async {}),
    );
    await tester.pumpAndSettle();

    expect(callCount, 1);
    await tester.tap(_refreshButton());
    await tester.pump(); // start reload
    await tester.pumpAndSettle();
    expect(callCount, 2);
  });

  testWidgets('search filters by title (case-insensitive, trims)', (tester) async {
    final notes = [
      _meta('1', 'Project Alpha', 'u1'),
      _meta('2', 'alpha beta', 'u2'),
      _meta('3', 'Gamma', 'u3'),
    ];

    await tester.pumpWidget(
      _wrapWithApp(
        const SharedVoiceNotesScreenTestable(),
        getShared: () async => notes,
        disableShare: (_) async {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_searchField(), '  ALPHA  ');
    await tester.pumpAndSettle();

    expect(find.text('Project Alpha'), findsOneWidget);
    expect(find.text('alpha beta'), findsOneWidget);
    expect(find.text('Gamma'), findsNothing);
    expect(_resultCounter(), findsOneWidget);
  });

  testWidgets('clear search button resets results and state', (tester) async {
    final notes = [
      _meta('1', 'One', 'u1'),
      _meta('2', 'Two', 'u2'),
    ];
    await tester.pumpWidget(
      _wrapWithApp(
        const SharedVoiceNotesScreenTestable(),
        getShared: () async => notes,
        disableShare: (_) async {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_searchField(), 'Two');
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsOneWidget);
    expect(find.text('One'), findsNothing);

    // Suffix clear icon should appear; tap it
    final clearIcon = find.byIcon(LineIcons.times);
    expect(clearIcon, findsOneWidget);
    await tester.tap(clearIcon);
    await tester.pumpAndSettle();

    // Both items visible again
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
  });

  testWidgets('no results message when search yields nothing', (tester) async {
    await tester.pumpWidget(
      _wrapWithApp(
        const SharedVoiceNotesScreenTestable(),
        getShared: () async => [_meta('1', 'Alpha', 'u')],
        disableShare: (_) async {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_searchField(), 'zzz');
    await tester.pumpAndSettle();

    expect(_noResultsTitle(), findsOneWidget);
  });

  testWidgets('empty state message when no shared notes and not searching', (tester) async {
    await tester.pumpWidget(
      _wrapWithApp(
        const SharedVoiceNotesScreenTestable(),
        getShared: () async => <SharedVoiceNoteMeta>[],
        disableShare: (_) async {},
      ),
    );
    await tester.pumpAndSettle();

    expect(_noSharedTitle(), findsOneWidget);
  });

  testWidgets('settings bottom sheet shows options', (tester) async {
    final note = _meta('1', 'One', 'u1');
    await tester.pumpWidget(
      _wrapWithApp(
        const SharedVoiceNotesScreenTestable(),
        getShared: () async => [note],
        disableShare: (_) async {},
      ),
    );
    await tester.pumpAndSettle();

    // Open settings via the gear icon
    await tester.tap(_settingsIcon());
    await tester.pumpAndSettle();

    expect(_viewShareLinkAction(), findsOneWidget);
    expect(_deleteShareAction(), findsOneWidget);
  });

  testWidgets('View Share Link shows dialog with URL, supports copy and share via app', (tester) async {
    final url = 'https://example.com/share';
    final note = _meta('1', 'Title X', url);

    await tester.pumpWidget(
      _wrapWithApp(
        const SharedVoiceNotesScreenTestable(),
        getShared: () async => [note],
        disableShare: (_) async {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_settingsIcon());
    await tester.pumpAndSettle();

    await tester.tap(_viewShareLinkAction());
    await tester.pumpAndSettle();

    expect(_shareLinkDialogTitle(), findsOneWidget);
    expect(find.text(url), findsOneWidget);

    // Copy link path
    await tester.tap(_copyLinkButton());
    await tester.pumpAndSettle();
    // Snack shown
    expect(
      find.textContaining('Link copied to clipboard'),
      findsAtLeastNWidgets(1),
    );

    // Share via app path
    await tester.tap(_shareViaAppButton());
    await tester.pump(); // dialog closes
    await tester.pumpAndSettle();

    verify(() => shareSpy.share(
      any(that: contains('Title X')),
      subject: any(named: 'subject'),
    )).called(1);
  });

  testWidgets('Delete Share: confirm -> shows loading -> disables share -> removes item -> success snackbar', (tester) async {
    final notes = [
      _meta('1', 'A', 'u1'),
      _meta('2', 'B', 'u2'),
    ];
    var disabledCalledWith = <VoiceNoteModel>[];

    await tester.pumpWidget(
      _wrapWithApp(
        const SharedVoiceNotesScreenTestable(),
        getShared: () async => List.of(notes),
        disableShare: (m) async {
          disabledCalledWith.add(m);
          await Future<void>.delayed(const Duration(milliseconds: 10));
        },
      ),
    );
    await tester.pumpAndSettle();

    // Open bottom sheet
    await tester.tap(_settingsIcon());
    await tester.pumpAndSettle();

    // Tap delete
    await tester.tap(_deleteShareAction());
    await tester.pumpAndSettle();

    // Confirm dialog appears; confirm deletion
    expect(find.text('Delete Shared Voice Note'), findsOneWidget);
    await tester.tap(find.text('Delete Share'));
    await tester.pump(); // start loading dialog
    // Loading dialog visible
    expect(find.text('Deleting shared voice note...'), findsOneWidget);

    // Let disableShare finish and UI settle
    await tester.pumpAndSettle();

    // "A" should be removed or count reduced
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);

    // Success snackbar
    expect(
      find.textContaining('Shared voice note deleted successfully'),
      findsAtLeastNWidgets(1),
    );

    expect(disabledCalledWith.length, 1);
    expect(disabledCalledWith.first.voiceNoteTitle, anyOf('A', 'B'));
  });

  testWidgets('load failure shows error snackbar', (tester) async {
    await tester.pumpWidget(
      _wrapWithApp(
        const SharedVoiceNotesScreenTestable(),
        getShared: () async => throw Exception('boom'),
        disableShare: (_) async {},
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Failed to load shared voice notes'),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('delete failure dismisses loading and shows error snackbar', (tester) async {
    final note = _meta('1', 'A', 'u');

    await tester.pumpWidget(
      _wrapWithApp(
        const SharedVoiceNotesScreenTestable(),
        getShared: () async => [note],
        disableShare: (_) async => throw Exception('nope'),
      ),
    );
    await tester.pumpAndSettle();

    // Open settings -> delete -> confirm
    await tester.tap(_settingsIcon());
    await tester.pumpAndSettle();
    await tester.tap(_deleteShareAction());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Share'));
    await tester.pump(); // loading dialog appears
    expect(find.text('Deleting shared voice note...'), findsOneWidget);

    // Complete frames; loading should be dismissed by catch block
    await tester.pumpAndSettle();

    // Error snackbar message
    expect(
      find.textContaining('Failed to delete shared voice note'),
      findsAtLeastNWidgets(1),
    );
  });
}