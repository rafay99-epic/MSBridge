import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showTitle;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBackButtonPressed;
  final bool backbutton;

  const CustomAppBar({
    super.key,
    this.title,
    this.showTitle = true,
    this.showBackButton = false,
    this.actions,
    this.onBackButtonPressed,
    this.backbutton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Guard against conflicting props. We allow either a manual back button
    // (showBackButton) or letting the Navigator decide (backbutton). Having
    // both true can produce duplicated buttons in some routes.
    assert(!(showBackButton && backbutton),
        'Use either showBackButton or backbutton, not both.');

    final bool implyLeading = backbutton && !showBackButton;

    Widget? leading;
    if (showBackButton) {
      leading = IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (onBackButtonPressed != null) {
            onBackButtonPressed!();
          } else {
            Navigator.of(context).pop();
          }
        },
      );
    }

    return AppBar(
      title: showTitle && title != null ? Text(title!) : null,
      automaticallyImplyLeading: implyLeading,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.primary,
      elevation: 1,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.2),
      centerTitle: true,
      leading: leading,
      actions: actions ?? const <Widget>[],
      titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
