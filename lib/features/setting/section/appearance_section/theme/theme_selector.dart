import 'package:flutter/material.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'widgets/theme_header.dart';
import 'widgets/dynamic_colors_toggle.dart';
import 'widgets/theme_search_bar.dart';
import 'widgets/theme_grid.dart';
import 'widgets/dynamic_colors_message.dart';

class ThemeSelector extends StatefulWidget {
  const ThemeSelector({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  State<ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<ThemeSelector> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const ThemeHeader(),

        // Dynamic Colors Toggle
        DynamicColorsToggle(themeProvider: widget.themeProvider),

        // Search Bar
        if (!widget.themeProvider.dynamicColorsEnabled)
          ThemeSearchBar(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            onClearSearch: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
          ),

        // Theme Grid or Dynamic Colors Message
        if (!widget.themeProvider.dynamicColorsEnabled) ...[
          const SizedBox(height: 16),
          ThemeGrid(
            searchQuery: _searchQuery,
            themeProvider: widget.themeProvider,
          ),
        ] else ...[
          const DynamicColorsMessage(),
        ],
      ],
    );
  }
}
