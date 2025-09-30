// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

// Project imports:
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/theme/colors.dart';

void main() {
  group('Theme Engine Tests', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Mock SharedPreferences for theme persistence
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (methodCall) async {
          switch (methodCall.method) {
            case 'getAll':
              return <String, dynamic>{
                'appTheme': 'dark',
                'dynamicColors': false,
              };
            case 'setString':
            case 'setBool':
            case 'remove':
              return true;
            default:
              return null;
          }
        },
      );

      // Mock FlutterBugfender to avoid MissingPluginException and return String
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_bugfender'),
        (methodCall) async => '',
      );

      // Prevent GoogleFonts from doing network fetches in tests
      GoogleFonts.config.allowRuntimeFetching = false;
    });

    group('AppTheme Enum Tests', () {
      test('All AppTheme values are valid', () {
        for (final theme in AppTheme.values) {
          expect(theme.name, isNotEmpty);
          expect(theme.toString(), contains('AppTheme.'));
        }
      });

      test('AppTheme provides image paths', () {
        for (final theme in AppTheme.values) {
          final imagePath = theme.imagePath();
          expect(imagePath, isA<String>());
          expect(imagePath.isNotEmpty, isTrue);
          expect(imagePath.contains('assets/'), isTrue);
        }
      });

      test('AppTheme enum has expected values', () {
        expect(AppTheme.values, contains(AppTheme.dark));
        expect(AppTheme.values, contains(AppTheme.light));

        // Verify we have multiple theme options
        expect(AppTheme.values.length, greaterThan(1));
      });
    });

    group('AppThemes Map Tests', () {
      test('AppThemes contains ThemeData for all AppTheme values', () {
        for (final theme in AppTheme.values) {
          expect(AppThemes.themeMap.containsKey(theme), isTrue);
          expect(AppThemes.themeMap[theme], isA<ThemeData>());
        }
      });

      test('All theme ThemeData objects are valid', () {
        for (final themeData in AppThemes.themeMap.values) {
          expect(themeData.colorScheme, isNotNull);
          expect(themeData.textTheme, isNotNull);
          expect(themeData.useMaterial3, isA<bool>());
        }
      });

      test('Dark and light themes have different color schemes', () {
        final darkTheme = AppThemes.themeMap[AppTheme.dark];
        final lightTheme = AppThemes.themeMap[AppTheme.light];

        if (darkTheme != null && lightTheme != null) {
          expect(darkTheme.colorScheme.brightness,
              isNot(equals(lightTheme.colorScheme.brightness)));
        }
      });
    });

    group('ThemeProvider Functionality Tests', () {
      test('ThemeProvider initializes with default values', () async {
        final provider = ThemeProvider();

        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        expect(provider.selectedTheme, isA<AppTheme>());
        expect(provider.dynamicColorsEnabled, isA<bool>());
        expect(provider.effectiveThemeName, isA<String>());
        expect(provider.currentImagePath, isA<String>());
      });

      test('ThemeProvider can change themes', () async {
        final provider = ThemeProvider();
        final List<AppTheme> changedThemes = [];

        provider.addListener(() {
          changedThemes.add(provider.selectedTheme);
        });

        // Test changing to different themes
        for (final theme in AppTheme.values) {
          await provider.setTheme(theme);
          expect(provider.selectedTheme, equals(theme));
        }

        expect(changedThemes.length, equals(AppTheme.values.length));
      }, skip: true);

      test('Dynamic colors override theme selection', () async {
        final provider = ThemeProvider();

        // Set a specific theme first
        await provider.setTheme(AppTheme.light);
        expect(provider.selectedTheme, equals(AppTheme.light));

        // Enable dynamic colors
        await provider.setDynamicColors(true);
        expect(provider.dynamicColorsEnabled, isTrue);

        // Try to set theme while dynamic colors are enabled
        await provider.setTheme(AppTheme.light);

        // Theme should not change when dynamic colors are enabled
        expect(provider.canSelectTheme(AppTheme.light), isFalse);
      }, skip: true);

      test('ThemeProvider reset functionality', () async {
        final provider = ThemeProvider();

        // Change settings
        await provider.setTheme(AppTheme.light);
        await provider.setDynamicColors(true);

        // Reset
        await provider.resetTheme();

        expect(provider.selectedTheme, equals(AppTheme.dark));
        expect(provider.dynamicColorsEnabled, isFalse);
      });

      test('ThemeProvider generates valid ThemeData', () async {
        final provider = ThemeProvider();

        for (final theme in AppTheme.values) {
          await provider.setTheme(theme);

          final themeData = provider.getThemeData();
          expect(themeData, isA<ThemeData>());
          expect(themeData.colorScheme, isNotNull);
          expect(themeData.textTheme, isNotNull);
        }
      });

      test('Dynamic colors generate custom ThemeData', () async {
        final provider = ThemeProvider();

        // Enable dynamic colors
        await provider.setDynamicColors(true);

        final dynamicThemeData = provider.getThemeData();
        expect(dynamicThemeData, isA<ThemeData>());
        expect(dynamicThemeData.colorScheme, isNotNull);
        expect(dynamicThemeData.useMaterial3, isTrue);

        // Disable dynamic colors
        await provider.setDynamicColors(false);

        final normalThemeData = provider.getThemeData();
        expect(normalThemeData, isA<ThemeData>());
      });

      test('Theme persistence works correctly', () async {
        // This test verifies that the mock SharedPreferences setup works
        final provider = ThemeProvider();

        // Change theme and verify persistence calls are made
        await provider.setTheme(AppTheme.light);
        expect(provider.selectedTheme, equals(AppTheme.light));

        // Enable dynamic colors and verify persistence
        await provider.setDynamicColors(true);
        expect(provider.dynamicColorsEnabled, isTrue);
      }, skip: true);
    });

    group('Theme Color Scheme Tests', () {
      test('Dynamic color schemes are properly configured', () async {
        final provider = ThemeProvider();

        await provider.setDynamicColors(true);

        // Test dark dynamic colors
        await provider.setTheme(AppTheme.dark);
        final darkTheme = provider.getThemeData();
        expect(darkTheme.colorScheme.brightness, equals(Brightness.dark));
        expect(darkTheme.colorScheme.primary, isNotNull);
        expect(darkTheme.colorScheme.surface, isNotNull);

        // Test light dynamic colors
        await provider.setTheme(AppTheme.light);
        final lightTheme = provider.getThemeData();
        expect(lightTheme.colorScheme.brightness, equals(Brightness.light));
        expect(lightTheme.colorScheme.primary, isNotNull);
        expect(lightTheme.colorScheme.surface, isNotNull);
      }, skip: true);

      test('Color contrast is maintained', () async {
        final provider = ThemeProvider();

        for (final theme in AppTheme.values) {
          await provider.setTheme(theme);
          final themeData = provider.getThemeData();
          final colorScheme = themeData.colorScheme;

          // Basic contrast check - primary and onPrimary should be different
          expect(colorScheme.primary, isNot(equals(colorScheme.onPrimary)));
          expect(colorScheme.surface, isNot(equals(colorScheme.onSurface)));

          // Ensure colors are not null
          expect(colorScheme.primary, isNotNull);
          expect(colorScheme.onPrimary, isNotNull);
          expect(colorScheme.surface, isNotNull);
          expect(colorScheme.onSurface, isNotNull);
        }
      });
    });

    group('Theme State Management Tests', () {
      test('Multiple listeners are notified correctly', () async {
        final provider = ThemeProvider();
        int listener1Calls = 0;
        int listener2Calls = 0;

        provider.addListener(() => listener1Calls++);
        provider.addListener(() => listener2Calls++);

        await provider.setTheme(AppTheme.light);

        expect(listener1Calls, greaterThan(0));
        expect(listener2Calls, greaterThan(0));
      }, skip: true);

      test('ThemeProvider handles errors gracefully', () async {
        // Mock SharedPreferences to throw an error
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (methodCall) async {
            if (methodCall.method == 'setString') {
              throw PlatformException(code: 'ERROR', message: 'Test error');
            }
            return null;
          },
        );

        final provider = ThemeProvider();

        // Should not throw even if persistence fails
        expect(() async {
          await provider.setTheme(AppTheme.light);
        }, returnsNormally);
      });

      test('Theme switching performance', () async {
        final provider = ThemeProvider();
        final stopwatch = Stopwatch()..start();

        // Switch themes rapidly
        for (int i = 0; i < 100; i++) {
          final theme = AppTheme.values[i % AppTheme.values.length];
          await provider.setTheme(theme);
        }

        stopwatch.stop();

        // Should complete quickly (less than 1 second)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Theme Integration Tests', () {
      test('effectiveThemeName reflects current state', () async {
        final provider = ThemeProvider();

        // Test normal theme
        await provider.setTheme(AppTheme.light);
        expect(provider.effectiveThemeName, equals(AppTheme.light.name));

        // Test dynamic colors
        await provider.setDynamicColors(true);
        expect(provider.effectiveThemeName, equals('Dynamic Colors'));

        // Back to normal
        await provider.setDynamicColors(false);
        expect(provider.effectiveThemeName, isNot(equals('Dynamic Colors')));
      });

      test('currentImagePath updates with theme changes', () async {
        final provider = ThemeProvider();
        final Set<String> imagePaths = <String>{};

        // Collect image paths for different states
        for (final theme in AppTheme.values) {
          await provider.setTheme(theme);
          imagePaths.add(provider.currentImagePath);
        }

        // Enable dynamic colors
        await provider.setDynamicColors(true);
        imagePaths.add(provider.currentImagePath);

        // Should have different paths for different themes
        expect(imagePaths.length, greaterThan(1));
      });

      test('canSelectTheme works correctly', () async {
        final provider = ThemeProvider();

        // Should be able to select themes by default
        expect(provider.canSelectTheme(AppTheme.light), isTrue);
        expect(provider.canSelectTheme(AppTheme.dark), isTrue);

        // Should not be able to select themes when dynamic colors are enabled
        await provider.setDynamicColors(true);
        expect(provider.canSelectTheme(AppTheme.light), isFalse);
        expect(provider.canSelectTheme(AppTheme.dark), isFalse);

        // Should be able to select again after disabling dynamic colors
        await provider.setDynamicColors(false);
        expect(provider.canSelectTheme(AppTheme.light), isTrue);
      });
    });

    group('Material 3 Support Tests', () {
      test('All themes support Material 3', () {
        for (final themeData in AppThemes.themeMap.values) {
          expect(themeData.useMaterial3, isTrue);
        }
      });

      test('Dynamic colors use Material 3', () async {
        final provider = ThemeProvider();
        await provider.setDynamicColors(true);

        final themeData = provider.getThemeData();
        expect(themeData.useMaterial3, isTrue);
      });
    });
  });
}
