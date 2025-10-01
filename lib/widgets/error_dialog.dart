// Flutter imports:
import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String message;

  const ErrorDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        "Error",
        style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: theme.primary),
      ),
      content: Text(
        message,
        style: TextStyle(
            fontSize: 16, color: theme.primary.withValues(alpha: 0.8)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Close",
            style:
                TextStyle(color: theme.secondary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
