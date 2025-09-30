// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:msbridge/core/provider/template_settings_provider.dart';
import 'package:msbridge/core/services/sync/auto_sync_scheduler.dart';
import 'package:msbridge/core/services/sync/templates_sync.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/bottom_sheet_base.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_action_tile.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_section_header.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_toggle_tile.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/sync_interval_dialog.dart';
import 'package:msbridge/widgets/snakbar.dart';

class TemplatesBottomSheet extends StatefulWidget {
  const TemplatesBottomSheet({super.key});

  @override
  State<TemplatesBottomSheet> createState() => _TemplatesBottomSheetState();
}

class _TemplatesBottomSheetState extends State<TemplatesBottomSheet> {
  bool _isSyncing = false;
  bool _isPulling = false;

  @override
  Widget build(BuildContext context) {
    return BottomSheetBase(
      title: 'Templates',
      content: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingSectionHeader(
          title: 'Templates',
          icon: LineIcons.clone,
        ),
        const SizedBox(height: 12),
        Consumer<TemplateSettingsProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                SettingToggleTile(
                  title: 'Enable Templates',
                  subtitle: provider.enabled
                      ? 'Templates feature is enabled'
                      : 'Templates feature is disabled',
                  icon: LineIcons.clone,
                  value: provider.enabled,
                  onChanged: (v) => provider.setEnabled(v),
                ),
                const SizedBox(height: 12),
                SettingToggleTile(
                  title: 'Cloud Sync',
                  subtitle: provider.cloudSyncEnabled
                      ? 'Sync templates to Firebase'
                      : 'Do not sync templates to cloud',
                  icon: LineIcons.cloud,
                  value: provider.cloudSyncEnabled,
                  onChanged: (v) => provider.setCloudSyncEnabled(v),
                ),
                const SizedBox(height: 16),
                SettingActionTile(
                  title: 'Sync Templates to Cloud',
                  subtitle: 'Push local templates to Firebase',
                  icon: LineIcons.upload,
                  onTap: () async {
                    // Also respect global cloud sync
                    final prefs = await SharedPreferences.getInstance();
                    final global = prefs.getBool('cloud_sync_enabled') ?? true;
                    if (!provider.enabled ||
                        !provider.cloudSyncEnabled ||
                        !global) {
                      if (context.mounted) {
                        CustomSnackBar.show(
                          context,
                          'Templates sync is disabled',
                          isSuccess: false,
                        );
                      }

                      return;
                    }
                    setState(() => _isSyncing = true);
                    try {
                      await TemplatesSyncService()
                          .syncLocalTemplatesToFirebase();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        CustomSnackBar.show(
                          context,
                          'Templates synced to cloud',
                          isSuccess: true,
                        );
                      }
                    } catch (e) {
                      FlutterBugfender.sendCrash(
                          'Failed to sync templates to cloud: $e',
                          StackTrace.current.toString());
                      FlutterBugfender.error(
                          'Failed to sync templates to cloud: $e');
                    } finally {
                      if (context.mounted) setState(() => _isSyncing = false);
                    }
                  },
                  isLoading: _isSyncing,
                  isDisabled: !provider.cloudSyncEnabled || !provider.enabled,
                ),
                const SizedBox(height: 12),
                SettingActionTile(
                  title: 'Pull Templates from Cloud',
                  subtitle: 'Download templates to this device',
                  icon: LineIcons.download,
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final global = prefs.getBool('cloud_sync_enabled') ?? true;
                    if (!provider.enabled ||
                        !provider.cloudSyncEnabled ||
                        !global) {
                      if (context.mounted) {
                        CustomSnackBar.show(
                          context,
                          'Templates sync is disabled',
                          isSuccess: false,
                        );
                      }
                      return;
                    }
                    setState(() => _isPulling = true);
                    try {
                      final count =
                          await TemplatesSyncService().pullTemplatesFromCloud();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        CustomSnackBar.show(
                          context,
                          count > 0
                              ? 'Pulled $count templates from cloud'
                              : 'No templates found in cloud',
                          isSuccess: count > 0,
                        );
                      }
                    } catch (e) {
                      FlutterBugfender.sendCrash(
                          'Failed to pull templates from cloud: $e',
                          StackTrace.current.toString());
                      FlutterBugfender.error(
                          'Failed to pull templates from cloud: $e');
                    } finally {
                      if (mounted) setState(() => _isPulling = false);
                    }
                  },
                  isLoading: _isPulling,
                  isDisabled: !provider.cloudSyncEnabled || !provider.enabled,
                ),
                const SizedBox(height: 12),
                SettingActionTile(
                  title: 'Templates Auto sync interval',
                  subtitle: 'Off / 15 / 30 / 60 minutes',
                  icon: LineIcons.history,
                  onTap: () async {
                    final current =
                        await AutoSyncScheduler.getTemplatesIntervalMinutes();
                    if (!context.mounted) return;
                    final choice = await SyncIntervalDialog.show(
                      context,
                      initialMinutes: current,
                      title: 'Templates Auto sync interval',
                    );
                    if (choice != null) {
                      await AutoSyncScheduler.setTemplatesIntervalMinutes(
                          choice);
                      if (!context.mounted) return;
                      CustomSnackBar.show(
                        context,
                        choice == 0
                            ? 'Templates auto sync turned off'
                            : 'Templates auto sync set to every $choice minutes',
                        isSuccess: true,
                      );
                    }
                  },
                  isDisabled: !provider.cloudSyncEnabled || !provider.enabled,
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ],
    );
  }
}
