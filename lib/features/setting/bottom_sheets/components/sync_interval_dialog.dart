// features/setting/components/sync_interval_dialog.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:msbridge/core/services/sync/auto_sync_scheduler.dart';

class SyncIntervalDialog extends StatefulWidget {
  const SyncIntervalDialog({super.key});

  @override
  State<SyncIntervalDialog> createState() => _SyncIntervalDialogState();

  static Future<int?> show(BuildContext context) async {
    return showDialog<int>(
      context: context,
      builder: (context) => const SyncIntervalDialog(),
    );
  }
}

class _SyncIntervalDialogState extends State<SyncIntervalDialog> {
  int _selectedInterval = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentInterval();
  }

  Future<void> _loadCurrentInterval() async {
    try {
      final interval = await AutoSyncScheduler.getIntervalMinutes();
      if (!mounted) return;
      setState(() {
        _selectedInterval = interval;
        _isLoading = false;
      });
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to load current interval');
      if (!mounted) return;
      setState(() {
        _selectedInterval = 0; // Off
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return AlertDialog(
        backgroundColor: colorScheme.surface,
        content: const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: const Text('Auto sync interval'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntervalOption('Off', 0),
          const SizedBox(height: 8),
          _buildIntervalOption('Every 15 minutes', 15),
          const SizedBox(height: 8),
          _buildIntervalOption('Every 30 minutes', 30),
          const SizedBox(height: 8),
          _buildIntervalOption('Every 60 minutes', 60),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedInterval),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildIntervalOption(String label, int value) {
    return InkWell(
      onTap: () => setState(() => _selectedInterval = value),
      child: Row(
        children: [
          Radio<int>(
            value: value,
            groupValue: _selectedInterval,
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedInterval = v);
              }
            },
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
