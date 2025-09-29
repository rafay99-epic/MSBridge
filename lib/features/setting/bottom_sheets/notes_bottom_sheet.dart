// features/setting/bottom_sheets/notes_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/provider/share_link_provider.dart';
import 'package:msbridge/core/repo/share_repo.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/bottom_sheet_base.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_action_tile.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_section_header.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_toggle_tile.dart';
import 'package:msbridge/features/setting/section/note_section/shared_notes_page.dart';
import 'package:msbridge/features/setting/section/note_section/version_history_settings.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesBottomSheet extends StatelessWidget {
  const NotesBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomSheetBase(
      title: "Notes & AI Settings",
      content: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Version History section
        const SettingSectionHeader(
          title: "Version History",
          icon: LineIcons.history,
        ),
        const SizedBox(height: 12),

        StatefulBuilder(
          builder: (ctx, setLocal) {
            return FutureBuilder<bool>(
              future: () async {
                final prefs = await SharedPreferences.getInstance();
                return prefs.getBool('version_history_enabled') ?? true;
              }(),
              builder: (context, snapshot) {
                final isEnabled = snapshot.data ?? true;
                return SettingToggleTile(
                  title: "Enable Version History",
                  subtitle: isEnabled
                      ? "Automatically track changes to your notes"
                      : "Version tracking is currently disabled",
                  icon: LineIcons.history,
                  value: isEnabled,
                  onChanged: (value) =>
                      _toggleVersionHistory(context, value, setLocal),
                );
              },
            );
          },
        ),

        const SizedBox(height: 8),

        SettingActionTile(
          title: "Version History Settings",
          subtitle: "Configure version limits and cleanup",
          icon: LineIcons.cog,
          onTap: () {
            Navigator.of(context).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: const VersionHistorySettings(),
                ),
              );
            });
          },
        ),

        const SizedBox(height: 24),
        const SettingSectionHeader(
          title: "Sharing & Collaboration",
          icon: LineIcons.share,
        ),
        const SizedBox(height: 12),

        Consumer<ShareLinkProvider>(
          builder: (context, shareProvider, _) {
            return Column(
              children: [
                SettingToggleTile(
                  title: "Shareable Links",
                  subtitle: "Create shareable links for your notes",
                  icon: LineIcons.shareSquare,
                  value: shareProvider.shareLinksEnabled,
                  onChanged: (value) =>
                      _toggleShareLinks(context, value, shareProvider),
                ),
                if (shareProvider.shareLinksEnabled) ...[
                  const SizedBox(height: 12),
                  SettingActionTile(
                    title: "Shared Notes",
                    subtitle: "Manage your shared notes and links",
                    icon: LineIcons.share,
                    onTap: () {
                      Navigator.of(context).pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: const SharedNotesPage(),
                          ),
                        );
                      });
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _toggleVersionHistory(BuildContext context, bool value,
      void Function(void Function()) setLocal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('version_history_enabled', value);
    setLocal(() {});
    if (context.mounted) {
      if (value) {
        CustomSnackBar.show(
          context,
          'Version History enabled! Your notes will now track changes automatically.',
          isSuccess: true,
        );
      } else {
        CustomSnackBar.show(
          context,
          'Version History disabled. No new versions will be created.',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _toggleShareLinks(
    BuildContext context,
    bool value,
    ShareLinkProvider provider,
  ) async {
    final prev = provider.shareLinksEnabled;
    if (!value) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: const Text('Disable shareable links?'),
            content: const Text(
                'This will disable all existing shared notes. You can re-enable sharing later.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Disable'),
              ),
            ],
          );
        },
      );
      if (confirm != true) return;
      try {
        await DynamicLink.disableAllShares();
      } catch (e) {
        FlutterBugfender.sendCrash('Failed to disable existing shares: $e',
            StackTrace.current.toString());
        FlutterBugfender.error('Failed to disable existing shares: $e');
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            'Failed to disable existing shares. Please try again.',
            isSuccess: false,
          );
        }
        provider.shareLinksEnabled = prev;
        return;
      }
    }
    provider.shareLinksEnabled = value;
  }
}
