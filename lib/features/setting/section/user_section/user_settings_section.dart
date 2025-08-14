import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/config/feature_flag.dart';
import 'package:msbridge/core/provider/fingerprint_provider.dart';
import 'package:msbridge/features/changePassword/change_password.dart';
import 'package:msbridge/features/setting/section/user_section/logout/logout_dialog.dart';
import 'package:msbridge/features/setting/section/user_section/pin_lock_screen.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/features/profile/profile_edit_page.dart';
import 'package:msbridge/core/provider/app_pin_lock_provider.dart';

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
        _buildSubsectionHeader(
            context, "Security & Privacy", LineIcons.userShield),
        const SizedBox(height: 12),
        _buildModernSettingsTile(
          context,
          title: "PIN Lock",
          subtitle: "Secure your app with a PIN code",
          icon: LineIcons.lock,
          trailing: Consumer<AppPinLockProvider>(
            builder: (context, pinProvider, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Switch(
                    value: pinProvider.enabled,
                    onChanged: (v) async {
                      if (v) {
                        if (!await pinProvider.hasPin()) {
                          // Show warning dialog before creating PIN
                          bool? proceed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              final theme = Theme.of(context);
                              final colorScheme = theme.colorScheme;
                              return AlertDialog(
                                backgroundColor: colorScheme.surface,
                                title: Text(
                                  'Important: PIN Security',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  '⚠️ Warning: There is no "forgot PIN" option.\n\n'
                                  'If you forget your PIN, you can only change it in Settings.\n\n'
                                  'Make sure to remember your PIN or keep it in a secure place.',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    height: 1.4,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text(
                                      'Cancel',
                                      style:
                                          TextStyle(color: colorScheme.primary),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                    ),
                                    child: const Text('I Understand'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (proceed == true) {
                            Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.rightToLeft,
                                child: PinLockScreen(
                                  isCreating: true,
                                  onConfirmed: (pin) async {
                                    await pinProvider.savePin(
                                        pin); // ✅ Use savePin for new PINs
                                    await pinProvider.setEnabled(true);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            );
                          }
                        } else {
                          await pinProvider.setEnabled(true);
                        }
                      } else {
                        await pinProvider.setEnabled(false);
                      }
                    },
                  ),
                  if (pinProvider.enabled) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Enabled',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.6),
                            fontSize: 10,
                          ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),

        // Change PIN option - only show if PIN lock is enabled
        Consumer<AppPinLockProvider>(
          builder: (context, pinProvider, _) {
            if (!pinProvider.enabled) return const SizedBox.shrink();

            return Column(
              children: [
                const SizedBox(height: 12),
                _buildModernSettingsTile(
                  context,
                  title: "Change PIN",
                  subtitle: "Update your PIN code",
                  icon: LineIcons.key,
                  onTap: () async {
                    // First verify current PIN
                    final currentPin = await pinProvider.readPin();
                    if (currentPin != null) {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: PinLockScreen(
                            isChanging: true,
                            existingPin: currentPin,
                            onConfirmed: (newPin) async {
                              await pinProvider
                                  .updatePin(newPin); // ✅ Use updatePin method
                              CustomSnackBar.show(
                                context,
                                'PIN changed successfully!',
                                isSuccess: true,
                              );
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildModernSettingsTile(
                  context,
                  title: "Reset PIN",
                  subtitle: "Remove PIN lock completely",
                  icon: LineIcons.trash,
                  onTap: () async {
                    // Show confirmation dialog
                    bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        final theme = Theme.of(context);
                        final colorScheme = theme.colorScheme;
                        return AlertDialog(
                          backgroundColor: colorScheme.surface,
                          title: Text(
                            'Reset PIN Lock',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            'This will completely remove your PIN lock.\n\n'
                            'You will need to create a new PIN if you want to re-enable PIN lock.',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              height: 1.4,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: colorScheme.primary),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                              ),
                              child: const Text('Reset PIN'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirm == true) {
                      await pinProvider.clearPin();
                      await pinProvider.setEnabled(false);
                      CustomSnackBar.show(
                        context,
                        'PIN lock has been reset!',
                        isSuccess: true,
                      );
                    }
                  },
                ),
              ],
            );
          },
        ),

        if (FeatureFlag.enableFingerprintLock)
          // Security & Privacy
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
