import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

enum SnackBarType {
  success,
  error,
  info,
  warning,
}

class CustomSnackBar {
  static void show(
    BuildContext context,
    String message,
    SnackBarType type,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine colors based on type
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    Color borderColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = colorScheme.primary.withValues(alpha: 0.95);
        textColor = colorScheme.onPrimary;
        iconColor = colorScheme.onPrimary;
        borderColor = colorScheme.primary;
        icon = LineIcons.checkCircle;
        break;
      case SnackBarType.error:
        backgroundColor = colorScheme.errorContainer.withValues(alpha: 0.95);
        textColor = colorScheme.onErrorContainer;
        iconColor = colorScheme.onErrorContainer;
        borderColor = colorScheme.error;
        icon = LineIcons.exclamationTriangle;
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.orange.withValues(alpha: 0.95);
        textColor = Colors.white;
        iconColor = Colors.white;
        borderColor = Colors.orange;
        icon = LineIcons.exclamationCircle;
        break;
      case SnackBarType.info:
        backgroundColor = colorScheme.secondary.withValues(alpha: 0.95);
        textColor = colorScheme.onSecondary;
        iconColor = colorScheme.onSecondary;
        borderColor = colorScheme.secondary;
        icon = LineIcons.infoCircle;
        break;
    }

    final snackBar = SnackBar(
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Container(
        constraints: const BoxConstraints(
          minHeight: 56,
          maxWidth: 400,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 16),

              // Message Text
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.2,
                    letterSpacing: 0.2,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 16),

              // Close Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LineIcons.times,
                      color: iconColor,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
