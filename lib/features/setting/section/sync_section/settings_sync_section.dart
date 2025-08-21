import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/user_settings_provider.dart';
import 'package:msbridge/widgets/buildModernSettingsTile.dart';
import 'package:msbridge/widgets/buildSubsectionHeader.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:msbridge/core/services/sync/settings_sync_service.dart';

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
      CustomSnackBar.show(
        context,
        "Error syncing settings: $e",
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isSyncing = false;
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choose Sync Direction"),
        content: const Text(
          "Select how you want to sync your settings:",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _syncToFirebase();
            },
            child: const Text("Upload to Cloud"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _syncFromFirebase();
            },
            child: const Text("Download from Cloud"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _manualSync();
            },
            child: const Text("Bidirectional"),
          ),
        ],
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
      final userSettings =
          Provider.of<UserSettingsProvider>(context, listen: false);
      await userSettings.exportSettings();

      // For now, just show a success message
      // In a real app, you'd save this to a file or share it
      CustomSnackBar.show(
        context,
        "Settings exported successfully!",
        isSuccess: true,
      );
    } catch (e) {
      CustomSnackBar.show(
        context,
        "Failed to export settings: $e",
        isSuccess: false,
      );
    }
  }

  Future<void> _importSettings() async {
    try {
      // For now, just show a message
      // In a real app, you'd show a file picker
      CustomSnackBar.show(
        context,
        "Import functionality coming soon!",
        isSuccess: false,
      );
    } catch (e) {
      CustomSnackBar.show(
        context,
        "Failed to import settings: $e",
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
