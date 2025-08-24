// features/setting/bottom_sheets/profile_management_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/features/changePassword/change_password.dart';
import 'package:msbridge/features/profile/profile_edit_page.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/bottom_sheet_base.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_action_tile.dart';
import 'package:msbridge/features/setting/section/user_section/logout/logout_dialog.dart';
import 'package:page_transition/page_transition.dart';

class ProfileManagementBottomSheet extends StatelessWidget {
  const ProfileManagementBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomSheetBase(
      title: "Profile Management",
      content: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingActionTile(
          title: "Edit Profile",
          subtitle: "Update your personal information",
          icon: LineIcons.user,
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: const ProfileEditPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        SettingActionTile(
          title: "Change Password",
          subtitle: "Update your account password",
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
        const SizedBox(height: 12),
        SettingActionTile(
          title: "Logout",
          subtitle: "Sign out of your account",
          icon: LineIcons.alternateSignOut,
          onTap: () => showLogoutDialog(context),
        ),
      ],
    );
  }
}
