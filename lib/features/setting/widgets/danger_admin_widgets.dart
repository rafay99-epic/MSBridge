import 'package:flutter/material.dart';
import 'package:msbridge/features/setting/section/danger_section/danger_settings_section.dart';
import 'package:msbridge/features/setting/section/admin_section/admin_settings_section.dart';

class DangerAdminWidgets {
  static Widget buildDangerSection(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "Danger Zone",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const DangerSettingsSection(),
          ),
        ],
      ),
    );
  }

  static Widget buildAdminSection(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "Administration",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.secondary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: const AdminSettingsSection(),
          ),
        ],
      ),
    );
  }
}
