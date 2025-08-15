import 'package:flutter/material.dart';

class AppBarWidgets {
  static Widget buildAppBarTitle(ThemeData theme, bool isSearching,
      TextEditingController searchController, FocusNode searchFocusNode) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: isSearching
          ? Container(
              key: const ValueKey('search'),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                autofocus: true,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search settings...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.primary.withOpacity(0.6),
                    fontFamily: 'Poppins',
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.primary.withOpacity(0.6),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (query) {
                  // Search logic will be handled by parent
                },
              ),
            )
          : Text(
              "Settings",
              key: const ValueKey('title'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                fontFamily: 'Poppins',
              ),
            ),
    );
  }

  static Widget? buildAppBarLeading(
      bool isSearching, VoidCallback onExitSearch) {
    return isSearching
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onExitSearch,
            tooltip: 'Exit search',
          )
        : null;
  }

  static List<Widget> buildAppBarActions(
      bool isSearching, VoidCallback onEnterSearch) {
    return [
      if (!isSearching)
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onEnterSearch,
          tooltip: 'Search settings',
        ),
    ];
  }
}
