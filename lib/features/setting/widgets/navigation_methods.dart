import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/features/setting/section/app_info/app_info_page.dart';
import 'package:msbridge/features/setting/section/streak_section/streak_settings_page.dart';
import 'package:msbridge/features/update_app/update_app.dart';

import 'package:msbridge/features/ai_chat/chat_page.dart';
import 'package:msbridge/core/services/sync/note_taking_sync.dart';
import 'package:msbridge/core/services/sync/reverse_sync.dart';
import 'package:msbridge/core/services/backup/backup_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:msbridge/features/setting/bottom_sheets/bottom_sheet_manager.dart';
import 'package:msbridge/features/setting/section/logout/logout_dialog.dart';

class NavigationMethods {
  static void navigateToProfile(BuildContext context) {
    BottomSheetManager.showProfileManagementBottomSheet(context);
  }

  static void navigateToSecurity(BuildContext context) {
    BottomSheetManager.showSecurityBottomSheet(context);
  }

  static void navigateToAppearance(BuildContext context) {
    BottomSheetManager.showAppearanceBottomSheet(context);
  }

  static void navigateToNotesSettings(BuildContext context) {
    BottomSheetManager.showNotesBottomSheet(context);
  }

  static void navigateToSyncSettings(BuildContext context) {
    BottomSheetManager.showSyncBottomSheet(context);
  }

  static void navigateToTemplatesSettings(BuildContext context) {
    BottomSheetManager.showTemplatesBottomSheet(context);
  }

  static void navigateToDataManagement(BuildContext context) {
    BottomSheetManager.showDataManagementBottomSheet(context);
  }

  static void navigateToStreakSettings(BuildContext context) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: const StreakSettingsPage(),
      ),
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
    BottomSheetManager.showAIFeaturesBottomSheet(context);
  }

  static Future<void> syncNow(BuildContext context) async {
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
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to sync notes: $e',
      );
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          'Sync failed: $e',
          isSuccess: false,
        );
      }
      rethrow;
    }
  }

  static Future<void> pullFromCloud(BuildContext context) async {
    try {
      // Pull data from cloud
      await ReverseSyncService().syncDataFromFirebaseToHive();

      // Force refresh the notes list
      await ReverseSyncService().refreshNotesList();

      // Get count after pulling
      final afterCount = await ReverseSyncService().getCloudNotesCount();

      if (context.mounted) {
        if (afterCount > 0) {
          CustomSnackBar.show(
            context,
            'Notes pulled from cloud successfully',
            isSuccess: true,
          );
        } else {
          CustomSnackBar.show(
            context,
            'No notes found in cloud',
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to pull from cloud: $e',
      );
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          'Pull from cloud failed: $e',
          isSuccess: false,
        );
      }
      rethrow;
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
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Backup failed: $e',
      );
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
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'Failed to delete account: $e',
        );
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
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'Failed to reset theme: $e',
        );
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

  static void logoutUser(BuildContext context) {
    showLogoutDialog(context);
  }

  static void navigateToBackgroundSync(BuildContext context) {
    BottomSheetManager.showBackgroundSyncBottomSheet(context);
  }
}
