import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/theme/colors.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({
    super.key,
    required this.themeProvider,
  });

  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int buttonsPerRow =
            (constraints.maxWidth / 75).floor().clamp(1, 5);
        return Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8.0,
            runSpacing: 8.0,
            children: AppTheme.values.map((theme) {
              return SizedBox(
                width: (constraints.maxWidth / buttonsPerRow) - 8.0,
                child: _buildThemeButton(theme, themeProvider, context),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildThemeButton(
      AppTheme theme, ThemeProvider themeProvider, BuildContext context) {
    final isSelected = theme == themeProvider.selectedTheme;

    Map<AppTheme, Map<String, dynamic>> themeStyles = {
      AppTheme.light: {
        "background": Colors.white,
        "icon": Icons.wb_sunny,
        "tooltip": "Light Theme",
        "iconColor": Colors.black
      },
      AppTheme.dark: {
        "background": Colors.black,
        "icon": Icons.nightlight_round,
        "tooltip": "Dark Theme",
        "iconColor": Colors.white
      },
      AppTheme.purpleHaze: {
        "background": Colors.deepPurple.shade400,
        "icon": Icons.blur_on,
        "tooltip": "Purple Haze",
        "iconColor": Colors.white
      },
      AppTheme.mintFresh: {
        "background": Colors.greenAccent.shade400,
        "icon": Icons.spa,
        "tooltip": "Mint Fresh",
        "iconColor": Colors.black
      },
      AppTheme.midnightBlue: {
        "background": Colors.indigo.shade900,
        "icon": Icons.nightlight,
        "tooltip": "Midnight Blue",
        "iconColor": Colors.white
      },
      AppTheme.crimsonBlush: {
        "background": Colors.pink.shade400,
        "icon": Icons.favorite,
        "tooltip": "Crimson Blush",
        "iconColor": Colors.white
      },
      AppTheme.forestGreen: {
        "background": Colors.green.shade700,
        "icon": Icons.park,
        "tooltip": "Forest Green",
        "iconColor": Colors.white
      },
      AppTheme.oceanWave: {
        "background": Colors.blue.shade400,
        "icon": Icons.waves,
        "tooltip": "Ocean Wave",
        "iconColor": Colors.white
      },
      AppTheme.sunsetGlow: {
        "background": Colors.orangeAccent.shade400,
        "icon": Icons.wb_twilight,
        "tooltip": "Sunset Glow",
        "iconColor": Colors.black
      },
    };

    return Tooltip(
      message: themeStyles[theme]!['tooltip'],
      child: GestureDetector(
        onTap: () {
          themeProvider.setTheme(theme);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: themeStyles[theme]!['background'],
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary, width: 2.0)
                : null,
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
            ],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  themeStyles[theme]!['icon'],
                  color: themeStyles[theme]!['iconColor'],
                  size: 28.0,
                ),
                if (isSelected)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Icon(
                      LineIcons.checkCircle,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
