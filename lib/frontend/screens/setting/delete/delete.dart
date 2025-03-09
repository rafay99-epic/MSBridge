import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/backend/repo/auth_repo.dart';
import 'package:msbridge/frontend/screens/setting/logout/logout_dialog.dart';
import 'package:msbridge/frontend/widgets/appbar.dart';
import 'package:msbridge/frontend/widgets/snakbar.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  DeleteAccountScreenState createState() => DeleteAccountScreenState();
}

class DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(title: 'Delete Account'),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                textStyle: const TextStyle(fontSize: 18),
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
      barrierDismissible: false,
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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    final AuthRepo authRepo = AuthRepo();
    final result = await authRepo.deleteUserAndData();

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      CustomSnackBar.show(context, "Account deleted successfully.");

      showLogoutDialog(context);
    } else {
      CustomSnackBar.show(context, "Failed to delete account: ${result.error}");
    }
  }
}
