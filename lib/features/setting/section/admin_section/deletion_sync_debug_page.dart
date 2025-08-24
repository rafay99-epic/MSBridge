import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:msbridge/core/services/background/workmanager_dispatcher.dart';

class DeletionSyncDebugPage extends StatefulWidget {
  const DeletionSyncDebugPage({super.key});

  @override
  State<DeletionSyncDebugPage> createState() => _DeletionSyncDebugPageState();
}

class _DeletionSyncDebugPageState extends State<DeletionSyncDebugPage> {
  String _lastStatus = '-';
  String _lastMessage = '-';
  String _lastEndedAt = '-';
  String _userId = '-';
  bool _killSwitch = false;
  bool _cloudSyncEnabled = true;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final endedAtMs = prefs.getInt('bg_sync_last_ended_at');
    final endedAt = endedAtMs != null
        ? DateTime.fromMillisecondsSinceEpoch(endedAtMs)
        : null;

    setState(() {
      _lastStatus = prefs.getString('bg_sync_last_status') ?? '-';
      _lastMessage = prefs.getString('bg_sync_last_message') ?? '-';
      _lastEndedAt = endedAt?.toLocal().toString() ?? '-';
      _killSwitch = prefs.getBool('sync_kill_switch') ?? false;
      _cloudSyncEnabled = prefs.getBool('cloud_sync_enabled') ?? true;
      _userId = FirebaseAuth.instance.currentUser?.uid ?? '-';
    });
  }

  Future<void> _toggleKillSwitch(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sync_kill_switch', value);
    setState(() {
      _killSwitch = value;
    });
  }

  Future<void> _toggleCloudSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cloud_sync_enabled', value);
    setState(() {
      _cloudSyncEnabled = value;
    });
  }

  Future<void> _runSyncNow() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
    });
    try {
      final unique = 'msbridge.manual.${DateTime.now().millisecondsSinceEpoch}';
      await Workmanager().registerOneOffTask(unique, BgTasks.taskPeriodicAll);
      // Give worker a moment, then refresh
      await Future.delayed(const Duration(seconds: 3));
      await _pollForCompletion();
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  Future<void> _pollForCompletion() async {
    // Poll SharedPreferences a few times to capture worker results
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 1));
      await _loadData();
    }
  }

  Future<void> _resetStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bg_sync_last_status');
    await prefs.remove('bg_sync_last_message');
    await prefs.remove('bg_sync_last_ended_at');
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deletion Sync Debug'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoTile(label: 'User ID', value: _userId),
            const SizedBox(height: 12),
            _InfoTile(label: 'Last Status', value: _lastStatus),
            const SizedBox(height: 8),
            _InfoTile(label: 'Last Message', value: _lastMessage),
            const SizedBox(height: 8),
            _InfoTile(label: 'Last Ended At', value: _lastEndedAt),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Kill Switch'),
              subtitle: const Text('Skip background sync when enabled'),
              value: _killSwitch,
              onChanged: _toggleKillSwitch,
            ),
            SwitchListTile(
              title: const Text('Cloud Sync Enabled'),
              subtitle: const Text('Allow background sync to run'),
              value: _cloudSyncEnabled,
              onChanged: _toggleCloudSync,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _runSyncNow,
              icon: const Icon(Icons.play_arrow),
              label: Text(_isRunning ? 'Running…' : 'Run Sync Now'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _resetStatus,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Last Status'),
            ),
            const SizedBox(height: 24),
            Text(
              'This triggers your existing Workmanager task ("${BgTasks.taskPeriodicAll}") which includes notes/templates/settings/streak sync and the deletion sync layer integrated in the dispatcher.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: colorScheme.outline.withOpacity(0.1), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
