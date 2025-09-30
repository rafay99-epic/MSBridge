// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';

// Project imports:
import 'package:msbridge/config/config.dart';
import 'package:msbridge/core/services/update_app/background_download_service.dart';
import 'package:msbridge/core/services/update_app/update_service.dart';
import 'package:msbridge/widgets/enhanced_update_dialog.dart';

class UpdateManager {
  static const Duration _checkInterval = UpdateConfig.checkInterval;
  static DateTime? _lastCheck;
  static bool _isChecking = false;

  /// Initialize the update manager
  static Future<void> initialize() async {
    try {
      await BackgroundDownloadService.initialize();
      FlutterBugfender.log('UpdateManager initialized successfully');
    } catch (e) {
      FlutterBugfender.error('Failed to initialize UpdateManager: $e');
    }
  }

  /// Check for updates on app startup with health check
  static Future<void> checkForUpdatesOnStartup(BuildContext context) async {
    if (_isChecking) return;

    try {
      _isChecking = true;

      // Silent health check - no loading dialog
      FlutterBugfender.log('Checking system health...');
      final isLive = await UpdateService.isSystemLive();

      if (!isLive) {
        if (context.mounted) {
          _showServerDownDialog(context);
        }
        return;
      }

      FlutterBugfender.log('System is live, checking for updates...');

      // Check for updates
      final updateResult = await UpdateService.checkForUpdates();

      if (updateResult.hasError) {
        FlutterBugfender.error('Update check failed: ${updateResult.error}');
        // Don't show error dialog for update check failures - just log
        return;
      }

      if (updateResult.updateAvailable) {
        FlutterBugfender.log(
            'Update available: ${updateResult.latestVersion?.version}');
        if (context.mounted) {
          _showEnhancedUpdateDialog(context, updateResult);
        }
      } else {
        FlutterBugfender.log('App is up to date');
        // Don't show anything if app is up to date
      }

      _lastCheck = DateTime.now();
    } catch (e) {
      FlutterBugfender.error('Update check error: $e');
      // Don't show error dialog for silent failures - just log
    } finally {
      _isChecking = false;
    }
  }

  /// Manually check for updates
  static Future<void> checkForUpdatesManually(BuildContext context) async {
    if (_isChecking) return;

    try {
      _isChecking = true;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // First check if system is live
      final isLive = await UpdateService.isSystemLive();
      if (!isLive) {
        if (context.mounted) {
          Navigator.of(context).pop();
          _showServerDownDialog(context);
        }
        return;
      }

      // Check for updates
      final updateResult = await UpdateService.checkForUpdates();

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (updateResult.hasError) {
        if (context.mounted) {
          _showErrorDialog(context, updateResult.error!);
        }
        return;
      }

      if (updateResult.updateAvailable) {
        if (context.mounted) {
          _showEnhancedUpdateDialog(context, updateResult);
        }
      } else {
        // Check if user has a newer version than server
        if (updateResult.message?.contains('newer version') == true) {
          if (context.mounted) {
            _showNewerVersionDialog(context, updateResult.message!);
          }
        } else {
          if (context.mounted) {
            _showNoUpdateDialog(
                context, updateResult.message ?? 'You are  up to date!');
          }
        }
      }

      _lastCheck = DateTime.now();
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      if (context.mounted) {
        _showErrorDialog(context, 'Error checking for updates: $e');
      }
    } finally {
      _isChecking = false;
    }
  }

  /// Check if enough time has passed since last check
  static bool shouldCheckForUpdates() {
    if (_lastCheck == null) return true;
    return DateTime.now().difference(_lastCheck!) >= _checkInterval;
  }

  static void _showEnhancedUpdateDialog(
      BuildContext context, UpdateCheckResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedUpdateDialog(
        updateResult: result,
        onDismiss: () {
          // Optionally save user preference to not show again for this version
        },
      ),
    );
  }

  static void _showNoUpdateDialog(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Check for Updates',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showNewerVersionDialog(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.new_releases,
                color: colorScheme.secondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Version Check',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.error,
                color: colorScheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Update Check Failed',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showServerDownDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.cloud_off,
                  color: colorScheme.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Server Unavailable',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sorry, the server is currently down. This could be due to:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReasonItem(
                        theme, colorScheme, '• Network connectivity issues'),
                    _buildReasonItem(
                        theme, colorScheme, '• Server maintenance'),
                    _buildReasonItem(
                        theme, colorScheme, '• Temporary server downtime'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This ensures the app and server work together continuously.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Exit the app completely
                SystemNavigator.pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurface.withValues(alpha: 0.7),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Exit App'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Try again by checking health
                _retryHealthCheck(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildReasonItem(
      ThemeData theme, ColorScheme colorScheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  static Future<void> _retryHealthCheck(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(
              'Checking connection...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );

    try {
      FlutterBugfender.log('Starting retry health check...');

      // Check health again with timeout
      final isLive = await UpdateService.isSystemLive().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          FlutterBugfender.error('Health check timeout during retry');
          return false;
        },
      );

      FlutterBugfender.log('Retry health check result: $isLive');

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (isLive) {
        if (context.mounted) {
          // Server is back up, show success and continue with update check
          _showConnectionRestoredDialog(context);
        }
      } else {
        // Still down, show server down dialog again
        if (context.mounted) {
          _showServerDownDialog(context);
        }
      }
    } catch (e) {
      FlutterBugfender.error('Retry health check error: $e');

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error dialog instead of server down dialog
      if (context.mounted) {
        _showErrorDialog(
            context, 'Connection check failed. Please try again later.');
      }
    }
  }

  static void _showConnectionRestoredDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Connection Restored!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Great! The server is back online. The app will now continue normally.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Continue with update check
              if (context.mounted) {
                checkForUpdatesOnStartup(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
