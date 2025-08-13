import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/config/feature_flag.dart';
import 'package:msbridge/core/provider/fingerprint_provider.dart';
import 'package:msbridge/features/changePassword/change_password.dart';
import 'package:msbridge/features/setting/section/user_section/logout/logout_dialog.dart';
import 'package:msbridge/features/setting/widgets/settings_section.dart';
import 'package:msbridge/features/setting/widgets/settings_tile.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/features/profile/profile_edit_page.dart';

class UserSettingsSection extends StatelessWidget {
  const UserSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: "User Settings",
      children: [
        SettingsTile(
          title: "Edit Profile",
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
        if (FeatureFlag.enableFingerprintLock)
          Consumer<FingerprintAuthProvider>(
            builder: (context, fingerprintProvider, child) {
              return SettingsTile(
                title: "Fingerprint Lock",
                icon: LineIcons.fingerprint,
                trailing: Switch(
                  value: fingerprintProvider.isFingerprintEnabled,
                  onChanged: (value) async {
                    if (value) {
                      bool authenticated =
                          await fingerprintProvider.authenticate(context);
                      if (authenticated) {
                        fingerprintProvider.setFingerprintEnabled(true);
                      } else {
                        CustomSnackBar.show(
                            context, "Fingerprint authentication failed.");
                      }
                    } else {
                      fingerprintProvider.setFingerprintEnabled(false);
                    }
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}
