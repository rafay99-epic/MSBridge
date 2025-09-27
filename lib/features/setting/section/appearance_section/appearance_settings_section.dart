import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/features/setting/section/appearance_section/theme/theme_selector.dart';
import 'package:provider/provider.dart';

class AppearanceSettingsSection extends StatelessWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Theme Customization
        _buildSubsectionHeader(
            context, "Theme Customization", LineIcons.palette),
        const SizedBox(height: 12),
        _buildModernSettingsTile(
          context,
          title: "Choose Theme",
          subtitle: "Select your preferred app appearance",
          icon: LineIcons.palette,
          child: ThemeSelector(themeProvider: themeProvider),
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
            color: colorScheme.secondary.withValues(alpha: 0.1),
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
    Widget? child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
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
                        color: colorScheme.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 16),
            child,
          ],
        ],
      ),
    );
  }
}
