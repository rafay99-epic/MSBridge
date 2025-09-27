import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';
import 'package:msbridge/core/permissions/permission.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

class VoiceNoteExportService {
  static const String _exportNotificationChannelId = 'voice_export_channel';
  static const String _exportNotificationChannelName = 'Voice Note Export';
  static const int _exportNotificationId = 2001;
  static const int _exportCompleteNotificationId = 2002;

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Initialize the voice note export service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      if (Platform.isAndroid) {
        const androidChannel = AndroidNotificationChannel(
          _exportNotificationChannelId,
          _exportNotificationChannelName,
          description: 'Shows voice note export progress and completion',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(androidChannel);
      }

      _isInitialized = true;
      FlutterBugfender.log('Voice note export service initialized');
    } catch (e, stackTrace) {
      FlutterBugfender.sendCrash(
          'Failed to initialize voice note export service: $e',
          stackTrace.toString());
      FlutterBugfender.error(
          'Failed to initialize voice note export service: $e');
    }
  }

  /// Export voice note to Downloads folder
  static Future<bool> exportVoiceNote(
    BuildContext context,
    VoiceNoteModel voiceNote, {
    Function(double progress)? onProgress,
    Function(String status)? onStatus,
  }) async {
    try {
      await initialize();
      if (!context.mounted) return false;
      // Check permissions first
      bool hasPermission =
          await PermissionHandler.checkAndRequestFilePermission(context);
      if (!hasPermission) {
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
        return false;
      }

      // Ensure directory exists
      if (!downloadsDirectory.existsSync()) {
        downloadsDirectory.createSync(recursive: true);
      }

      // Get file extension from the original file
      final originalFile = File(voiceNote.audioFilePath);
      if (!await originalFile.exists()) {
        return false;
      }

      final fileExtension = originalFile.path.split('.').last;
      final safeFileName = _safeFileName(voiceNote.voiceNoteTitle);
      final fileName = '$safeFileName.$fileExtension';
      final exportPath = '${downloadsDirectory.path}/$fileName';

      onStatus?.call('Preparing export...');
      onProgress?.call(0.1);

      // Show initial notification
      await _showExportNotification(0.0, 'Preparing voice note export...');

      onStatus?.call('Copying voice note...');
      onProgress?.call(0.3);

      // Copy the file to downloads directory
      await originalFile.copy(exportPath);

      onProgress?.call(0.8);
      onStatus?.call('Finalizing export...');

      // Verify the file was copied successfully
      final exportedFile = File(exportPath);
      if (!await exportedFile.exists()) {
        throw Exception('Failed to copy voice note file');
      }

      onProgress?.call(1.0);
      onStatus?.call('Export completed!');

      // Cancel the progress notification
      await cancelExportNotification();

      // Show completion notification
      await _showExportCompleteNotification(fileName, exportPath);

      FlutterBugfender.log('Voice note exported successfully: $exportPath');
      return true;
    } catch (e, stackTrace) {
      FlutterBugfender.sendCrash(
          'Error exporting voice note: $e', stackTrace.toString());
      FlutterBugfender.error('Error exporting voice note: $e');

      onStatus?.call('Export failed: $e');
      await cancelExportNotification();
      return false;
    }
  }

  /// Show export progress notification
  static Future<void> _showExportNotification(
      double progress, String status) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _exportNotificationChannelId,
        _exportNotificationChannelName,
        channelDescription: 'Shows voice note export progress',
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

      await _notificationsPlugin.show(
        _exportNotificationId,
        'Exporting Voice Note',
        status,
        notificationDetails,
      );
    } catch (e) {
      FlutterBugfender.error('Failed to show export notification: $e');
    }
  }

  /// Show export complete notification
  static Future<void> _showExportCompleteNotification(
      String fileName, String filePath) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _exportNotificationChannelId,
        _exportNotificationChannelName,
        channelDescription: 'Shows when voice note export is complete',
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
            'open_folder',
            'Open Folder',
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

      await _notificationsPlugin.show(
        _exportCompleteNotificationId,
        'Voice Note Exported!',
        'Successfully exported $fileName to Downloads',
        notificationDetails,
        payload: filePath,
      );
    } catch (e) {
      FlutterBugfender.error('Failed to show export complete notification: $e');
    }
  }

  /// Sanitize filename for safe storage
  static String _safeFileName(String title) {
    if (title.isEmpty) return 'voice_note';

    String sanitized = title.trim();

    // Replace invalid filesystem characters with underscores
    sanitized = sanitized.replaceAll(RegExp(r'[<>:"/\\|?*\n\r]'), '_');

    // Collapse multiple whitespace characters into single spaces
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Remove leading/trailing spaces after whitespace collapse
    sanitized = sanitized.trim();

    // Default to 'voice_note' if empty after sanitization
    if (sanitized.isEmpty) return 'voice_note';

    // Truncate to 64 characters
    if (sanitized.length > 64) {
      sanitized = sanitized.substring(0, 64);
    }

    return sanitized;
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.actionId == 'open_folder' && response.payload != null) {
        // Open the Downloads folder
        _openDownloadsFolder(response.payload!);
      } else if (response.payload != null) {
        // Regular notification tap - could open the file or folder here
        FlutterBugfender.log('Export notification tapped: ${response.payload}');
        _openDownloadsFolder(response.payload!);
      }
    } catch (e, stackTrace) {
      FlutterBugfender.sendCrash(
          'Error handling notification tap: $e', stackTrace.toString());
    }
  }

  /// Open Downloads folder
  static Future<void> _openDownloadsFolder(String filePath) async {
    try {
      // Extract the directory path from the file path
      final directory =
          Directory(filePath.substring(0, filePath.lastIndexOf('/')));

      if (Platform.isAndroid) {
        // For Android, try to open the Downloads folder using file:// URI
        final downloadsUri = Uri.file(directory.path);
        FlutterBugfender.log('Opening Downloads folder: ${directory.path}');

        if (await canLaunchUrl(downloadsUri)) {
          await launchUrl(downloadsUri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback: try to open the specific file
          final fileUri = Uri.file(filePath);
          if (await canLaunchUrl(fileUri)) {
            await launchUrl(fileUri, mode: LaunchMode.externalApplication);
          } else {
            FlutterBugfender.log('Could not open Downloads folder or file');
          }
        }
      } else if (Platform.isIOS) {
        // For iOS, open the Documents directory
        final documentsUri = Uri.file(directory.path);
        FlutterBugfender.log('Opening Documents folder: ${directory.path}');

        if (await canLaunchUrl(documentsUri)) {
          await launchUrl(documentsUri, mode: LaunchMode.externalApplication);
        } else {
          FlutterBugfender.log('Could not open Documents folder');
        }
      }
    } catch (e, stackTrace) {
      FlutterBugfender.sendCrash(
          'Error opening Downloads folder: $e', stackTrace.toString());
    }
  }

  /// Cancel export notification
  static Future<void> cancelExportNotification() async {
    try {
      await _notificationsPlugin.cancel(_exportNotificationId);
    } catch (e) {
      FlutterBugfender.error('Failed to cancel export notification: $e');
    }
  }
}
