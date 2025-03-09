import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/core/repo/webview_repo.dart';
import 'package:msbridge/features/setting/widgets/settings_section.dart';
import 'package:msbridge/features/setting/widgets/settings_tile.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';

class AdminSettingsSection extends StatefulWidget {
  const AdminSettingsSection({super.key});

  @override
  State<AdminSettingsSection> createState() => _AdminSettingsSectionState();
}

class _AdminSettingsSectionState extends State<AdminSettingsSection> {
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
    final theme = Theme.of(context);
    if (!_isVisible) {
      return const SizedBox.shrink();
    }
    Divider(color: theme.colorScheme.primary);

    return SettingsSection(
      title: "Admin Settings",
      children: [
        SettingsTile(
          title: "Tina CMS",
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
        SettingsTile(
          title: "Page CMS",
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
        SettingsTile(
          title: "Contact Messages",
          icon: LineIcons.users,
          onTap: () {
            CustomSnackBar.show(context, "Coming Soon");
          },
        ),
      ],
    );
  }
}
