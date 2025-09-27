import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:msbridge/widgets/snakbar.dart';

class NotificationPermissionHandler {
  static Future<bool> checkAndRequestNotificationPermission(
      BuildContext context) async {
    // Check if notification permission is granted
    PermissionStatus status = await Permission.notification.status;

    if (status.isGranted) {
      return true;
    }

    // Request notification permission
    status = await Permission.notification.request();

    if (status.isGranted) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          "Notification permission granted! You'll now receive daily streak reminders.",
          isSuccess: true,
        );
      }
      return true;
    } else {
      if (context.mounted) {
        // Show dialog explaining why notification permission is needed
        _showPermissionExplanationDialog(context);
      }
      return false;
    }
  }

  static void _showPermissionExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notification Permission Required"),
        content: const Text(
          "To help you maintain your daily streak and get reminders to use the app, "
          "we need notification permission. You can enable this later in your device settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Maybe Later"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  static Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  static Future<void> openNotificationSettings() async {
    await openAppSettings();
  }
}
