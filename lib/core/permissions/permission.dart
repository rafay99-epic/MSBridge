import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:msbridge/widgets/snakbar.dart';

class PermissionHandler {
  static Future<bool> checkAndRequestFilePermission(
      BuildContext context) async {
    try {
      if (kIsWeb) {
        return true;
      }

      if (Platform.isIOS) {
        return true;
      }

      if (Platform.isAndroid) {
        return await _handleAndroidFilePermission(context);
      }

      return true;
    } catch (e) {
      FlutterBugfender.error("Error checking permissions: $e");
      FlutterBugfender.sendCrash(
          'Error checking permissions: $e', StackTrace.current.toString());
      CustomSnackBar.show(context, "Error checking permissions: $e",
          isSuccess: false);
      return false;
    }
  }

  /// Handle Android-specific file permission logic
  static Future<bool> _handleAndroidFilePermission(BuildContext context) async {
    try {
      // Check Android SDK version to determine appropriate permission
      if (await _isAndroid11OrHigher()) {
        // Android 11+ (API 30+) requires MANAGE_EXTERNAL_STORAGE
        PermissionStatus status = await Permission.manageExternalStorage.status;

        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          if (status.isGranted) {
            return true;
          } else {
            // Permission denied - show guidance and open app settings
            CustomSnackBar.show(
                context,
                "Manage External Storage permission is required for Android 11+. "
                "Please grant this permission in app settings.",
                isSuccess: false);
            await openAppSettings();
            return false;
          }
        } else {
          return true;
        }
      } else {
        // Android <11 (API <30) uses STORAGE permission
        PermissionStatus status = await Permission.storage.status;

        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (status.isGranted) {
            return true;
          } else {
            // Permission denied - show guidance and open app settings
            CustomSnackBar.show(
                context,
                "Storage permission is required to save files. "
                "Please grant this permission in app settings.",
                isSuccess: false);
            await openAppSettings();
            return false;
          }
        } else {
          return true;
        }
      }
    } catch (e) {
      FlutterBugfender.sendCrash('Error requesting Android permissions: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Error requesting Android permissions: $e',
      );
      CustomSnackBar.show(context, "Error requesting Android permissions: $e",
          isSuccess: false);
      return false;
    }
  }

  /// Check if device is running Android 11 or higher (API 30+)
  static Future<bool> _isAndroid11OrHigher() async {
    try {
      if (!Platform.isAndroid) {
        return false;
      }

      // Try to parse Android version from Platform.operatingSystemVersion
      // This is a fallback approach since device_info_plus is not available
      final versionString = Platform.operatingSystemVersion;

      // Look for Android version pattern like "Android 12" or "Android 11"
      if (versionString.contains('Android')) {
        final versionMatch = RegExp(r'Android (\d+)').firstMatch(versionString);
        if (versionMatch != null) {
          final version = int.tryParse(versionMatch.group(1) ?? '');
          if (version != null) {
            // Android 11 = API 30, Android 12 = API 31, etc.
            // Use conservative estimate: assume Android 11+ if version >= 11
            return version >= 11;
          }
        }
      }

      // If we can't determine version, assume older Android for safety
      // This ensures we request the less restrictive STORAGE permission
      return false;
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error checking Android version: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Error checking Android version: $e',
      );
      // If we can't determine SDK version, assume older Android for safety
      return false;
    }
  }
}
