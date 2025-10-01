// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:permission_handler/permission_handler.dart';

// Project imports:
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

  static Future<bool> _handleAndroidFilePermission(BuildContext context) async {
    try {
      PermissionStatus status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }

      if (status.isGranted) return true;
      if (!context.mounted) return false;
      CustomSnackBar.show(
        context,
        "Storage access denied. Unable to save to Downloads without permission.",
        isSuccess: false,
      );
      return false;
    } catch (e) {
      FlutterBugfender.sendCrash('Error requesting Android permissions: $e',
          StackTrace.current.toString());
      if (!context.mounted) return false;
      CustomSnackBar.show(context, "Error requesting Android permissions: $e",
          isSuccess: false);
      return false;
    }
  }
}
