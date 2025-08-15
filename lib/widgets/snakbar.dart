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
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Container(
        constraints: const BoxConstraints(
          minHeight: 56,
          maxWidth: 400, // Limit maximum width for better proportions
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
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
              // Success/Error Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSuccessMessage
                      ? colorScheme.onPrimary.withOpacity(0.15)
                      : colorScheme.onErrorContainer.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSuccessMessage
                      ? LineIcons.checkCircle
                      : LineIcons.exclamationTriangle,
                  color: iconColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 16),

              // Message Text - Centered and properly sized
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.2,
                    letterSpacing: 0.2,
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
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSuccessMessage
                          ? colorScheme.onPrimary.withOpacity(0.15)
                          : colorScheme.onErrorContainer.withOpacity(0.15),
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
