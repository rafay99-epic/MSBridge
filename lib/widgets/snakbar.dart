import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

class CustomSnackBar {
  static void show(
    BuildContext context,
    String message, {
    bool? isSuccess,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine colors based on success state
    final isSuccessMessage = isSuccess == true;
    final backgroundColor = isSuccessMessage
        ? colorScheme.primary.withOpacity(0.95)
        : colorScheme.errorContainer.withOpacity(0.95);

    final textColor =
        isSuccessMessage ? colorScheme.onPrimary : colorScheme.onErrorContainer;

    final iconColor =
        isSuccessMessage ? colorScheme.onPrimary : colorScheme.onErrorContainer;

    final borderColor =
        isSuccessMessage ? colorScheme.primary : colorScheme.error;

    final snackBar = SnackBar(
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isSuccessMessage ? colorScheme.primary : colorScheme.error)
                      .withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Success/Error Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSuccessMessage
                      ? colorScheme.onPrimary.withOpacity(0.2)
                      : colorScheme.onErrorContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSuccessMessage
                      ? LineIcons.checkCircle
                      : LineIcons.exclamationTriangle,
                  color: iconColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 16),

              // Message Text
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Close Button
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSuccessMessage
                        ? colorScheme.onPrimary.withOpacity(0.2)
                        : colorScheme.onErrorContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LineIcons.times,
                    color: iconColor,
                    size: 18,
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
