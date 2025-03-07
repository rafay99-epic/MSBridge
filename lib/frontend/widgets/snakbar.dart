import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show(
    BuildContext context,
    String message, {
    bool? isSuccess,
  }) {
    final snackBar = SnackBar(
      closeIconColor: Colors.red,
      showCloseIcon: true,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isSuccess == true
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surface,
      behavior: SnackBarBehavior.floating,
      elevation: 6.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 5),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
