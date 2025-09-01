import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/user_settings_provider.dart';
import 'package:msbridge/widgets/build_modern_settings_tile.dart';
import 'package:msbridge/widgets/build_subsection_header.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:msbridge/core/services/sync/settings_sync_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:msbridge/core/permissions/permission.dart';

class SettingsSyncSection extends StatefulWidget {
  const SettingsSyncSection({super.key});

  @override
  State<SettingsSyncSection> createState() => _SettingsSyncSectionState();
}

class _SettingsSyncSectionState extends State<SettingsSyncSection> {
  final SettingsSyncService _syncService = SettingsSyncService();
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserSettingsProvider>(
      builder: (context, userSettings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSubsectionHeader(context, "Settings Sync", LineIcons.cloud),
            const SizedBox(height: 12),

            // Sync Status
            _buildSyncStatusTile(userSettings),
            const SizedBox(height: 8),

            // Manual Sync
            buildModernSettingsTile(
              context,
              title: "Manual Sync",
              subtitle: "Sync settings to/from Firebase now",
              icon: LineIcons.cloud,
              trailing: _isSyncing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : Icon(
                      LineIcons.cloud,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
              onTap: _isSyncing ? null : _manualSync,
            ),

            const SizedBox(height: 8),

            // Force Sync
            buildModernSettingsTile(
              context,
              title: "Force Sync",
              subtitle: "Resolve conflicts and force sync all settings",
              icon: LineIcons.exclamationTriangle,
              onTap: _isSyncing ? null : _forceSync,
            ),

            const SizedBox(height: 8),

            // Sync Direction
            buildModernSettingsTile(
              context,
              title: "Sync Direction",
              subtitle: "Choose sync direction",
              icon: LineIcons.cog,
              onTap: _showSyncDirectionDialog,
            ),

            const SizedBox(height: 8),

            // Export/Import
            buildModernSettingsTile(
              context,
              title: "Export Settings",
              subtitle: "Download settings backup",
              icon: LineIcons.download,
              onTap: _exportSettings,
            ),

            const SizedBox(height: 8),

            buildModernSettingsTile(
              context,
              title: "Import Settings",
              subtitle: "Restore settings from backup",
              icon: LineIcons.upload,
              onTap: _importSettings,
            ),

            const SizedBox(height: 8),

            // Reset to Default
            buildModernSettingsTile(
              context,
              title: "Reset to Default",
              subtitle: "Reset all settings to default values",
              icon: LineIcons.undo,
              onTap: _showResetDialog,
            ),

            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildSyncStatusTile(UserSettingsProvider userSettings) {
    final isInSync = userSettings.isInSync;
    final lastSyncedAt = userSettings.lastSyncedAt;
    final lastUpdated = userSettings.lastUpdated;

    String statusText;
    IconData statusIcon;
    Color statusColor;

    if (userSettings.isLoading) {
      statusText = "Loading...";
      statusIcon = LineIcons.spinner;
      statusColor = Theme.of(context).colorScheme.primary;
    } else if (isInSync) {
      statusText = "In Sync";
      statusIcon = LineIcons.checkCircle;
      statusColor = Colors.green;
    } else {
      statusText = "Out of Sync";
      statusIcon = LineIcons.exclamationCircle;
      statusColor = Colors.orange;
    }

    String subtitle = "Last updated: ${_formatDateTime(lastUpdated)}";
    if (lastSyncedAt != null) {
      subtitle += "\nLast synced: ${_formatDateTime(lastSyncedAt)}";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sync Status",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return "Never";
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return "${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago";
    } else {
      return "Just now";
    }
  }

  Future<void> _manualSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final success = await _syncService.syncSettingsBidirectional();

      if (success) {
        CustomSnackBar.show(
          context,
          "Settings synced successfully!",
          isSuccess: true,
        );
      } else {
        CustomSnackBar.show(
          context,
          "Failed to sync settings",
          isSuccess: false,
        );
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error syncing settings: $e', StackTrace.current.toString());
      FlutterBugfender.error('Error syncing settings: $e');
      CustomSnackBar.show(
        context,
        "Error syncing settings: $e",
        isSuccess: false,
      );
    } finally {
      setState(() {
        if (!mounted) {
          _isSyncing = false;
        }
      });
    }
  }

  Future<void> _forceSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final success = await _syncService.forceSyncAllSettings();

      if (success) {
        CustomSnackBar.show(
          context,
          "Settings force synced successfully!",
          isSuccess: true,
        );
      } else {
        CustomSnackBar.show(
          context,
          "Failed to force sync settings",
          isSuccess: false,
        );
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error force syncing settings: $e', StackTrace.current.toString());
      FlutterBugfender.error('Error force syncing settings: $e');
      CustomSnackBar.show(
        context,
        "Error force syncing settings: $e",
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _showSyncDirectionDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          title: Row(
            children: [
              Icon(Icons.sync_alt, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Choose sync direction',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSyncOption(
                ctx,
                icon: LineIcons.arrowUp,
                title: 'Upload to Cloud',
                subtitle: 'Push local settings to Firebase',
                color: colorScheme.primary,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _syncToFirebase();
                },
              ),
              const SizedBox(height: 10),
              _buildSyncOption(
                ctx,
                icon: LineIcons.arrowDown,
                title: 'Download from Cloud',
                subtitle: 'Replace local settings with cloud copy',
                color: colorScheme.secondary,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _syncFromFirebase();
                },
              ),
              const SizedBox(height: 10),
              _buildSyncOption(
                ctx,
                icon: LineIcons.syncIcon,
                title: 'Bidirectional',
                subtitle: 'Smart merge based on last updated time',
                color: colorScheme.primary,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _manualSync();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSyncOption(
    BuildContext ctx, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(ctx);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }

  Future<void> _syncToFirebase() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final success = await _syncService.syncSettingsToFirebase();

      if (success) {
        CustomSnackBar.show(
          context,
          "Settings uploaded to cloud successfully!",
          isSuccess: true,
        );
      } else {
        CustomSnackBar.show(
          context,
          "Failed to upload settings to cloud",
          isSuccess: false,
        );
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error uploading settings: $e', StackTrace.current.toString());
      FlutterBugfender.error('Error uploading settings: $e');
      CustomSnackBar.show(
        context,
        "Error uploading settings: $e",
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _syncFromFirebase() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final success = await _syncService.syncSettingsFromFirebase();

      if (success) {
        CustomSnackBar.show(
          context,
          "Settings downloaded from cloud successfully!",
          isSuccess: true,
        );
      } else {
        CustomSnackBar.show(
          context,
          "Failed to download settings from cloud",
          isSuccess: false,
        );
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error downloading settings: $e', StackTrace.current.toString());
      FlutterBugfender.error('Error downloading settings: $e');
      CustomSnackBar.show(
        context,
        "Error downloading settings: $e",
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _exportSettings() async {
    try {
      // Request storage permission (Android)
      bool hasPermission = true;
      try {
        hasPermission =
            await PermissionHandler.checkAndRequestFilePermission(context);
      } catch (e) {
        FlutterBugfender.sendCrash(
            'Storage permission denied.', StackTrace.current.toString());
        FlutterBugfender.error('Storage permission denied.');
      }
      if (!hasPermission) {
        FlutterBugfender.sendCrash(
            'Storage permission denied.', StackTrace.current.toString());
        FlutterBugfender.error('Storage permission denied.');

        throw Exception('Storage permission denied.');
      }

      final userSettings =
          Provider.of<UserSettingsProvider>(context, listen: false);
      final backup = await userSettings.exportSettings();

      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);
      final bytes = utf8.encode(jsonString);

      final timestamp = DateTime.now();
      final formatted =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}';
      final fileName = 'msbridge-settings-backup-$formatted.json';

      Directory? downloadsDirectory;
      if (Platform.isAndroid) {
        downloadsDirectory = Directory('/storage/emulated/0/Download');
        if (!await downloadsDirectory.exists()) {
          await downloadsDirectory.create(recursive: true);
        }
      } else if (Platform.isIOS) {
        downloadsDirectory = await getApplicationDocumentsDirectory();
        downloadsDirectory = Directory('${downloadsDirectory.path}/Downloads');
        if (!await downloadsDirectory.exists()) {
          await downloadsDirectory.create(recursive: true);
        }
      } else {
        downloadsDirectory = await getApplicationDocumentsDirectory();
      }

      final file = File('${downloadsDirectory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      CustomSnackBar.show(
        context,
        'Settings exported to ${file.path}',
        isSuccess: true,
      );
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Export failed: $e', StackTrace.current.toString());
      FlutterBugfender.error('Export failed: $e');
      if (!mounted) return;
      CustomSnackBar.show(
        context,
        'Export failed: $e',
        isSuccess: false,
      );
    }
  }

  Future<void> _importSettings() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) {
        return; // user cancelled
      }
      final path = result.files.single.path!;
      final content = await File(path).readAsString();
      final Map<String, dynamic> backup = json.decode(content);

      final userSettings =
          Provider.of<UserSettingsProvider>(context, listen: false);
      final success = await userSettings.importSettings(backup);

      CustomSnackBar.show(
        context,
        success ? 'Settings imported successfully!' : 'Import failed',
        isSuccess: success,
      );
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Import failed: $e', StackTrace.current.toString());
      FlutterBugfender.error('Import failed: $e');
      CustomSnackBar.show(
        context,
        'Import failed: $e',
        isSuccess: false,
      );
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Settings"),
        content: const Text(
          "Are you sure you want to reset all settings to default values? "
          "This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetSettings();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSettings() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final userSettings =
          Provider.of<UserSettingsProvider>(context, listen: false);
      final success = await userSettings.resetToDefault();

      if (success) {
        CustomSnackBar.show(
          context,
          "Settings reset to default successfully!",
          isSuccess: true,
        );
      } else {
        CustomSnackBar.show(
          context,
          "Failed to reset settings",
          isSuccess: false,
        );
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Reset failed: $e', StackTrace.current.toString());
      FlutterBugfender.error('Reset failed: $e');
      CustomSnackBar.show(
        context,
        "Error resetting settings: $e",
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }
}
