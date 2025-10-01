// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:msbridge/theme/colors.dart';
import 'theme_icons.dart';

class ThemeCard extends StatelessWidget {
  const ThemeCard({
    super.key,
    required this.appTheme,
    required this.themeData,
    required this.isSelected,
    required this.onTap,
  });

  final AppTheme appTheme;
  final ThemeData themeData;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Theme Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  ThemeIcons.getThemeIcon(appTheme),
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),

              // Theme Name
              Text(
                appTheme.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Color Preview
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildColorDot(themeData.colorScheme.primary),
                  const SizedBox(width: 3),
                  _buildColorDot(themeData.colorScheme.secondary),
                  const SizedBox(width: 3),
                  _buildColorDot(themeData.colorScheme.surface),
                ],
              ),

              // Active Indicator
              if (isSelected) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check,
                        size: 10,
                        color: colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "Active",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
      ),
    );
  }
}
