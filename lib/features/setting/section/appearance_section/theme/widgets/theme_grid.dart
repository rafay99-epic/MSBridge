import 'package:flutter/material.dart';
import 'package:msbridge/theme/colors.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'theme_card.dart';

class ThemeGrid extends StatelessWidget {
  const ThemeGrid({
    super.key,
    required this.searchQuery,
    required this.themeProvider,
  });

  final String searchQuery;
  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    // Filter themes based on search
    final filteredThemes = AppTheme.values.where((theme) {
      if (searchQuery.isEmpty) return true;
      return theme.name.toLowerCase().contains(searchQuery);
    }).toList();

    if (filteredThemes.isEmpty) {
      return _buildNoThemesFound(context);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredThemes.length,
      itemBuilder: (context, index) {
        final appTheme = filteredThemes[index];
        final isSelected = themeProvider.selectedTheme == appTheme;
        final themeData = AppThemes.themeMap[appTheme]!;

        return ThemeCard(
          appTheme: appTheme,
          themeData: themeData,
          isSelected: isSelected,
          onTap: () => themeProvider.setTheme(appTheme),
        );
      },
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
