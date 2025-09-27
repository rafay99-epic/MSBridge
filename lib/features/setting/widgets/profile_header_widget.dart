import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/theme_provider.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;

  const ProfileHeaderWidget({
    super.key,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.1),
                colorScheme.secondary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LineIcons.user,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "MS Bridge",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Customize your experience",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: themeProvider.dynamicColorsEnabled
                            ? colorScheme.primary.withValues(alpha: 0.2)
                            : colorScheme.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: themeProvider.dynamicColorsEnabled
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : colorScheme.secondary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            themeProvider.dynamicColorsEnabled
                                ? Icons.auto_awesome
                                : Icons.palette,
                            size: 14,
                            color: themeProvider.dynamicColorsEnabled
                                ? colorScheme.primary
                                : colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            themeProvider.effectiveThemeName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: themeProvider.dynamicColorsEnabled
                                  ? colorScheme.primary
                                  : colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
