import 'package:flutter/material.dart';

Widget buildExpandableButton({
  required BuildContext context,
  required String heroTag,
  required IconData icon,
  required String text,
  required ThemeData theme,
  required VoidCallback onPressed,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text(
        text,
        style: TextStyle(color: theme.colorScheme.primary),
      ),
      const SizedBox(width: 8),
      FloatingActionButton(
        heroTag: heroTag,
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: theme.colorScheme.surface,
        elevation: 4,
        tooltip: text,
        onPressed: onPressed,
        child: Icon(
          icon,
          size: 25,
        ),
      ),
    ],
  );
}
