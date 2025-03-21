import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:msbridge/widgets/snakbar.dart';

class PermissionHandler {
  static Future<bool> checkAndRequestFilePermission(
      BuildContext context) async {
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
            "Manage External Storage permission is required. "
            "Attempting to request Storage permission instead.");

        status = await Permission.storage.request();
        if (status.isGranted) {
          CustomSnackBar.show(context, "Storage permission granted.");
          return true;
        } else {
          CustomSnackBar.show(
              context, "Storage permission is required to save the file.");
          return false;
        }
      }
    } else {
      return true;
    }
  }
}
