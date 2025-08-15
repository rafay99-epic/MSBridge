import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/features/setting/pages/app_info_page.dart';
import 'package:msbridge/features/setting/section/appearance_section/appearance_settings_page.dart';
import 'package:msbridge/features/update_app/update_app.dart';
import 'package:msbridge/features/profile/profile_edit_page.dart';
import 'package:msbridge/features/ai_chat/chat_page.dart';
import 'package:msbridge/core/services/sync/note_taking_sync.dart';
import 'package:msbridge/core/services/backup_service.dart';
import 'package:msbridge/features/notes_taking/recyclebin/recycle.dart';
import 'package:msbridge/core/services/sync/reverse_sync.dart';
import 'package:msbridge/core/services/sync/auto_sync_scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:msbridge/features/setting/widgets/bottom_sheet_widgets.dart';

class NavigationMethods {
  static void navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: const ProfileEditPage(),
      ),
    );
  }

  static void navigateToSecurity(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          BottomSheetWidgets.buildSecurityBottomSheet(context),
    );
  }

  static void navigateToAppearance(BuildContext context) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: const AppearanceSettingsPage(),
      ),
    );
  }

  static void navigateToNotesSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomSheetWidgets.buildNotesBottomSheet(context),
    );
  }

  static void navigateToSyncSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomSheetWidgets.buildSyncBottomSheet(context),
    );
  }

  static void navigateToDataManagement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          BottomSheetWidgets.buildDataManagementBottomSheet(context),
    );
  }

  static void navigateToUpdateApp(BuildContext context) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: const UpdateApp(),
      ),
    );
  }

  static void navigateToAppInfo(BuildContext context) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: const AppInfoPage(),
      ),
    );
  }

  static void navigateToAI(BuildContext context) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: const ChatAssistantPage(),
      ),
    );
  }

  static void navigateToAISmartFeatures(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          BottomSheetWidgets.buildAISmartFeaturesBottomSheet(context),
    );
  }

  static void syncNow(BuildContext context) async {
    try {
      await SyncService().syncLocalNotesToFirebase();
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          'Synced successfully',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          'Sync failed: $e',
          isSuccess: false,
        );
      }
    }
  }

  static void createBackup(BuildContext context) async {
    try {
      final filePath = await BackupService.exportAllNotes(context);
      if (context.mounted) {
        final detailedLocation =
            BackupService.getDetailedFileLocation(filePath);
        CustomSnackBar.show(
          context,
          'Backup exported successfully to $detailedLocation',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          'Backup failed: $e',
          isSuccess: false,
        );
      }
    }
  }

  static void navigateToDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: const Text('Delete Account'),
          content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete')),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final auth = FirebaseAuth.instance;
        await auth.currentUser?.delete();
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            'Account deleted successfully. We are sorry to see you go.',
            isSuccess: true,
          );
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } catch (e) {
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            'Failed to delete account: $e',
            isSuccess: false,
          );
        }
      }
    }
  }

  static void navigateToResetTheme(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: const Text('Reset App Theme'),
          content: const Text(
              'Are you sure you want to reset your app theme to the default? This will remove any custom theme settings.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Reset')),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        themeProvider.resetTheme();
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            'App theme reset to default.',
            isSuccess: true,
          );
        }
      } catch (e) {
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            'Failed to reset theme: $e',
            isSuccess: false,
          );
        }
      }
    }
  }

  static void navigateToTinaCMS(BuildContext context) {
    CustomSnackBar.show(context, 'Tina CMS is under development.',
        isSuccess: false);
  }

  static void navigateToPageCMS(BuildContext context) {
    CustomSnackBar.show(context, 'Page CMS is under development.',
        isSuccess: false);
  }

  static void navigateToContactMessages(BuildContext context) {
    CustomSnackBar.show(context, 'Contact Messages is under development.',
        isSuccess: false);
  }
}
