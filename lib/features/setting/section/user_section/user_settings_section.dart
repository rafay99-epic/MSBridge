import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/features/changePassword/change_password.dart';
import 'package:msbridge/features/setting/section/user_section/logout/logout_dialog.dart';
import 'package:msbridge/features/setting/widgets/settings_section.dart';
import 'package:msbridge/features/setting/widgets/settings_tile.dart';
import 'package:page_transition/page_transition.dart';

class UserSettingsSection extends StatelessWidget {
  const UserSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: "User Settings",
      children: [
        SettingsTile(
          title: "Logout",
          icon: LineIcons.alternateSignOut,
          onTap: () => showLogoutDialog(context),
        ),
        SettingsTile(
          title: "Change Password",
          icon: LineIcons.lock,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const Changepassword(),
              ),
            );
          },
        ),
      ],
    );
  }
}
