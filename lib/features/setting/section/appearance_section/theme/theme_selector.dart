import 'package:flutter/material.dart';
import 'package:msbridge/theme/colors.dart';
import 'package:msbridge/core/provider/theme_provider.dart';

class ThemeSelector extends StatefulWidget {
  const ThemeSelector({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  State<ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<ThemeSelector> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Header with Expand/Collapse
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.palette,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "Choose Your Theme",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                "${AppTheme.values.length} themes",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Theme Display (Compact or Expanded)
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: _buildCompactThemeView(),
          secondChild: _buildExpandedThemeView(),
        ),

        // Quick Theme Info
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _isExpanded
                ? "Browse all themes in detail. Tap any theme to apply instantly."
                : "Tap any theme to apply instantly. Tap the expand button to see more details.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactThemeView() {
    return SizedBox(
      height: 120, // Much more compact height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: AppTheme.values.length,
        itemBuilder: (context, index) {
          final appTheme = AppTheme.values[index];
          final isSelected = widget.themeProvider.selectedTheme == appTheme;
          final themeData = AppThemes.themeMap[appTheme]!;

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildCompactThemeCard(
              context,
              appTheme,
              themeData,
              isSelected,
              () => widget.themeProvider.setTheme(appTheme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandedThemeView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        final itemWidth = (constraints.maxWidth - 16) / crossAxisCount;
        final itemHeight = itemWidth * 1.1;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: AppTheme.values.map((appTheme) {
            final isSelected = widget.themeProvider.selectedTheme == appTheme;
            final themeData = AppThemes.themeMap[appTheme]!;

            return SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _buildExpandedThemeCard(
                context,
                appTheme,
                themeData,
                isSelected,
                () => widget.themeProvider.setTheme(appTheme),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCompactThemeCard(
    BuildContext context,
    AppTheme appTheme,
    ThemeData themeData,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final selectedTheme = Theme.of(context);
    final currentColorScheme = selectedTheme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140, // Fixed width for consistency
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? currentColorScheme.primary
                : currentColorScheme.outline.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? currentColorScheme.primary.withOpacity(0.3)
                  : currentColorScheme.shadow.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Theme Preview Background
              Container(
                decoration: BoxDecoration(
                  gradient: _getThemeGradient(appTheme),
                ),
              ),

              // Content Overlay
              Container(
                decoration: BoxDecoration(
                  color: currentColorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Theme Icon and Name Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: themeData.colorScheme.primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getThemeIcon(appTheme),
                              size: 16,
                              color: themeData.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              appTheme.name,
                              style:
                                  selectedTheme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: currentColorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Color Preview Dots
                      Row(
                        children: [
                          _buildCompactColorDot(themeData.colorScheme.primary),
                          const SizedBox(width: 4),
                          _buildCompactColorDot(
                              themeData.colorScheme.secondary),
                          const SizedBox(width: 4),
                          _buildCompactColorDot(themeData.colorScheme.surface),
                        ],
                      ),

                      const Spacer(),

                      // Selection Indicator
                      if (isSelected)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: currentColorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check,
                                size: 12,
                                color: currentColorScheme.onPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Active',
                                style:
                                    selectedTheme.textTheme.bodySmall?.copyWith(
                                  color: currentColorScheme.onPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedThemeCard(
    BuildContext context,
    AppTheme appTheme,
    ThemeData themeData,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final selectedTheme = Theme.of(context);
    final currentColorScheme = selectedTheme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity, // Expanded to full width
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? currentColorScheme.primary
                : currentColorScheme.outline.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? currentColorScheme.primary.withOpacity(0.3)
                  : currentColorScheme.shadow.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Theme Preview Background
              Container(
                decoration: BoxDecoration(
                  gradient: _getThemeGradient(appTheme),
                ),
              ),

              // Content Overlay
              Container(
                decoration: BoxDecoration(
                  color: currentColorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Theme Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeData.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getThemeIcon(appTheme),
                          size: 20,
                          color: themeData.colorScheme.primary,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Theme Name
                      Text(
                        appTheme.name,
                        style: selectedTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: currentColorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Color Preview
                      Row(
                        children: [
                          _buildExpandedColorDot(themeData.colorScheme.primary),
                          const SizedBox(width: 4),
                          _buildExpandedColorDot(
                              themeData.colorScheme.secondary),
                          const SizedBox(width: 4),
                          _buildExpandedColorDot(themeData.colorScheme.surface),
                        ],
                      ),

                      const Spacer(),

                      // Selection Indicator
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: currentColorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check,
                                size: 14,
                                color: currentColorScheme.onPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Active',
                                style:
                                    selectedTheme.textTheme.bodySmall?.copyWith(
                                  color: currentColorScheme.onPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactColorDot(Color color) {
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
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedColorDot(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  LinearGradient _getThemeGradient(AppTheme appTheme) {
    switch (appTheme) {
      case AppTheme.cyberDark:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8BE9FD), Color(0xFFFF79C6), Color(0xFFBD93F9)],
        );
      case AppTheme.neonPunk:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00FF88), Color(0xFFFF0080), Color(0xFF00F5FF)],
        );
      case AppTheme.auroraBorealis:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00D4FF), Color(0xFF00FFB3), Color(0xFF9D4EDD)],
        );
      case AppTheme.cosmicVoid:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9D4EDD), Color(0xFFE0AAFF), Color(0xFF7B2CBF)],
        );
      case AppTheme.electricBlue:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00F5FF), Color(0xFF0099CC), Color(0xFF001122)],
        );
      case AppTheme.goldenHour:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B35), Color(0xFFFFD93D), Color(0xFFFF79C6)],
        );
      case AppTheme.midnightPurple:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B2CBF), Color(0xFFC77DFF), Color(0xFF240046)],
        );
      case AppTheme.tropicalParadise:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00B894), Color(0xFF00CEC9), Color(0xFFE8F5E8)],
        );
      case AppTheme.arcticFrost:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF74B9FF), Color(0xFFA29BFE), Color(0xFFF0F8FF)],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemes.themeMap[appTheme]!.colorScheme.primary,
            AppThemes.themeMap[appTheme]!.colorScheme.secondary,
            AppThemes.themeMap[appTheme]!.colorScheme.surface,
          ],
        );
    }
  }

  IconData _getThemeIcon(AppTheme appTheme) {
    switch (appTheme) {
      case AppTheme.light:
        return Icons.light_mode;
      case AppTheme.dark:
        return Icons.dark_mode;
      case AppTheme.cyberDark:
        return Icons.psychology;
      case AppTheme.neonPunk:
        return Icons.electric_bolt;
      case AppTheme.auroraBorealis:
        return Icons.nights_stay;
      case AppTheme.cosmicVoid:
        return Icons.space_bar;
      case AppTheme.electricBlue:
        return Icons.flash_on;
      case AppTheme.goldenHour:
        return Icons.wb_sunny;
      case AppTheme.midnightPurple:
        return Icons.nightlife;
      case AppTheme.tropicalParadise:
        return Icons.park;
      case AppTheme.arcticFrost:
        return Icons.ac_unit;
      default:
        return Icons.palette;
    }
  }
}
