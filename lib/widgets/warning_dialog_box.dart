import 'package:flutter/material.dart';

void showConfirmationDialog(BuildContext context, ThemeData theme,
    VoidCallback action, String title, String description, {String confirmButtonText = "Confirm"}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          title,
          style: TextStyle(color: theme.colorScheme.primary),
        ),
        content: Text(
          description,
          style: TextStyle(color: theme.colorScheme.primary),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
            child: const Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
            ),
            child: Text(confirmButtonText),
            onPressed: () {
              Navigator.of(context).pop();
              action();
            },
          ),
        ],
      );
    },
  );
}
