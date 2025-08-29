import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/provider/app_pin_lock_provider.dart';
import 'package:msbridge/features/setting/section/user_section/pin_lock_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

class PinSettingsBottomSheet extends StatelessWidget {
  const PinSettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LineIcons.lock,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "PIN Settings",
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Manage your app security",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer<AppPinLockProvider>(
                    builder: (context, pinProvider, _) {
                      return FutureBuilder<bool>(
                        future: pinProvider.hasPin(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final hasPin = snapshot.data ?? false;
                          return Column(
                            children: [
                              // PIN Lock Toggle
                              _buildSettingsTile(
                                context,
                                "PIN Lock",
                                "Secure your app with a PIN code",
                                LineIcons.lock,
                                Switch(
                                  value: pinProvider.enabled,
                                  onChanged: (value) {
                                    if (value) {
                                      _showCreatePinDialog(context);
                                    } else {
                                      _showDisablePinDialog(context, pinProvider);
                                    }
                                  },
                                  activeColor: colorScheme.primary,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Change PIN
                              if (hasPin) ...[
                                _buildSettingsTile(
                                  context,
                                  "Change PIN",
                                  "Update your existing PIN code",
                                  LineIcons.edit,
                                  Icon(Icons.chevron_right),
                                  onTap: () => _navigateToChangePin(context),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Reset PIN
                              if (hasPin) ...[
                                _buildSettingsTile(
                                  context,
                                  "Reset PIN",
                                  "Remove PIN and disable lock",
                                  LineIcons.trash,
                                  Icon(Icons.chevron_right),
                                  onTap: () =>
                                      _showResetPinDialog(context, pinProvider),
                                  isDestructive: true,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // PIN Status
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: pinProvider.enabled
                                      ? colorScheme.primary.withOpacity(0.1)
                                      : colorScheme.outline.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: pinProvider.enabled
                                        ? colorScheme.primary.withOpacity(0.3)
                                        : colorScheme.outline.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      pinProvider.enabled
                                          ? LineIcons.checkCircle
                                          : LineIcons.infoCircle,
                                      color: pinProvider.enabled
                                          ? colorScheme.primary
                                          : colorScheme.outline,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        pinProvider.enabled
                                            ? "PIN Lock is enabled"
                                            : "PIN Lock is disabled",
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: pinProvider.enabled
                                              ? colorScheme.primary
                                              : colorScheme.outline,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget trailing, {
    VoidCallback? onTap,
    bool isDestructive = false,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? colorScheme.error.withOpacity(0.1)
                      : colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color:
                      isDestructive ? colorScheme.error : colorScheme.primary,
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
                        color: isDestructive
                            ? colorScheme.error
                            : colorScheme.primary,
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
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePinDialog(BuildContext context) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: PinLockScreen(
          isCreating: true,
          onConfirmed: (pin) {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _navigateToChangePin(BuildContext context) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: PinLockScreen(
          isChanging: true,
          onConfirmed: (pin) {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showDisablePinDialog(
      BuildContext context, AppPinLockProvider pinProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Disable PIN Lock"),
        content: const Text(
          "Are you sure you want to disable PIN lock? This will remove the security from your app.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              pinProvider.setEnabled(false);
              Navigator.pop(context);
            },
            child: const Text("Disable"),
          ),
        ],
      ),
    );
  }

  void _showResetPinDialog(
      BuildContext context, AppPinLockProvider pinProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset PIN"),
        content: const Text(
          "Are you sure you want to reset your PIN? This will remove the PIN lock completely.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              pinProvider.setEnabled(false);
              Navigator.pop(context);
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }
}
