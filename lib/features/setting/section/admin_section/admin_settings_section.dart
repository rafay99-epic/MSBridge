import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/core/repo/webview_repo.dart';
import 'package:msbridge/widgets/build_settings_tile.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:msbridge/features/setting/section/admin_section/deletion_sync_debug_page.dart';

class AdminSettingsSection extends StatefulWidget {
  const AdminSettingsSection({super.key});

  @override
  State<AdminSettingsSection> createState() => _AdminSettingsSectionState();
}

class _AdminSettingsSectionState extends State<AdminSettingsSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _isVisible = false;
  final AuthRepo _authRepo = AuthRepo();

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final result = await _authRepo.getUserRole();
    if (result.error != null) {
      if (mounted) {
        setState(() {
          _isVisible = result.error == 'owner' || result.error == 'admin';
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content Management
        _buildSubsectionHeader(context, "Content Management", LineIcons.edit),
        const SizedBox(height: 12),
        buildSettingsTile(
          context,
          title: "Tina CMS",
          subtitle: "Manage website content and structure",
          icon: LineIcons.edit,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child:
                    const MyCMSWebView(cmsUrl: "https://www.rafay99.com/admin"),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        buildSettingsTile(
          context,
          title: "Page CMS",
          subtitle: "Manage page content and layouts",
          icon: LineIcons.pen,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const MyCMSWebView(
                    cmsUrl: "https://app.pagescms.org/sign-in"),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Background/Sync Tools
        _buildSubsectionHeader(context, "Background Sync", LineIcons.sun),
        const SizedBox(height: 12),
        buildSettingsTile(
          context,
          title: "Deletion Sync Debug",
          subtitle: "Run Workmanager sync and view last status",
          icon: LineIcons.trash,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const DeletionSyncDebugPage(),
              ),
            );
          },
        ),

        // User Management
        _buildSubsectionHeader(context, "User Management", LineIcons.users),
        const SizedBox(height: 12),
        buildSettingsTile(
          context,
          title: "Contact Messages",
          subtitle: "View and manage user feedback",
          icon: LineIcons.users,
          onTap: () {
            CustomSnackBar.show(context, "Coming Soon");
          },
        ),
      ],
    );
  }

  Widget _buildSubsectionHeader(
      BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  // Widget _buildModernSettingsTile(
  //   BuildContext context, {
  //   required String title,
  //   required String subtitle,
  //   required IconData icon,
  //   VoidCallback? onTap,
  // }) {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;

  //   return Material(
  //     color: Colors.transparent,
  //     child: InkWell(
  //       onTap: onTap,
  //       borderRadius: BorderRadius.circular(12),
  //       splashColor: colorScheme.primary.withOpacity(0.1),
  //       highlightColor: colorScheme.primary.withOpacity(0.05),
  //       child: Container(
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(
  //             color: colorScheme.outline.withOpacity(0.1),
  //             width: 1,
  //           ),
  //         ),
  //         child: Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(10),
  //               decoration: BoxDecoration(
  //                 color: colorScheme.primary.withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //               child: Icon(
  //                 icon,
  //                 size: 20,
  //                 color: colorScheme.primary,
  //               ),
  //             ),
  //             const SizedBox(width: 16),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     title,
  //                     style: theme.textTheme.titleMedium?.copyWith(
  //                       fontWeight: FontWeight.w600,
  //                       color: colorScheme.primary,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     subtitle,
  //                     style: theme.textTheme.bodySmall?.copyWith(
  //                       color: colorScheme.primary.withOpacity(0.6),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             if (onTap != null) ...[
  //               const SizedBox(width: 16),
  //               Icon(
  //                 Icons.chevron_right,
  //                 size: 20,
  //                 color: colorScheme.primary.withOpacity(0.5),
  //               ),
  //             ],
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
