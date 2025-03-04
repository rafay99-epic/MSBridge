import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/backend/repo/auth_repo.dart'; // Import your AuthRepo
import 'package:msbridge/frontend/screens/setting/logout/logout_dialog.dart';
import 'package:msbridge/frontend/widgets/snakbar.dart'; // Import CustomSnackBar

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  DeleteAccountScreenState createState() => DeleteAccountScreenState();
}

class DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isLoading = false; // Add loading state

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Delete Account"),
        automaticallyImplyLeading: true,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LineIcons.trash,
              size: 60,
              color: theme.colorScheme.error,
            ),
            Text(
              'Delete Account',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete your account?\nThis action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32), // Adjust padding for larger button
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // Remove rounded corners
                ),
                textStyle: const TextStyle(fontSize: 18), // Make font bigger
              ),
              onPressed: _isLoading ? null : _showConfirmationDialog,
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Account Deletion'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Are you absolutely sure you want to delete your account?'),
                Text(
                    'This action is irreversible and will delete all of your data.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss the dialog
                await _deleteAccount(); // Call the delete function
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    final AuthRepo authRepo = AuthRepo();
    final result = await authRepo.deleteUserAndData();

    setState(() {
      _isLoading = false; // Stop loading
    });

    if (result.isSuccess) {
      // Account deleted successfully - navigate to login or home screen
      CustomSnackBar.show(context, "Account deleted successfully.");

      // Navigate to the login screen
      showLogoutDialog(context);
    } else {
      // Display an error message
      CustomSnackBar.show(context, "Failed to delete account: ${result.error}");
    }
  }
}
