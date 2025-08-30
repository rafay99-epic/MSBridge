import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/widgets/build_modern_settings_tile.dart';
import 'package:msbridge/widgets/build_section_header.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/core/utils/version_download_utils.dart';
import 'package:msbridge/core/repo/note_version_repo.dart';

class VersionHistorySettings extends StatefulWidget {
  const VersionHistorySettings({super.key});

  @override
  State<VersionHistorySettings> createState() => _VersionHistorySettingsState();
}

class _VersionHistorySettingsState extends State<VersionHistorySettings> {
  bool _isLoading = false;
  int _maxVersionsToKeep = 3;
  bool _autoCleanupEnabled = true;
  bool _versionHistoryEnabled = true;
  Map<String, dynamic> _storageInfo = {};
  int _totalVersions = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStorageInfo();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxVersionsToKeep = prefs.getInt('max_versions_to_keep') ?? 3;
      _autoCleanupEnabled = prefs.getBool('auto_cleanup_enabled') ?? true;
      _versionHistoryEnabled = prefs.getBool('version_history_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('max_versions_to_keep', _maxVersionsToKeep);
    await prefs.setBool('auto_cleanup_enabled', _autoCleanupEnabled);
    await prefs.setBool('version_history_enabled', _versionHistoryEnabled);
  }

  Future<void> _loadStorageInfo() async {
    try {
      final storageInfo = await NoteVersionRepo.getStorageInfo();
      final totalVersions = await NoteVersionRepo.getTotalVersionCount();

      setState(() {
        _storageInfo = storageInfo;
        _totalVersions = totalVersions;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<String> _getDownloadLocation() async {
    try {
      final downloadPath = await VersionDownloadUtils.getDownloadDirectory();
      return VersionDownloadUtils.getUserFriendlyPath(downloadPath);
    } catch (e) {
      return 'Unknown location';
    }
  }

  Future<void> _cleanupOldVersions() async {
    // Show confirmation dialog
    final shouldProceed = await _showCleanupConfirmation();
    if (!shouldProceed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          await NoteVersionRepo.cleanupOldVersions(_maxVersionsToKeep);

      if (result['success'] == true && mounted) {
        // Reload storage info
        await _loadStorageInfo();

        // Show success message
        CustomSnackBar.show(
          context,
          "Version cleanup completed successfully!",
          isSuccess: true,
        );
      } else if (mounted) {
        CustomSnackBar.show(
          context,
          "Error during cleanup: ${result['message'] ?? 'Unknown error'}",
          isSuccess: false,
        );
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      if (mounted) {
        CustomSnackBar.show(
          context,
          "Error during cleanup: $e",
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showCleanupConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Cleanup"),
            content: Text(
              "This will remove old versions beyond the limit of $_maxVersionsToKeep versions per note. "
              "This action cannot be undone.\n\n"
              "Current total versions: $_totalVersions",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Clean Up"),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMaxVersionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Maximum Versions to Keep"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Choose how many versions of each note to keep. "
              "Older versions will be automatically removed.\n\n"
              "Current setting: $_maxVersionsToKeep versions per note",
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  Text("Keep last $_maxVersionsToKeep versions"),
                  Slider(
                    value: _maxVersionsToKeep.toDouble(),
                    min: 3,
                    max: 50,
                    divisions: 47,
                    label: _maxVersionsToKeep.toString(),
                    onChanged: (value) {
                      setState(() {
                        _maxVersionsToKeep = value.round();
                      });
                    },
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("3"),
                      Text("50"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveSettings();
              if (mounted) {
                CustomSnackBar.show(
                  context,
                  "Maximum versions setting updated to $_maxVersionsToKeep",
                  isSuccess: true,
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Version History Settings"),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        elevation: 0,
      ),
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionHeader(
              context,
              "Version Management",
              LineIcons.history,
            ),
            const SizedBox(height: 16),

            // Enable/Disable Version History
            buildModernSettingsTile(
              context,
              title: "Enable Version History",
              subtitle: _versionHistoryEnabled
                  ? "Versioning is ON"
                  : "Versioning is OFF",
              icon: LineIcons.toggleOn,
              trailing: Switch(
                value: _versionHistoryEnabled,
                onChanged: (value) async {
                  setState(() => _versionHistoryEnabled = value);
                  await _saveSettings();
                  if (mounted) {
                    CustomSnackBar.show(
                      context,
                      value
                          ? 'Version History enabled'
                          : 'Version History disabled',
                      isSuccess: true,
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 8),

            // Max versions to keep
            buildModernSettingsTile(
              context,
              title: "Maximum Versions to Keep",
              subtitle:
                  "Keep the last $_maxVersionsToKeep versions of each note",
              icon: LineIcons.save,
              onTap: () => _showMaxVersionsDialog(),
            ),

            const SizedBox(height: 8),

            // Auto cleanup toggle
            buildModernSettingsTile(
              context,
              title: "Automatic Cleanup",
              subtitle: _autoCleanupEnabled
                  ? "Automatically remove old versions"
                  : "Manual cleanup only",
              icon: _autoCleanupEnabled
                  ? LineIcons.checkCircle
                  : LineIcons.timesCircle,
              trailing: Switch(
                value: _autoCleanupEnabled,
                onChanged: (value) async {
                  setState(() => _autoCleanupEnabled = value);
                  await _saveSettings();
                  if (mounted) {
                    CustomSnackBar.show(
                      context,
                      value
                          ? 'Automatic cleanup enabled'
                          : 'Automatic cleanup disabled',
                      isSuccess: true,
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // Storage Information
            buildSectionHeader(
                context, "Storage Information", LineIcons.database),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LineIcons.database,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Current Usage",
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStorageInfoRow("Total Versions", "$_totalVersions"),
                  if (_storageInfo.isNotEmpty) ...[
                    _buildStorageInfoRow(
                        "Unique Notes", "${_storageInfo['uniqueNotes'] ?? 0}"),
                    _buildStorageInfoRow("Average per Note",
                        "${(_storageInfo['averageVersionsPerNote'] ?? 0).toStringAsFixed(1)}"),
                    _buildStorageInfoRow("Content Size",
                        "${(_storageInfo['totalContentSize'] ?? 0) ~/ 1024} KB"),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Information
            buildSectionHeader(context, "Information", LineIcons.infoCircle),
            const SizedBox(height: 16),

            // Download Location
            buildModernSettingsTile(
              context,
              title: "Download Location",
              subtitle: "Where version files are saved",
              icon: LineIcons.folder,
              onTap: null,
              trailing: FutureBuilder<String>(
                future: _getDownloadLocation(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      snapshot.data ?? 'Unknown',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LineIcons.lightbulb,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "How Version History Works",
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "• A new version is created every time you edit a note\n"
                    "• Old versions are automatically cleaned up based on your settings\n"
                    "• You can view and compare different versions of your notes\n"
                    "• Version history helps you track changes and recover content\n"
                    "• Current limit: $_maxVersionsToKeep versions per note",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            buildSectionHeader(context, "Actions", LineIcons.tools),
            const SizedBox(height: 16),
            buildModernSettingsTile(
              context,
              title: "Clean Up Old Versions",
              subtitle: "Remove versions beyond the limit for all notes",
              icon: LineIcons.broom,
              onTap: _isLoading ? null : _cleanupOldVersions,
              trailing: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(LineIcons.arrowRight, color: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
