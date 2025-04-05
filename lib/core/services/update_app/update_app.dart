// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:install_plugin/install_plugin.dart';
// import 'package:msbridge/core/permissions/permission.dart';
// import 'package:msbridge/widgets/appbar.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:percent_indicator/linear_percent_indicator.dart';
// import 'package:permission_handler/permission_handler.dart';

// class UpdateApp extends StatefulWidget {
//   const UpdateApp({super.key});

//   @override
//   State<UpdateApp> createState() => _UpdateAppState();
// }

// class _UpdateAppState extends State<UpdateApp> {
//   final String apkUrl =
//       'http://rafay99.com/downloads/app/msbridge/MSBridge-release.apk';

//   String? _downloadedFilePath;
//   bool _isDownloading = false;
//   double _downloadProgress = 0.0;
//   Dio? _dio;
//   CancelToken _cancelToken = CancelToken();

//   Future<void> _downloadAndInstallApk(BuildContext context) async {
//     setState(() {
//       _isDownloading = true;
//       _downloadProgress = 0.0;
//       _dio = Dio();
//       _cancelToken = CancelToken();
//     });

//     bool hasPermission =
//         await PermissionHandler.checkAndRequestFilePermission(context);
//     if (!hasPermission) {
//       setState(() {
//         _isDownloading = false;
//         _dio?.close();
//         _dio = null;
//       });
//       return;
//     }

//     var installStatus = await Permission.requestInstallPackages.status;
//     if (!installStatus.isGranted) {
//       installStatus = await Permission.requestInstallPackages.request();
//       if (!installStatus.isGranted) {
//         print("installStatus permission denied.");
//         setState(() {
//           _isDownloading = false;
//           _dio?.close();
//           _dio = null;
//         });
//         return;
//       }
//     }

//     try {
//       Directory? externalDir = await getExternalStorageDirectory();
//       String apkPath = '${externalDir?.path}/app-update.apk';
//       _downloadedFilePath = apkPath;

//       await _dio!.download(
//         apkUrl,
//         apkPath,
//         cancelToken: _cancelToken,
//         onReceiveProgress: (received, total) {
//           if (total != -1) {
//             double progress = received / total;
//             setState(() {
//               _downloadProgress = progress;
//             });
//             print((progress * 100).toStringAsFixed(0) + "%");
//           }
//         },
//       );

//       print('APK downloaded to: $apkPath');

//       InstallPlugin.installApk(_downloadedFilePath!).then((result) {
//         print('Installation result: $result');
//       }).catchError((error) {
//         print('Error installing APK: $error');
//       });
//     } catch (e) {
//       if (e is DioException && CancelToken.isCancel(e)) {
//         print('Download canceled');
//       } else {
//         print('Error downloading APK: $e');
//       }
//     } finally {
//       setState(() {
//         _isDownloading = false;
//         _dio?.close();
//         _dio = null;
//       });
//     }
//   }

//   void _cancelDownload() {
//     if (_dio != null && !_cancelToken.isCancelled) {
//       _cancelToken.cancel("Download canceled");
//       setState(() {
//         _isDownloading = false;
//         _dio?.close();
//         _dio = null;
//       });
//     }
//   }

//   @override
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       backgroundColor: theme.colorScheme.surface,
//       appBar: const CustomAppBar(
//         title: "Update MS Bridge",
//         backbutton: true,
//         showTitle: true,
//       ),
//       body: Center(
//         child: Container(
//           margin: const EdgeInsets.symmetric(horizontal: 20),
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             color: theme.colorScheme.surface,
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 Icons.system_update_alt_rounded,
//                 size: 80,
//                 color: theme.colorScheme.primary,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 "MS Bridge Update",
//                 style: theme.textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "Get the latest features and improvements.",
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   color: theme.hintColor,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 24),
//               _isDownloading
//                   ? Column(
//                       children: [
//                         LinearPercentIndicator(
//                           width: MediaQuery.of(context).size.width * 0.7,
//                           animation: true,
//                           lineHeight: 14.0,
//                           percent: _downloadProgress,
//                           progressColor: theme.colorScheme.secondary,
//                           backgroundColor:
//                               theme.colorScheme.primary.withOpacity(0.15),
//                           barRadius: const Radius.circular(8),
//                           fillColor: theme.colorScheme.surface,
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           "Downloading: ${(_downloadProgress * 100).toStringAsFixed(1)}%",
//                           style: TextStyle(
//                             color: theme.colorScheme.secondary,
//                             fontWeight: FontWeight.w500,
//                             fontSize: 16,
//                             letterSpacing: 0.5,
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         TextButton.icon(
//                           onPressed: _cancelDownload,
//                           icon: const Icon(Icons.cancel, color: Colors.red),
//                           label: const Text(
//                             "Cancel Download",
//                             style: TextStyle(color: Colors.red),
//                           ),
//                         ),
//                       ],
//                     )
//                   : ElevatedButton.icon(
//                       icon: const Icon(Icons.download_rounded),
//                       label: const Text("Download & Install"),
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 32, vertical: 16),
//                         backgroundColor: theme.colorScheme.primary,
//                         foregroundColor: theme.colorScheme.onPrimary,
//                         textStyle: const TextStyle(
//                             fontWeight: FontWeight.bold, fontSize: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       onPressed: () => _downloadAndInstallApk(context),
//                     ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:msbridge/core/permissions/permission.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateApp extends StatefulWidget {
  const UpdateApp({super.key});

  @override
  State<UpdateApp> createState() => _UpdateAppState();
}

class _UpdateAppState extends State<UpdateApp> {
  final String apkUrl =
      'https://rafay99.com/downloads/app/msbridge/MSBridge-release.apk';

  String? _downloadedFilePath;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  Dio? _dio;
  CancelToken _cancelToken = CancelToken();

  Future<void> _downloadAndInstallApk(BuildContext context) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _dio = Dio();
      _cancelToken = CancelToken();
    });

    print("Checking Storage Permission...");
    bool hasPermission =
        await PermissionHandler.checkAndRequestFilePermission(context);
    if (!hasPermission) {
      print("Storage permission NOT granted. Aborting.");
      setState(() {
        _isDownloading = false;
        _dio?.close();
        _dio = null;
      });
      return;
    }
    print("Storage Permission Granted.");

    print("Checking Install Packages Permission...");
    var installStatus = await Permission.requestInstallPackages.status;
    if (!installStatus.isGranted) {
      print("Install Packages permission NOT granted. Requesting...");
      installStatus = await Permission.requestInstallPackages.request();
      if (!installStatus.isGranted) {
        print("Install Packages permission DENIED. Aborting.");
        setState(() {
          _isDownloading = false;
          _dio?.close();
          _dio = null;
        });
        return;
      }
    }
    print("Install Packages Permission Granted.");

    try {
      Directory? externalDir = await getExternalStorageDirectory();
      String apkPath = '${externalDir?.path}/app-update.apk';
      _downloadedFilePath = apkPath;

      print('Starting Download: URL = $apkUrl, Save Path = $apkPath');
      await _dio!.download(
        apkUrl,
        apkPath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total;
            setState(() {
              _downloadProgress = progress;
            });
            print("Download Progress: ${progress * 100}%");
          }
        },
      );

      print('APK downloaded to: $apkPath');

      // SHA-256 for check the signature
      print('Attempting to Install APK from: $_downloadedFilePath');
      InstallPlugin.installApk(_downloadedFilePath!).then((result) {
        print('InstallPlugin.installApk() returned: $result');
      }).catchError((error) {
        print('Error installing APK: $error');
      });
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        print('Download canceled');
      } else {
        print('Error downloading APK: $e');
      }
    } finally {
      setState(() {
        _isDownloading = false;
        _dio?.close();
        _dio = null;
      });
    }
  }

  void _cancelDownload() {
    if (_dio != null && !_cancelToken.isCancelled) {
      print('Canceling download...');
      _cancelToken.cancel("Download canceled");
      setState(() {
        _isDownloading = false;
        _dio?.close();
        _dio = null;
      });
      print('Download canceled successfully.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(
        title: "Update MS Bridge",
        backbutton: true,
        showTitle: true,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.system_update_alt_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                "MS Bridge Update",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Get the latest features and improvements.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _isDownloading
                  ? Column(
                      children: [
                        LinearPercentIndicator(
                          width: MediaQuery.of(context).size.width * 0.7,
                          animation: true,
                          lineHeight: 14.0,
                          percent: _downloadProgress,
                          progressColor: theme.colorScheme.secondary,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.15),
                          barRadius: const Radius.circular(8),
                          fillColor: theme.colorScheme.surface,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Downloading: ${(_downloadProgress * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton.icon(
                          onPressed: _cancelDownload,
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text(
                            "Cancel Download",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.download_rounded),
                      label: const Text("Download & Install"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _downloadAndInstallApk(context),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
