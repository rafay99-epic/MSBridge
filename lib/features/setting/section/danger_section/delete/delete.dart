import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/features/setting/section/logout/logout_dialog.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';

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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: 'Delete Account',
        backbutton: true,
      ),
      body: CustomScrollView(
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: _buildHeaderSection(context, colorScheme, theme),
          ),

          // Warning Section
          SliverToBoxAdapter(
            child: _buildWarningSection(context, colorScheme, theme),
          ),

          // Action Section
          SliverToBoxAdapter(
            child: _buildActionSection(context, colorScheme, theme),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.error.withOpacity(0.05),
            colorScheme.error.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Warning Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LineIcons.trash,
              size: 48,
              color: colorScheme.error,
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            "Delete Account",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Subtitle
          Text(
            "This action will permanently remove your account and all associated data.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.error.withOpacity(0.8),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWarningSection(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning Header
          Row(
            children: [
              Icon(
                LineIcons.exclamationTriangle,
                color: colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "What will be deleted:",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Warning Items
          _buildWarningItem(
            context,
            "All your notes and data",
            LineIcons.stickyNote,
            colorScheme,
          ),
          _buildWarningItem(
            context,
            "Account settings and preferences",
            LineIcons.cog,
            colorScheme,
          ),
          _buildWarningItem(
            context,
            "Shared notes and collaborations",
            LineIcons.share,
            colorScheme,
          ),
          _buildWarningItem(
            context,
            "This action cannot be undone",
            LineIcons.ban,
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(BuildContext context, String text, IconData icon,
      ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colorScheme.error.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Delete Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _showConfirmationDialog,
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colorScheme.onError),
                      ),
                    )
                  : Icon(LineIcons.trash, size: 20),
              label: Text(
                _isLoading ? 'Deleting...' : 'Delete Account',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: colorScheme.error.withOpacity(0.3),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Cancel Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Cancel',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LineIcons.exclamationTriangle,
                  color: colorScheme.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Final Confirmation',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you absolutely sure you want to delete your account?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This action is irreversible and will permanently delete all of your data, notes, and account information.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary.withOpacity(0.7),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.primary),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Delete Permanently'),
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
    // Step 1: Wipe local storage (Hive boxes + SharedPreferences handled in logout)
    try {
      // Clear note boxes
      try {
        final box = await HiveNoteTakingRepo.getBox();
        await box.clear();
      } catch (_) {}
      try {
        final deletedBox = await HiveNoteTakingRepo.getDeletedBox();
        await deletedBox.clear();
      } catch (_) {}

      // Additionally clear any other Hive boxes registered in main.dart
      try {
        if (Hive.isBoxOpen('notesBox')) {
          await Hive.box('notesBox').clear();
        }
      } catch (_) {}
    } catch (_) {}

    // Step 2: Delete all user docs and auth user
    final result = await authRepo.deleteUserAndData();

    setState(() {
      _isLoading = false;
    });

    if (result.error == null) {
      CustomSnackBar.show(context, "Account deleted successfully.");

      showLogoutDialog(context);
    } else {
      CustomSnackBar.show(context, "Failed to delete account: ${result.error}");
    }
  }
}
