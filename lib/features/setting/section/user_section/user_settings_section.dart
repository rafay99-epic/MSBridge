import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/config/feature_flag.dart';
import 'package:msbridge/core/provider/fingerprint_provider.dart';
import 'package:msbridge/features/changePassword/change_password.dart';
import 'package:msbridge/features/setting/section/user_section/logout/logout_dialog.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/features/profile/profile_edit_page.dart';

class UserSettingsSection extends StatelessWidget {
  const UserSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Management
        _buildSubsectionHeader(context, "Profile Management", LineIcons.user),
        const SizedBox(height: 12),
        _buildModernSettingsTile(
          context,
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
        _buildModernSettingsTile(
          context,
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

        const SizedBox(height: 24),

        if (FeatureFlag.enableFingerprintLock)
          // Security & Privacy
          _buildSubsectionHeader(
              context, "Security & Privacy", LineIcons.userShield),
        const SizedBox(height: 12),
        Consumer<FingerprintAuthProvider>(
          builder: (context, fingerprintProvider, child) {
            return _buildModernSettingsTile(
              context,
              title: "Fingerprint Lock",
              subtitle: "Use biometric authentication to secure the app",
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

        const SizedBox(height: 24),

        // Account Actions
        _buildSubsectionHeader(
            context, "Account Actions", LineIcons.alternateSignOut),
        const SizedBox(height: 12),
        _buildModernSettingsTile(
          context,
          title: "Logout",
          subtitle: "Sign out of your account",
          icon: LineIcons.alternateSignOut,
          onTap: () => showLogoutDialog(context),
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

  Widget _buildModernSettingsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: colorScheme.primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing,
              ] else if (onTap != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colorScheme.primary.withOpacity(0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
