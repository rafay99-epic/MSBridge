// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

// Project imports:
import 'package:msbridge/core/permissions/permission.dart';

class UpdateAppRepo {
  final String apkUrl;
  String? downloadedFilePath;
  Dio? dio;
  CancelToken cancelToken = CancelToken();

  UpdateAppRepo({required this.apkUrl});

  Future<bool> downloadAndInstallApk(
      BuildContext context,
      Function(double) onProgress,
      Function(bool) setIsDownloading,
      Function() onDownloadComplete,
      Function(String) onError) async {
    setIsDownloading(true);
    cancelToken = CancelToken();

    bool hasPermission =
        await PermissionHandler.checkAndRequestFilePermission(context);
    if (!hasPermission) {
      setIsDownloading(false);
      dio?.close();
      dio = null;
      onError("Storage permission denied.");
      return false;
    }

    try {
      Directory? externalDir = await getExternalStorageDirectory();
      String apkPath = '${externalDir?.path}/MSBridge-Update.apk';
      downloadedFilePath = apkPath;
      dio = Dio();

      await dio!.download(
        apkUrl,
        apkPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total;
            onProgress(progress);
          }
        },
      );

      onDownloadComplete();

      // Show success message and guide user to install manually
      return true;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        onError("Download canceled");
      } else {
        onError("Error downloading APK: $e");
      }
    } finally {
      setIsDownloading(false);
      dio?.close();
      dio = null;
    }
    return false;
  }

  void cancelDownload() {
    if (dio != null && !cancelToken.isCancelled) {
      cancelToken.cancel("Download canceled");
      dio?.close();
      dio = null;
    }
  }
}
