// Dart imports:
import 'dart:io';
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:dio/dio.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

// Project imports:
import 'package:msbridge/core/permissions/permission.dart';
import 'package:msbridge/core/services/update_app/update_service.dart';

class BackgroundDownloadService {
  static Dio? _dio;
  static CancelToken? _cancelToken;
  static double _downloadProgress = 0.0;
  static bool _isDownloading = false;
  static String? _currentFileName;
  static FlutterLocalNotificationsPlugin? _notifications;
  static const int _downloadNotificationId = 1001;
  static const int _completeNotificationId = 1002;

  /// Initialize the background download service
  static Future<void> initialize() async {
    try {
      _dio = Dio();

      // Configure Dio with timeout and headers
      _dio!.options.connectTimeout = const Duration(seconds: 30);
      _dio!.options.receiveTimeout = const Duration(seconds: 30);
      _dio!.options.sendTimeout = const Duration(seconds: 30);

      // Add user agent
      _dio!.options.headers['User-Agent'] = 'MSBridge-App-Update';

      // Initialize notifications
      _notifications = FlutterLocalNotificationsPlugin();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications!.initialize(initSettings);

      // Create notification channel for Android
      if (Platform.isAndroid) {
        const androidChannel = AndroidNotificationChannel(
          'download_channel',
          'Download Progress',
          description: 'Shows download progress for app updates',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        await _notifications!
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(androidChannel);
      }

      FlutterBugfender.log('Background download service initialized');
    } catch (e) {
      FlutterBugfender.error(
          'Failed to initialize background download service: $e');
    }
  }

  /// Show download progress notification
  static Future<void> _showDownloadNotification(
      double progress, String status) async {
    if (_notifications == null) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        'download_channel',
        'Download Progress',
        channelDescription: 'Shows download progress for app updates',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: 100,
        progress: (progress * 100).toInt(),
        ongoing: true,
        autoCancel: false,
        icon: '@mipmap/launcher_icon',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      );

      const iosDetails = DarwinNotificationDetails();
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications!.show(
        _downloadNotificationId,
        'Downloading Update',
        status,
        notificationDetails,
      );
    } catch (e) {
      FlutterBugfender.error('Failed to show download notification: $e');
    }
  }

  /// Show download complete notification
  static Future<void> _showCompleteNotification(String fileName) async {
    if (_notifications == null) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        'download_channel',
        'Download Complete',
        channelDescription: 'Shows when download is complete',
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
        icon: '@mipmap/launcher_icon',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
        actions: [
          const AndroidNotificationAction(
            'install',
            'Install',
            showsUserInterface: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications!.show(
        _completeNotificationId,
        'Download Complete!',
        'Tap to install $fileName',
        notificationDetails,
      );
    } catch (e) {
      FlutterBugfender.error('Failed to show complete notification: $e');
    }
  }

  /// Start downloading APK with background support
  static Future<bool> downloadApk(
    BuildContext context,
    AppVersion version, {
    Function(double progress)? onProgress,
    Function(String status)? onStatus,
  }) async {
    try {
      // Check permissions first
      bool hasPermission =
          await PermissionHandler.checkAndRequestFilePermission(context);
      if (!hasPermission) {
        FlutterBugfender.error('Storage permission denied for APK download');
        return false;
      }

      // Get downloads directory
      Directory? downloadsDirectory;
      if (Platform.isAndroid) {
        downloadsDirectory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadsDirectory = await getApplicationDocumentsDirectory();
      }

      if (downloadsDirectory == null) {
        FlutterBugfender.error('Could not find downloads directory');
        return false;
      }

      // Ensure directory exists
      if (!downloadsDirectory.existsSync()) {
        downloadsDirectory.createSync(recursive: true);
      }

      // Create filename
      final fileName = 'ms-bridge-${version.version}.apk';
      final filePath = '${downloadsDirectory.path}/$fileName';
      _currentFileName = fileName;

      // Fix localhost URLs for device/emulator
      String downloadUrl = version.downloadUrl;
      if (downloadUrl.contains('localhost') ||
          downloadUrl.contains('127.0.0.1')) {
        // Replace localhost with the API server IP
        downloadUrl = downloadUrl.replaceAll('localhost', '192.168.100.146');
        downloadUrl = downloadUrl.replaceAll('127.0.0.1', '192.168.100.146');
        FlutterBugfender.log('Fixed localhost URL: $downloadUrl');
      }

      // Create cancel token for this download
      _cancelToken = CancelToken();
      _isDownloading = true;
      _downloadProgress = 0.0;

      FlutterBugfender.log('Starting APK download: ${version.version}');
      FlutterBugfender.log('Download URL: $downloadUrl');

      // Show initial notification
      await _showDownloadNotification(0.0, 'Starting download...');
      onStatus?.call('Starting download...');

      // Start download
      await _dio!.download(
        downloadUrl,
        filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _downloadProgress = received / total;
            final progressPercent = (_downloadProgress * 100).toInt();

            FlutterBugfender.log('Download progress: $progressPercent%');

            // Update notification
            _showDownloadNotification(
                _downloadProgress, 'Downloading... $progressPercent%');

            // Call callbacks for UI updates
            onProgress?.call(_downloadProgress);
            onStatus?.call('Downloading... $progressPercent%');
          }
        },
      );

      _isDownloading = false;
      FlutterBugfender.log('APK download completed: $filePath');

      // Show completion notification
      await _showCompleteNotification(fileName);
      onStatus?.call('Download completed!');

      // Trigger install intent
      await _triggerInstallIntent(filePath);

      return true;
    } catch (e) {
      _isDownloading = false;
      FlutterBugfender.error('APK download error: $e');
      onStatus?.call('Download failed: $e');
      return false;
    }
  }

  /// Trigger install intent for APK
  static Future<void> _triggerInstallIntent(String filePath) async {
    try {
      // For Android, we can use the file path directly
      // The system will handle the APK installation
      FlutterBugfender.log('Install intent triggered for: $filePath');

      // You can add platform-specific code here to open the APK
      // For now, we'll just log the success
    } catch (e) {
      FlutterBugfender.error('Failed to trigger install intent: $e');
    }
  }

  /// Cancel ongoing download
  static Future<void> cancelDownload() async {
    try {
      if (_cancelToken != null && !_cancelToken!.isCancelled) {
        _cancelToken!.cancel('Download cancelled by user');
        _isDownloading = false;
        _downloadProgress = 0.0;
        _currentFileName = null;
        FlutterBugfender.log('Download cancelled');
      }
    } catch (e) {
      FlutterBugfender.error('Failed to cancel download: $e');
    }
  }

  /// Pause ongoing download
  static Future<void> pauseDownload() async {
    try {
      if (_cancelToken != null && !_cancelToken!.isCancelled) {
        _cancelToken!.cancel('Download paused by user');
        _isDownloading = false;
        FlutterBugfender.log('Download paused');
      }
    } catch (e) {
      FlutterBugfender.error('Failed to pause download: $e');
    }
  }

  /// Resume paused download
  static Future<void> resumeDownload() async {
    // Dio doesn't support resume, so we'll just log it
    FlutterBugfender.log(
        'Resume not supported with Dio - please restart download');
  }

  /// Check if download is in progress
  static bool isDownloadInProgress() {
    return _isDownloading;
  }

  /// Get download progress
  static double getDownloadProgress() {
    return _downloadProgress;
  }

  /// Get download status
  static String getDownloadStatus() {
    if (_isDownloading) {
      return 'Downloading... ${(_downloadProgress * 100).toInt()}%';
    }
    return 'Not downloading';
  }

  /// Get current filename
  static String? getCurrentFileName() {
    return _currentFileName;
  }
}
