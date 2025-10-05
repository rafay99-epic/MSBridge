// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:msbridge/core/models/custom_color_scheme_model.dart';
import 'package:msbridge/core/provider/theme_provider.dart';

class CustomThemeCard extends StatelessWidget {
  final CustomColorSchemeModel? customScheme;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ThemeProvider themeProvider;

  const CustomThemeCard({
    super.key,
    this.customScheme,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outline.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            if (isSelected)
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color preview circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: customScheme != null
                    ? LinearGradient(
                        colors: [
                          customScheme!.primary,
                          customScheme!.secondary,
                          customScheme!.background,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      )
                    : null,
                color: customScheme == null
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : null,
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: customScheme != null
                    ? [
                        BoxShadow(
                          color: customScheme!.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                customScheme != null ? Icons.palette : Icons.add,
                color: customScheme != null
                    ? customScheme!.textColor
                    : colorScheme.primary,
                size: 20,
              ),
            ),

            const SizedBox(height: 8),

            // Theme name
            Flexible(
              child: Text(
                customScheme?.name ?? 'Create Custom',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 4),

            // Active indicator
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Active',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),

            const SizedBox(height: 6),

            // Action buttons
            if (customScheme != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit button
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        color: colorScheme.primary.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.05),
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(28, 28),
                      ),
                      tooltip: 'Edit Theme',
                    ),

                  if (onEdit != null && onDelete != null)
                    const SizedBox(width: 4),

                  // Delete button
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            colorScheme.error.withValues(alpha: 0.05),
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(28, 28),
                      ),
                      tooltip: 'Delete Theme',
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
