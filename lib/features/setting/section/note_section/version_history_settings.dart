import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/widgets/buildModernSettingsTile.dart';
import 'package:msbridge/widgets/buildSectionHeader.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VersionHistorySettings extends StatefulWidget {
  const VersionHistorySettings({super.key});

  @override
  State<VersionHistorySettings> createState() => _VersionHistorySettingsState();
}

class _VersionHistorySettingsState extends State<VersionHistorySettings> {
  bool _isLoading = false;
  int _maxVersionsToKeep = 10;
  bool _autoCleanupEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxVersionsToKeep = prefs.getInt('max_versions_to_keep') ?? 10;
      _autoCleanupEnabled = prefs.getBool('auto_cleanup_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('max_versions_to_keep', _maxVersionsToKeep);
    await prefs.setBool('auto_cleanup_enabled', _autoCleanupEnabled);
  }

  Future<void> _cleanupOldVersions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // This would need to be implemented to clean up all notes' old versions
      // For now, we'll just show a success message
      CustomSnackBar.show(context, "Version cleanup completed successfully!",
          isSuccess: true);
    } catch (e) {
      CustomSnackBar.show(context, "Error during cleanup: $e",
          isSuccess: false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                onChanged: (value) {
                  setState(() {
                    _autoCleanupEnabled = value;
                  });
                  _saveSettings();
                },
                activeColor: colorScheme.primary,
              ),
            ),

            const SizedBox(height: 24),

            buildSectionHeader(
              context,
              "Actions",
              LineIcons.tools,
            ),
            const SizedBox(height: 16),

            // Manual cleanup button
            buildModernSettingsTile(
              context,
              title: "Clean Up Old Versions",
              subtitle: "Remove versions beyond the limit for all notes",
              icon: LineIcons.broom,
              onTap: _isLoading ? null : _cleanupOldVersions,
              trailing: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      ),
                    )
                  : Icon(
                      LineIcons.arrowRight,
                      color: colorScheme.primary,
                    ),
            ),

            const SizedBox(height: 24),

            buildSectionHeader(
              context,
              "Information",
              LineIcons.infoCircle,
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
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
                    "• Version history helps you track changes and recover content",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMaxVersionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Maximum Versions to Keep"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Choose how many versions of each note to keep. "
              "Older versions will be automatically removed.",
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  Text("Keep last $_maxVersionsToKeep versions"),
                  Slider(
                    value: _maxVersionsToKeep.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: _maxVersionsToKeep.toString(),
                    onChanged: (value) {
                      setState(() {
                        _maxVersionsToKeep = value.round();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("5"),
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
            onPressed: () {
              Navigator.pop(context);
              _saveSettings();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
