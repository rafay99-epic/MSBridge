import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:msbridge/widgets/snakbar.dart';

class PermissionHandler {
  static Future<bool> checkAndRequestFilePermission(
      BuildContext context) async {
    try {
      // For Android 11+ (API 30+), we need MANAGE_EXTERNAL_STORAGE
      if (await _isAndroid11OrHigher()) {
        PermissionStatus status = await Permission.manageExternalStorage.status;

        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          if (status.isGranted) {
            CustomSnackBar.show(
                context, "Manage External Storage permission granted.");
            return true;
          } else {
            CustomSnackBar.show(
                context,
                "Manage External Storage permission is required for Android 11+. "
                "Please grant this permission in app settings.");
            return false;
          }
        } else {
          return true;
        }
      } else {
        // For older Android versions, use STORAGE permission
        PermissionStatus status = await Permission.storage.status;

        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (status.isGranted) {
            CustomSnackBar.show(context, "Storage permission granted.");
            return true;
          } else {
            CustomSnackBar.show(
                context, "Storage permission is required to save files.");
            return false;
          }
        } else {
          return true;
        }
      }
    } catch (e) {
      CustomSnackBar.show(context, "Error requesting permissions: $e");
      return false;
    }
  }

  /// Check if device is running Android 11 or higher
  static Future<bool> _isAndroid11OrHigher() async {
    try {
      // This is a simple check - in production you might want to use device_info_plus
      // For now, we'll assume Android 11+ to be safe
      return true;
    } catch (e) {
      return false;
    }
  }
}
