import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/provider/haptic_feedback_settings_provider.dart';
import 'package:msbridge/core/models/haptic_feedback_settings_model.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/bottom_sheet_base.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_section_header.dart';
import 'package:msbridge/features/setting/bottom_sheets/components/setting_toggle_tile.dart';
import 'package:provider/provider.dart';

class AppSettingsBottomSheet extends StatelessWidget {
  const AppSettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomSheetBase(
      title: "App Settings",
      content: const HapticFeedbackSettingsSection(),
    );
  }
}

class HapticFeedbackSettingsSection extends StatelessWidget {
  const HapticFeedbackSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HapticFeedbackSettingsProvider>(
      builder: (context, hapticProvider, child) {
        final settings = hapticProvider.settings;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            SettingSectionHeader(
              title: "Haptic Feedback",
              icon: LineIcons.cog,
            ),
            const SizedBox(height: 16),

            // Navigation Haptic Toggle
            SettingToggleTile(
              title: "Navigation Feedback",
              subtitle: "Haptic feedback when switching tabs",
              icon: LineIcons.cog,
              value: settings.navigationEnabled,
              onChanged: (value) {
                hapticProvider.updateNavigationEnabled(value);
                if (value) {
                  hapticProvider.triggerButtonHaptic();
                }
              },
            ),

            // Button Haptic Toggle
            SettingToggleTile(
              title: "Button Feedback",
              subtitle: "Haptic feedback when tapping buttons",
              icon: LineIcons.cog,
              value: settings.buttonEnabled,
              onChanged: (value) {
                hapticProvider.updateButtonEnabled(value);
                if (value) {
                  hapticProvider.triggerButtonHaptic();
                }
              },
            ),

            // Gesture Haptic Toggle
            SettingToggleTile(
              title: "Gesture Feedback",
              subtitle: "Haptic feedback for swipe gestures",
              icon: LineIcons.cog,
              value: settings.gestureEnabled,
              onChanged: (value) {
                hapticProvider.updateGestureEnabled(value);
                if (value) {
                  hapticProvider.triggerGestureHaptic();
                }
              },
            ),

            // Intensity Selection
            _buildIntensityTile(context, hapticProvider, settings),
          ],
        );
      },
    );
  }

  Widget _buildIntensityTile(
    BuildContext context,
    HapticFeedbackSettingsProvider hapticProvider,
    HapticFeedbackSettingsModel settings,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            LineIcons.cog,
            size: 20,
            color: colorScheme.primary,
          ),
        ),
        title: Text(
          "Feedback Intensity",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          "Adjust the strength of haptic feedback",
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: GestureDetector(
          onTap: () => _showIntensityDialog(context, hapticProvider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  settings.intensity.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIntensityDialog(
      BuildContext context, HapticFeedbackSettingsProvider hapticProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Haptic Feedback Intensity',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how strong the haptic feedback feels',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Intensity options
              ...HapticFeedbackIntensity.values.map((intensity) {
                final isSelected =
                    hapticProvider.settings.intensity == intensity;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withOpacity(0.1)
                            : colorScheme.outline.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIntensityIcon(intensity),
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      intensity.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      intensity.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      hapticProvider.updateIntensity(intensity);
                      hapticProvider.triggerButtonHaptic();
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIntensityIcon(HapticFeedbackIntensity intensity) {
    switch (intensity) {
      case HapticFeedbackIntensity.light:
        return LineIcons.circle;
      case HapticFeedbackIntensity.medium:
        return LineIcons.circle;
      case HapticFeedbackIntensity.heavy:
        return LineIcons.circle;
    }
  }
}
