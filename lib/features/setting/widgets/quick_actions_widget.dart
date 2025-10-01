// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:msbridge/features/notes_taking/recyclebin/recycle.dart';
import 'package:msbridge/widgets/snakbar.dart';

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
      child: _buildDynamicGrid(),
    );
  }

  Widget _buildDynamicGrid() {
    // Define all quick actions in a list for easy management
    final List<QuickActionItem> actions = [
      QuickActionItem(
        title: "Logout",
        icon: LineIcons.alternateSignOut,
        color: Colors.red,
        onTap: widget.onLogout,
        isDisabled: false,
      ),
      QuickActionItem(
        title: "Sync Now",
        icon: LineIcons.syncIcon,
        color: _cloudSyncEnabled ? widget.colorScheme.secondary : Colors.grey,
        onTap: _cloudSyncEnabled ? _handleSync : _showEnableCloudSyncMessage,
        isDisabled: false,
        isLoading: _isSyncing,
        loadingText: "Syncing...",
      ),
      QuickActionItem(
        title: "Pull Cloud",
        icon: LineIcons.cloud,
        color: _cloudSyncEnabled ? widget.colorScheme.tertiary : Colors.grey,
        onTap: _cloudSyncEnabled
            ? _handlePullFromCloud
            : _showEnableCloudSyncMessage,
        isDisabled: false,
        isLoading: _isPulling,
        loadingText: "Pulling...",
      ),
      QuickActionItem(
        title: "Backup",
        icon: LineIcons.download,
        color: widget.colorScheme.primary,
        onTap: widget.onBackup,
        isDisabled: false,
      ),
      QuickActionItem(
        title: "Recycle Bin",
        icon: LineIcons.trash,
        color: Colors.orange,
        onTap: _navigateToRecycleBin,
        isDisabled: false,
      ),
      // Add more actions here easily - they'll automatically flow to new rows
    ];

    return Column(
      children: _buildRows(actions),
    );
  }

  List<Widget> _buildRows(List<QuickActionItem> actions) {
    final List<Widget> rows = [];
    const int itemsPerRow = 4;

    for (int i = 0; i < actions.length; i += itemsPerRow) {
      final endIndex =
          (i + itemsPerRow < actions.length) ? i + itemsPerRow : actions.length;
      final rowActions = actions.sublist(i, endIndex);

      rows.add(
        Row(
          children: _buildRowItems(rowActions, itemsPerRow),
        ),
      );

      // Add spacing between rows (except after the last row)
      if (endIndex < actions.length) {
        rows.add(const SizedBox(height: 12));
      }
    }

    return rows;
  }

  List<Widget> _buildRowItems(
      List<QuickActionItem> rowActions, int maxItemsPerRow) {
    final List<Widget> items = [];

    for (int i = 0; i < maxItemsPerRow; i++) {
      if (i < rowActions.length) {
        // Add the action
        items.add(
          Expanded(
            child: rowActions[i].isLoading
                ? _buildLoadingTile(rowActions[i])
                : QuickActionTile(
                    title: rowActions[i].title,
                    icon: rowActions[i].icon,
                    color: rowActions[i].color,
                    onTap: rowActions[i].onTap,
                    disabled: rowActions[i].isDisabled,
                  ),
          ),
        );
      } else {
        // Add empty space to maintain grid alignment
        items.add(const Expanded(child: SizedBox()));
      }

      // Add spacing between items (except after the last item)
      if (i < maxItemsPerRow - 1) {
        items.add(const SizedBox(width: 12));
      }
    }

    return items;
  }

  Widget _buildLoadingTile(QuickActionItem action) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: action.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: action.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(action.color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            action.loadingText ?? 'Loading...',
            style: widget.theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: action.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToRecycleBin() {
    Navigator.of(context).push(
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: const DeletedNotes(),
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
      FlutterBugfender.sendCrash(
          'Failed to sync: $e', StackTrace.current.toString());
      FlutterBugfender.error('Failed to sync: $e');
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
      FlutterBugfender.sendCrash(
          'Failed to pull from cloud: $e', StackTrace.current.toString());
      FlutterBugfender.error('Failed to pull from cloud: $e');
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

class QuickActionItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDisabled;
  final bool isLoading;
  final String? loadingText;

  const QuickActionItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isDisabled = false,
    this.isLoading = false,
    this.loadingText,
  });
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
            color: color.withValues(alpha: disabled ? 0.05 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: disabled ? 0.1 : 0.2),
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
