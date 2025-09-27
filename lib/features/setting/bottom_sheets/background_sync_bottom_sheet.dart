import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:msbridge/core/services/background/workmanager_dispatcher.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/bottom_sheet_base.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_action_tile.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_toggle_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundSyncBottomSheet extends StatefulWidget {
  const BackgroundSyncBottomSheet({super.key});

  @override
  State<BackgroundSyncBottomSheet> createState() =>
      _BackgroundSyncBottomSheetState();
}

class _BackgroundSyncBottomSheetState extends State<BackgroundSyncBottomSheet> {
  bool _killSwitch = false;
  Duration _frequency = const Duration(hours: 6);
  String? _lastStatus;
  String? _lastMessage;
  DateTime? _lastEndedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _killSwitch = prefs.getBool('sync_kill_switch') ?? false;
      _lastStatus = prefs.getString('bg_sync_last_status');
      _lastMessage = prefs.getString('bg_sync_last_message');
      final ts = prefs.getInt('bg_sync_last_ended_at');
      _lastEndedAt =
          ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
    });
  }

  Future<void> _setKillSwitch(bool on) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sync_kill_switch', on);
    setState(() => _killSwitch = on);
  }

  Future<void> _applyFrequency(Duration d) async {
    setState(() => _frequency = d);
    await WorkSchedulerUI.reschedule(frequency: d);
  }

  Future<void> _triggerOneOff(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bg_sync_last_status');
    await prefs.remove('bg_sync_last_message');
    await prefs.remove('bg_sync_last_ended_at');
    setState(() {
      _lastStatus = null;
      _lastMessage = null;
      _lastEndedAt = null;
    });

    await WorkSchedulerUI.triggerOnce();
    // Poll for result for up to 10 seconds
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _load();
      if (_lastStatus != null) break;
    }
    final success = _lastStatus == 'success';
    final skipped = _lastStatus == 'skipped';
    final msg = _lastMessage ??
        (skipped
            ? 'Background sync skipped'
            : (success
                ? 'Background sync completed'
                : 'Background sync failed'));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor:
              skipped ? Colors.orange : (success ? Colors.green : Colors.red),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return BottomSheetBase(
      title: 'Background Sync',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingToggleTile(
            title: 'Emergency kill switch',
            subtitle: 'Pause all background sync without uninstalling the app',
            icon: Icons.warning_amber_rounded,
            value: _killSwitch,
            onChanged: (v) async => await _setKillSwitch(v),
          ),
          const SizedBox(height: 12),
          Text('Sync cadence',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              _freqChip(context, '6h', const Duration(hours: 6)),
              _freqChip(context, '12h', const Duration(hours: 12)),
              _freqChip(context, '24h', const Duration(hours: 24)),
            ],
          ),
          const SizedBox(height: 12),
          if (_lastStatus != null) ...[
            Text(
              'Last run: ${_lastEndedAt != null ? _lastEndedAt!.toLocal().toString() : 'unknown'}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 4),
            Text(
              'Status: $_lastStatus',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _lastStatus == 'success'
                    ? Colors.green
                    : (_lastStatus == 'error'
                        ? Colors.red
                        : cs.primary.withValues(alpha: 0.7)),
              ),
            ),
            if (_lastMessage != null) ...[
              const SizedBox(height: 2),
              Text(_lastMessage!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.primary.withValues(alpha: 0.7))),
            ],
            const SizedBox(height: 12),
          ],
          SettingActionTile(
            title: 'Reschedule now',
            subtitle: 'Apply changes immediately',
            icon: Icons.schedule,
            onTap: () async =>
                await WorkSchedulerUI.reschedule(frequency: _frequency),
          ),
          const SizedBox(height: 12),
          SettingActionTile(
            title: 'Run background sync now',
            subtitle: 'Trigger one background cycle (best-effort)',
            icon: Icons.sync,
            onTap: () async => await _triggerOneOff(context),
          ),
        ],
      ),
    );
  }

  Widget _freqChip(BuildContext context, String label, Duration d) {
    final selected = _frequency == d;
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _applyFrequency(d),
      selectedColor: cs.secondary.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: cs.primary),
      side: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
    );
  }
}

class WorkSchedulerUI {
  static Future<void> reschedule({required Duration frequency}) async {
    await Workmanager().cancelByUniqueName('msbridge.periodic.all.id');
    await Workmanager().registerPeriodicTask(
      'msbridge.periodic.all.id',
      BgTasks.taskPeriodicAll,
      frequency: frequency,
      initialDelay: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 10),
    );
  }

  static Future<void> triggerOnce() async {
    await Workmanager().registerOneOffTask(
      'msbridge.oneoff.sync.id',
      BgTasks.taskPeriodicAll,
      initialDelay: const Duration(seconds: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }
}
