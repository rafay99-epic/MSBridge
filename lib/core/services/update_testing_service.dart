import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:msbridge/core/services/update_manager.dart';
import 'package:msbridge/core/services/update_service.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:msbridge/widgets/enhanced_update_dialog.dart';

class UpdateTestingService {
  /// Simulate a version downgrade for testing purposes
  /// This should only be used in debug mode
  static Future<void> simulateVersionDowngrade(BuildContext context) async {
    if (!_isDebugMode()) {
      FlutterBugfender.error(
          'Version downgrade simulation only available in debug mode');
      return;
    }

    try {
      // Show confirmation dialog
      final shouldProceed = await _showConfirmationDialog(context);
      if (!shouldProceed) return;

      // Simulate downgrade by temporarily modifying the version check
      await _simulateDowngrade(context);
    } catch (e) {
      FlutterBugfender.error('Error simulating version downgrade: $e');
      CustomSnackBar.show(
        context,
        'Error simulating downgrade: $e',
        isSuccess: false,
      );
    }
  }

  /// Check if we're in debug mode
  static bool _isDebugMode() {
    // In a real app, you might want to check for debug flags or build configuration
    return true; // For now, always allow in this implementation
  }

  /// Show confirmation dialog for testing
  static Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Testing Mode'),
            content: const Text(
              'This will simulate a version downgrade to test the update flow. '
              'The app will check for updates and show the update dialog if available. '
              'Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Simulate the downgrade process
  static Future<void> _simulateDowngrade(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Simulating version downgrade...'),
          ],
        ),
      ),
    );

    try {
      // Wait a moment for the dialog to show
      await Future.delayed(const Duration(milliseconds: 500));

      // Force a manual update check (this will trigger the update flow)
      await UpdateManager.checkForUpdatesManually(context);

      // Close loading dialog
      Navigator.of(context).pop();

      CustomSnackBar.show(
        context,
        'Version downgrade simulation completed. Check for update dialog.',
        isSuccess: true,
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      rethrow;
    }
  }

  /// Test the update flow with a specific version
  static Future<void> testUpdateFlow(
    BuildContext context, {
    required String testVersion,
    required int testBuildNumber,
  }) async {
    if (!_isDebugMode()) {
      FlutterBugfender.error(
          'Update flow testing only available in debug mode');
      return;
    }

    try {
      // Create a mock update result for testing
      final mockResult = UpdateCheckResult(
        isLive: true,
        updateAvailable: true,
        message: 'Test update available',
        latestVersion: AppVersion(
          version: testVersion,
          buildNumber: testBuildNumber,
          downloadUrl:
              'https://msbridge.rafay99.com/downloads/ms-bridge-$testVersion.apk',
          changelog: 'This is a test update with the following features:\n'
              '• Enhanced user interface\n'
              '• Improved performance\n'
              '• Bug fixes and stability improvements\n'
              '• New features and functionality',
          releaseDate: DateTime.now().toIso8601String().split('T')[0],
        ),
        currentVersion: AppVersion(
          version: '7.6.0',
          buildNumber: 13,
          downloadUrl: '',
          releaseDate: '2024-01-01',
        ),
      );

      // Show the enhanced update dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => EnhancedUpdateDialog(
          updateResult: mockResult,
          onDismiss: () {
            FlutterBugfender.log('Test update dialog dismissed');
          },
        ),
      );
    } catch (e) {
      FlutterBugfender.error('Error testing update flow: $e');
      CustomSnackBar.show(
        context,
        'Error testing update flow: $e',
        isSuccess: false,
      );
    }
  }

  /// Get testing options for the settings screen
  static List<Map<String, dynamic>> getTestingOptions() {
    return [
      {
        'title': 'Simulate Version Downgrade',
        'subtitle': 'Test the update flow by simulating a downgrade',
        'action': 'simulate_downgrade',
      },
      {
        'title': 'Test Update Dialog (v7.9)',
        'subtitle': 'Show update dialog for version 7.9.0',
        'action': 'test_dialog_7_9',
      },
      {
        'title': 'Test Update Dialog (v8.0)',
        'subtitle': 'Show update dialog for version 8.0.0',
        'action': 'test_dialog_8_0',
      },
      {
        'title': 'Test Update Dialog (v8.1)',
        'subtitle': 'Show update dialog for version 8.1.0',
        'action': 'test_dialog_8_1',
      },
    ];
  }

  /// Handle testing action
  static Future<void> handleTestingAction(
    BuildContext context,
    String action,
  ) async {
    switch (action) {
      case 'simulate_downgrade':
        await simulateVersionDowngrade(context);
        break;
      case 'test_dialog_7_9':
        await testUpdateFlow(context,
            testVersion: '7.9.0', testBuildNumber: 16);
        break;
      case 'test_dialog_8_0':
        await testUpdateFlow(context,
            testVersion: '8.0.0', testBuildNumber: 17);
        break;
      case 'test_dialog_8_1':
        await testUpdateFlow(context,
            testVersion: '8.1.0', testBuildNumber: 18);
        break;
      default:
        FlutterBugfender.error('Unknown testing action: $action');
    }
  }
}
