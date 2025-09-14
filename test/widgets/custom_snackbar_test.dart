import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:line_icons/line_icons.dart';

// Adjust this import if your CustomSnackBar file is in a different location.
// We attempt the common path "lib/widgets/custom_snackbar.dart".
import 'package:msbridge//home/jailuser/git/lib/widgets/custom_snackbar.dart' as under_test;

void main() {
  group('CustomSnackBar.show', () {
    // Helper to build a testable app with Scaffold and provide a BuildContext.
    Widget _appWithScaffold(ThemeData theme, {required Widget child}) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => child,
          ),
        ),
      );
    }

    // Extract the SnackBar widget currently displayed by the ScaffoldMessenger.
    SnackBar? _locateSnackBar(WidgetTester tester) {
      final snackBarFinder = find.byType(SnackBar);
      if (snackBarFinder.evaluate().isEmpty) return null;
      return tester.widget<SnackBar>(snackBarFinder);
    }

    // Find the primary decorated container inside the SnackBar content.
    // This is the Container that applies BoxDecoration with backgroundColor,
    // borderRadius, border, and shadow.
    BoxDecoration? _snackContentDecoration(WidgetTester tester) {
      final containerFinder = find.descendant(
        of: find.byType(SnackBar),
        matching: find.byWidgetPredicate((w) {
          if (w is Container) {
            final d = w.decoration;
            return d is BoxDecoration && d.borderRadius \!= null;
          }
          return false;
        }),
      );
      if (containerFinder.evaluate().isEmpty) return null;
      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration;
      return decoration is BoxDecoration ? decoration : null;
    }

    Future<void> _showSnackBar(
      WidgetTester tester, {
      required String message,
      required under_test.SnackBarType type,
      ThemeData? theme,
    }) async {
      final ThemeData effectiveTheme = theme ?? ThemeData.from(colorScheme: const ColorScheme.light());
      await tester.pumpWidget(
        _appWithScaffold(effectiveTheme, child: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  under_test.CustomSnackBar.show(context, message, type);
                },
                child: const Text('Show'),
              ),
            );
          },
        )),
      );

      // Tap to trigger show
      await tester.tap(find.text('Show'));
      await tester.pump(); // start animation
      await tester.pump(const Duration(milliseconds: 100)); // settle initial frames
    }

    testWidgets('renders floating transparent SnackBar with expected base props', (tester) async {
      await _showSnackBar(
        tester,
        message: 'Hello world',
        type: under_test.SnackBarType.info,
      );

      final sb = _locateSnackBar(tester);
      expect(sb, isNotNull);
      expect(sb\!.backgroundColor, Colors.transparent);
      expect(sb.behavior, SnackBarBehavior.floating);
      expect(sb.elevation, 0);
      expect(sb.duration, const Duration(seconds: 3));
      // margin: EdgeInsets.symmetric(horizontal: 24, vertical: 12)
      final EdgeInsets m = sb.margin as EdgeInsets;
      expect(m.horizontal, 48);
      expect(m.vertical, 24);
      // RoundedRectangleBorder with radius 20
      expect(sb.shape, isA<RoundedRectangleBorder>());
      final r = sb.shape as RoundedRectangleBorder;
      final radii = r.borderRadius as BorderRadius;
      expect(radii.topLeft.x, 20);
      expect(radii.topLeft.y, 20);
    });

    testWidgets('shows message text with center alignment, max 2 lines and ellipsis', (tester) async {
      const longMsg = 'A' * 300;
      await _showSnackBar(
        tester,
        message: longMsg,
        type: under_test.SnackBarType.info,
      );

      final textFinder = find.descendant(
        of: find.byType(SnackBar),
        matching: find.byType(Text),
      ).first;

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.data, longMsg);
      expect(textWidget.textAlign, TextAlign.center);
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);
      // font weight and size are set; we can't guarantee font is available in test env,
      // but we can still verify the numeric values if style exists.
      final style = textWidget.style\!;
      expect(style.fontSize, 15);
      expect(style.fontWeight, FontWeight.w600);
    });

    testWidgets('success type uses expected icon and themed colors', (tester) async {
      final theme = ThemeData.from(colorScheme: const ColorScheme.light(
        primary: Colors.green,
        onPrimary: Colors.white,
      ));
      await _showSnackBar(
        tester,
        message: 'Saved\!',
        type: under_test.SnackBarType.success,
        theme: theme,
      );

      // Icon should be LineIcons.checkCircle with iconColor onPrimary
      final iconFinder = find.descendant(
        of: find.byType(SnackBar),
        matching: find.byWidgetPredicate((w) => w is Icon && w.icon == LineIcons.checkCircle),
      );
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, theme.colorScheme.onPrimary);

      // Background color on main decorated container is primary.withOpacity(0.95)
      final deco = _snackContentDecoration(tester);
      expect(deco, isNotNull);
      expect(deco\!.color, theme.colorScheme.primary.withOpacity(0.95));

      // Border color is primary with 0.15 opacity
      final border = deco.border as Border?;
      expect(border, isNotNull);
      expect(border\!.top.color, theme.colorScheme.primary.withOpacity(0.15));
      // Border radius 20 as well (inner container)
      final br = deco.borderRadius as BorderRadius?;
      expect(br, isNotNull);
      expect(br\!.topLeft.x, 20);
    });

    testWidgets('error type uses expected icon and themed colors', (tester) async {
      final theme = ThemeData.from(colorScheme: const ColorScheme.light(
        error: Colors.red,
        errorContainer: Color(0xFFFFCDD2),
        onErrorContainer: Colors.black,
      ));
      await _showSnackBar(
        tester,
        message: 'Failed\!',
        type: under_test.SnackBarType.error,
        theme: theme,
      );

      final iconFinder = find.descendant(
        of: find.byType(SnackBar),
        matching: find.byWidgetPredicate((w) => w is Icon && w.icon == LineIcons.exclamationTriangle),
      );
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, theme.colorScheme.onErrorContainer);

      final deco = _snackContentDecoration(tester);
      expect(deco, isNotNull);
      expect(deco\!.color, theme.colorScheme.errorContainer.withOpacity(0.95));

      final border = deco.border as Border?;
      expect(border, isNotNull);
      expect(border\!.top.color, theme.colorScheme.error.withOpacity(0.15));
    });

    testWidgets('warning type uses expected icon and fixed colors', (tester) async {
      // warning uses Colors.orange + white, not theme-derived
      await _showSnackBar(
        tester,
        message: 'Beware\!',
        type: under_test.SnackBarType.warning,
      );

      final iconFinder = find.descendant(
        of: find.byType(SnackBar),
        matching: find.byWidgetPredicate((w) => w is Icon && w.icon == LineIcons.exclamationCircle),
      );
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, Colors.white);

      final deco = _snackContentDecoration(tester);
      expect(deco, isNotNull);
      expect(deco\!.color, Colors.orange.withOpacity(0.95));

      final border = deco.border as Border?;
      expect(border, isNotNull);
      expect(border\!.top.color, Colors.orange.withOpacity(0.15));
    });

    testWidgets('info type uses expected icon and themed secondary colors', (tester) async {
      final theme = ThemeData.from(colorScheme: const ColorScheme.light(
        secondary: Colors.blue,
        onSecondary: Colors.white,
      ));
      await _showSnackBar(
        tester,
        message: 'FYI',
        type: under_test.SnackBarType.info,
        theme: theme,
      );

      final iconFinder = find.descendant(
        of: find.byType(SnackBar),
        matching: find.byWidgetPredicate((w) => w is Icon && w.icon == LineIcons.infoCircle),
      );
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, theme.colorScheme.onSecondary);

      final deco = _snackContentDecoration(tester);
      expect(deco, isNotNull);
      expect(deco\!.color, theme.colorScheme.secondary.withOpacity(0.95));

      final border = deco.border as Border?;
      expect(border, isNotNull);
      expect(border\!.top.color, theme.colorScheme.secondary.withOpacity(0.15));
    });

    testWidgets('close button hides the currently visible SnackBar', (tester) async {
      await _showSnackBar(
        tester,
        message: 'Dismiss me',
        type: under_test.SnackBarType.info,
      );

      // Click the close button (LineIcons.times) and ensure the SnackBar hides
      final closeIconFinder = find.descendant(
        of: find.byType(SnackBar),
        matching: find.byWidgetPredicate((w) => w is Icon && w.icon == LineIcons.times),
      );
      expect(closeIconFinder, findsOneWidget);

      await tester.tap(closeIconFinder);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // SnackBar should be gone (or in the process of dismissing)
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}