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

    return AppBar(
      title: showTitle && title != null ? Text(title!) : null,
      automaticallyImplyLeading: backbutton,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.primary,
      elevation: 1,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (onBackButtonPressed != null) {
                  onBackButtonPressed!();
                } else {
                  Navigator.of(context).pop();
                }
              },
            )
          : null,
      actions: actions,
      titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
