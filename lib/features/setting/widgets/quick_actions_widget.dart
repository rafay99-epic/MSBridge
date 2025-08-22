import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuickActionsWidget extends StatefulWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onLogout;
  final Future<void> Function() onSyncNow;
  final Future<void> Function() onPullFromCloud;
  final VoidCallback onBackup;

  const QuickActionsWidget({
    super.key,
    required this.theme,
    required this.colorScheme,
    required this.onLogout,
    required this.onSyncNow,
    required this.onPullFromCloud,
    required this.onBackup,
  });

  @override
  State<QuickActionsWidget> createState() => _QuickActionsWidgetState();
}

class _QuickActionsWidgetState extends State<QuickActionsWidget> {
  bool _isSyncing = false;
  bool _isPulling = false;
  bool _cloudSyncEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadCloudSyncStatus();
  }

  Future<void> _loadCloudSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('cloud_sync_enabled') ?? true;
    if (mounted) {
      setState(() {
        _cloudSyncEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: QuickActionTile(
              title: "Logout",
              icon: LineIcons.alternateSignOut,
              color: Colors.red,
              onTap: widget.onLogout,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _isSyncing
                ? _buildSyncingTile()
                : QuickActionTile(
                    title: "Sync Now",
                    icon: LineIcons.syncIcon,
                    color: _cloudSyncEnabled
                        ? widget.colorScheme.secondary
                        : Colors.grey,
                    onTap: _cloudSyncEnabled
                        ? _handleSync
                        : _showEnableCloudSyncMessage,
                    disabled: !_cloudSyncEnabled,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _isPulling
                ? _buildPullingTile()
                : QuickActionTile(
                    title: "Pull Cloud",
                    icon: LineIcons.cloud,
                    color: _cloudSyncEnabled
                        ? widget.colorScheme.tertiary
                        : Colors.grey,
                    onTap: _cloudSyncEnabled
                        ? _handlePullFromCloud
                        : _showEnableCloudSyncMessage,
                    disabled: !_cloudSyncEnabled,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: QuickActionTile(
              title: "Backup",
              icon: LineIcons.download,
              color: widget.colorScheme.primary,
              onTap: widget.onBackup,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncingTile() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: widget.colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.colorScheme.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Syncing...",
            style: widget.theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.colorScheme.secondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPullingTile() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: widget.colorScheme.tertiary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.colorScheme.tertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Pulling...",
            style: widget.theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.colorScheme.tertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleSync() async {
    setState(() => _isSyncing = true);

    try {
      await widget.onSyncNow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Sync completed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Sync failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _handlePullFromCloud() async {
    setState(() => _isPulling = true);

    try {
      await widget.onPullFromCloud();
      if (mounted) {
        CustomSnackBar.show(context, "Pull from cloud completed successfully!",
            isSuccess: true);
      }
    } catch (e) {
      FirebaseCrashlytics.instance
          .recordError(e, StackTrace.current, reason: "Pull from cloud failed");
      if (mounted) {
        CustomSnackBar.show(context, "Pull from cloud failed: $e",
            isSuccess: false);
      }
    } finally {
      if (mounted) {
        setState(() => _isPulling = false);
      }
    }
  }

  void _showEnableCloudSyncMessage() {
    CustomSnackBar.show(
      context,
      'Please enable Cloud sync in Cloud Sync settings first',
      isSuccess: false,
    );
  }
}

class QuickActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool disabled;

  const QuickActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(disabled ? 0.05 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(disabled ? 0.1 : 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: disabled ? Colors.grey : color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: disabled ? Colors.grey : color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
