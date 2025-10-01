// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:msbridge/core/provider/streak_provider.dart';
import 'package:msbridge/core/services/sync/streak_sync_service.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/build_section_header.dart';
import 'package:msbridge/widgets/build_settings_tile.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:msbridge/widgets/streak_display_widget.dart';

class StreakSettingsPage extends StatefulWidget {
  const StreakSettingsPage({super.key});

  @override
  State<StreakSettingsPage> createState() => _StreakSettingsPageState();
}

class _StreakSettingsPageState extends State<StreakSettingsPage> {
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final streakProvider =
          Provider.of<StreakProvider>(context, listen: false);

      // Ensure streak provider is initialized
      if (!streakProvider.isInitialized) {
        await streakProvider.initializeStreak();
      }

      _selectedTime = streakProvider.notificationTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Streak Settings", backbutton: true),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<StreakProvider>(
        builder: (context, streakProvider, child) {
          if (streakProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Streak Display
                const Center(
                  child: StreakDisplayWidget(
                    showExtendedInfo: true,
                    showAppBar: false,
                  ),
                ),
                const SizedBox(height: 24),

                // Main Feature Toggle
                buildSectionHeader(context, "Streak Feature", LineIcons.fire),
                const SizedBox(height: 16),

                _buildMainToggle(
                  context,
                  "Enable Streak Tracking",
                  "Track your daily note creation streak",
                  streakProvider.streakEnabled,
                  (value) => streakProvider.setStreakEnabled(value),
                  LineIcons.fire,
                ),

                if (streakProvider.streakEnabled) ...[
                  const SizedBox(height: 24),
                  buildSectionHeader(
                      context, "Streak Information", LineIcons.info),
                  const SizedBox(height: 16),
                  _buildStreakInfoTile(
                      context,
                      "Current Streak",
                      "${streakProvider.currentStreakCount} days",
                      LineIcons.fire),
                  _buildStreakInfoTile(
                      context,
                      "Longest Streak",
                      "${streakProvider.longestStreakCount} days",
                      LineIcons.trophy),
                  _buildStreakInfoTile(
                      context,
                      "Streak Started",
                      _formatDate(streakProvider.currentStreak.streakStartDate),
                      LineIcons.calendar),
                  _buildStreakInfoTile(
                      context,
                      "Last Activity",
                      _formatDate(
                          streakProvider.currentStreak.lastActivityDate),
                      LineIcons.clock),
                ],

                const SizedBox(height: 24),
                buildSectionHeader(
                    context, "Notification Settings", LineIcons.bell),
                const SizedBox(height: 16),

                _buildMainToggle(
                  context,
                  "Enable Notifications",
                  "Get notified about your streak",
                  streakProvider.notificationsEnabled,
                  (value) => streakProvider.setNotificationsEnabled(value),
                  LineIcons.bell,
                ),

                if (streakProvider.notificationsEnabled) ...[
                  const SizedBox(height: 24),
                  buildSectionHeader(
                      context, "Notification Types", LineIcons.list),
                  const SizedBox(height: 16),
                  _buildNotificationTypeToggle(
                      context,
                      "Daily Reminders",
                      "Get reminded to maintain your streak",
                      streakProvider.dailyReminders,
                      (value) => streakProvider.updateSetting(
                          'dailyReminders', value)),
                  _buildNotificationTypeToggle(
                      context,
                      "Urgent Alerts",
                      "Warnings when streak is about to end",
                      streakProvider.urgentReminders,
                      (value) => streakProvider.updateSetting(
                          'urgentReminders', value)),
                  _buildNotificationTypeToggle(
                      context,
                      "Milestone Celebrations",
                      "Celebrate streak achievements",
                      streakProvider.milestoneNotifications,
                      (value) => streakProvider.updateSetting(
                          'milestoneNotifications', value)),
                  const SizedBox(height: 24),
                  buildSectionHeader(
                      context, "Reminder Timing", LineIcons.clock),
                  const SizedBox(height: 16),
                  _buildTimeSelector(context, "Daily Reminder Time",
                      "Current: ${_selectedTime ?? streakProvider.notificationTime}"),
                  const SizedBox(height: 24),
                  buildSectionHeader(
                      context, "Notification Preferences", LineIcons.cog),
                  const SizedBox(height: 16),
                  _buildNotificationTypeToggle(
                      context,
                      "Sound",
                      "Play sound for notifications",
                      streakProvider.settings.soundEnabled,
                      (value) =>
                          streakProvider.updateSetting('soundEnabled', value)),
                  _buildNotificationTypeToggle(
                      context,
                      "Vibration",
                      "Vibrate for notifications",
                      streakProvider.settings.vibrationEnabled,
                      (value) => streakProvider.updateSetting(
                          'vibrationEnabled', value)),
                ],

                const SizedBox(height: 24),
                buildSectionHeader(context, "Cloud Sync", LineIcons.cloud),
                const SizedBox(height: 16),
                FutureBuilder<bool>(
                  future: () async {
                    final prefs = await SharedPreferences.getInstance();
                    return prefs
                            .getBool(StreakSyncService.streakCloudToggleKey) ??
                        true;
                  }(),
                  builder: (context, snap) {
                    final value = snap.data ?? true;
                    return _buildMainToggle(
                      context,
                      "Sync streak across devices",
                      "Keep your streak consistent on all devices",
                      value,
                      (enabled) async {
                        final prev = value; // snapshot before change
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool(
                              StreakSyncService.streakCloudToggleKey, enabled);
                          if (enabled) {
                            final ok = await StreakSyncService().syncNow();
                            if (!ok) throw Exception('Sync failed or disabled');
                            if (context.mounted) {
                              await Provider.of<StreakProvider>(context,
                                      listen: false)
                                  .refreshStreak();
                              if (context.mounted) {
                                CustomSnackBar.show(
                                  context,
                                  'Streak cloud sync enabled and synced',
                                  isSuccess: true,
                                );
                              }
                            }
                            FlutterBugfender.log(
                                'Streak sync toggle ON and synced');
                          } else {
                            if (context.mounted) {
                              CustomSnackBar.show(
                                context,
                                'Streak cloud sync disabled',
                                isSuccess: true,
                              );
                            }
                            FlutterBugfender.log('Streak sync toggle OFF');
                          }
                        } catch (e) {
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool(
                                StreakSyncService.streakCloudToggleKey, prev);
                          } catch (e) {
                            FlutterBugfender.sendCrash(
                                'Failed toggling streak cloud sync: $e',
                                StackTrace.current.toString());
                            FlutterBugfender.error(
                                'Failed toggling streak cloud sync: $e');
                          }
                          if (context.mounted) {
                            CustomSnackBar.show(
                              context,
                              'Failed to update streak sync setting: $e',
                              isSuccess: false,
                            );
                          }
                        } finally {
                          if (mounted) setState(() {});
                        }
                      },
                      LineIcons.cloud,
                    );
                  },
                ),

                const SizedBox(height: 24),
                buildSectionHeader(context, "Streak Actions", LineIcons.cog),
                const SizedBox(height: 16),

                buildSettingsTile(context,
                    title: "Refresh Streak",
                    subtitle:
                        "Reload local streak and reschedule notifications",
                    icon: LineIcons.syncIcon, onTap: () async {
                  try {
                    await streakProvider.refreshStreak();
                    if (context.mounted) {
                      CustomSnackBar.show(
                        context,
                        'Streak refreshed',
                        isSuccess: true,
                      );
                    }
                  } catch (e) {
                    FlutterBugfender.sendCrash('Refresh streak failed: $e',
                        StackTrace.current.toString());
                    FlutterBugfender.error('Refresh streak failed: $e');
                    if (context.mounted) {
                      CustomSnackBar.show(
                        context,
                        'Failed to refresh streak: $e',
                        isSuccess: false,
                      );
                    }
                  } finally {
                    if (mounted) setState(() {});
                  }
                }),
                buildSettingsTile(context,
                    title: "Sync Now",
                    subtitle: "Push/pull streak with cloud",
                    icon: LineIcons.cloud, onTap: () async {
                  try {
                    final ok = await StreakSyncService().syncNow();
                    // ensure UI reflects pulled values
                    if (context.mounted) {
                      await Provider.of<StreakProvider>(context, listen: false)
                          .refreshStreak();
                      if (context.mounted) {
                        CustomSnackBar.show(
                          context,
                          ok
                              ? 'Streak synced with cloud'
                              : 'Sync disabled or no changes',
                          isSuccess: ok,
                        );
                      }
                    }
                    FirebaseCrashlytics.instance.log('Streak syncNow success');
                  } catch (e) {
                    FlutterBugfender.sendCrash('Streak syncNow failed: $e',
                        StackTrace.current.toString());
                    FlutterBugfender.error('Streak syncNow failed: $e');
                    if (context.mounted) {
                      CustomSnackBar.show(
                        context,
                        'Failed to sync streak: $e',
                        isSuccess: false,
                      );
                    }
                  }
                }),
                buildSettingsTile(context,
                    title: "Pull from Cloud",
                    subtitle: "Fetch streak from cloud and merge",
                    icon: LineIcons.cloud, onTap: () async {
                  try {
                    await StreakSyncService().pullCloudToLocal();
                    if (context.mounted) {
                      await Provider.of<StreakProvider>(context, listen: false)
                          .refreshStreak();
                      if (context.mounted) {
                        CustomSnackBar.show(
                          context,
                          'Streak pulled from cloud',
                          isSuccess: true,
                        );
                      }
                    }
                    FirebaseCrashlytics.instance.log('Streak pull success');
                  } catch (e) {
                    FlutterBugfender.sendCrash('Streak pull failed: $e',
                        StackTrace.current.toString());
                    if (context.mounted) {
                      CustomSnackBar.show(
                        context,
                        'Failed to pull streak: $e',
                        isSuccess: false,
                      );
                    }
                  }
                }),
                buildSettingsTile(context,
                    title: "Reset Streak",
                    subtitle: "Set streak to 0 and start over (irreversible)",
                    icon: LineIcons.redo,
                    onTap: () => _showResetDialog(context, streakProvider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainToggle(BuildContext context, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildStreakInfoTile(
      BuildContext context, String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(child: Text(title)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildNotificationTypeToggle(BuildContext context, String title,
      String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(
      BuildContext context, String title, String currentTime) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(currentTime, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          TextButton(
            onPressed: () => _showTimePicker(context),
            child: const Text("Change"),
          ),
        ],
      ),
    );
  }

  void _showTimePicker(BuildContext context) async {
    final streakProvider = Provider.of<StreakProvider>(context, listen: false);
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      setState(() => _selectedTime = time);

      streakProvider.setNotificationTime(time);
    }
  }

  void _showResetDialog(BuildContext context, StreakProvider streakProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Streak?"),
        content: const Text("This will reset your streak to 0. Continue?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              streakProvider.resetStreak();
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly.isAtSameMomentAs(today)) {
      return "Today";
    }
    if (dateOnly.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return "Yesterday";
    }
    return "${date.day}/${date.month}/${date.year}";
  }
}
