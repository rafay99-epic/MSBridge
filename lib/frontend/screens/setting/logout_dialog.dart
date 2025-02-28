import 'package:flutter/material.dart';
import 'package:msbridge/backend/repo/auth_repo.dart';
import 'package:msbridge/frontend/screens/auth/login.dart';
import 'package:provider/provider.dart';

void showLogoutDialog(BuildContext context) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(), // No rounded corners
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Confirm Logout",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Are you sure you want to log out?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.primary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "No",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleLogout(context);
                  },
                  child: Text(
                    "Yes",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Handles logout
void _handleLogout(BuildContext context) async {
  final authRepo = Provider.of<AuthRepo>(context, listen: false);

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  final error = await authRepo.logout();

  Navigator.pop(context); // Close loading dialog

  if (error == null) {
    // ✅ Success: Navigate to Login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  } else {
    // ❌ Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Logout Failed: $error",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
