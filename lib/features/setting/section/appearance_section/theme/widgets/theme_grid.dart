// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/theme/colors.dart';
import 'package:msbridge/core/models/custom_color_scheme_model.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'theme_card.dart';
import 'custom_theme_card.dart';
import 'custom_color_picker.dart';

class ThemeGrid extends StatefulWidget {
  const ThemeGrid({
    super.key,
    required this.searchQuery,
    required this.themeProvider,
  });

  final String searchQuery;
  final ThemeProvider themeProvider;

  @override
  State<ThemeGrid> createState() => _ThemeGridState();
}

class _ThemeGridState extends State<ThemeGrid> {
  @override
  Widget build(BuildContext context) {
    // Filter themes based on search
    final filteredThemes = AppTheme.values.where((theme) {
      if (widget.searchQuery.isEmpty) return true;
      return theme.name.toLowerCase().contains(widget.searchQuery);
    }).toList();

    // Get custom color schemes
    final customSchemes = widget.themeProvider.customColorScheme != null
        ? [widget.themeProvider.customColorScheme!]
        : <dynamic>[];

    // Combine regular themes and custom schemes
    final allItems = <dynamic>[
      ...filteredThemes,
      ...customSchemes,
      null, // Add button for creating new custom theme
    ];

    if (allItems.isEmpty) {
      return _buildNoThemesFound(context);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];

        if (item == null) {
          // Create custom theme button
          return CustomThemeCard(
            customScheme: null,
            isSelected: false,
            themeProvider: widget.themeProvider,
            onTap: () => _showCreateCustomThemeDialog(),
          );
        } else if (item is AppTheme) {
          // Regular theme
          final appTheme = item;
          final isSelected = !widget.themeProvider.isCustomTheme &&
              widget.themeProvider.selectedTheme == appTheme;
          final themeData = AppThemes.themeMap[appTheme]!;

          return ThemeCard(
            appTheme: appTheme,
            themeData: themeData,
            isSelected: isSelected,
            onTap: () => widget.themeProvider.setTheme(appTheme),
          );
        } else {
          // Custom color scheme
          final customScheme = item;
          final isSelected = widget.themeProvider.isCustomTheme &&
              widget.themeProvider.customColorScheme?.id == customScheme.id;

          return CustomThemeCard(
            customScheme: customScheme,
            isSelected: isSelected,
            themeProvider: widget.themeProvider,
            onTap: () =>
                widget.themeProvider.setCustomColorScheme(customScheme),
            onEdit: () => _showEditDialog(customScheme),
            onDelete: () => _showDeleteDialog(customScheme),
          );
        }
      },
    );
  }

  void _showCreateCustomThemeDialog() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CustomColorPicker(
          themeProvider: widget.themeProvider,
          onSchemeCreated: (scheme) {
            // Refresh the UI
            setState(() {});
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide transition from right to left
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _showEditDialog(CustomColorSchemeModel scheme) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CustomColorPicker(
          themeProvider: widget.themeProvider,
          existingScheme: scheme,
          onSchemeUpdated: (updatedScheme) {
            // Refresh the UI
            setState(() {});
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide transition from right to left
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _showDeleteDialog(CustomColorSchemeModel scheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Theme',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${scheme.name}"?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading indicator to prevent UI jerk
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              final success =
                  await widget.themeProvider.deleteCustomColorScheme(scheme);

              // Hide loading indicator
              if (context.mounted) {
                Navigator.of(context).pop();
              }

              if (success) {
                // Add a small delay to prevent UI jerk
                await Future.delayed(const Duration(milliseconds: 150));
                setState(() {
                  CustomSnackBar.show(context, 'Theme deleted successfully!',
                      isSuccess: true);
                });
              } else {
                if (context.mounted) {
                  CustomSnackBar.show(context, 'Failed to delete theme',
                      isSuccess: false);
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              'Delete',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoThemesFound(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 32,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              "No themes found",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                  ),
            ),
            Text(
              "Try a different search term",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
