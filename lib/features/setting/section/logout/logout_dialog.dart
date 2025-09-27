import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/features/splash/splash_screen.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:line_icons/line_icons.dart';

import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Fast parallel clearing of all Hive boxes
Future<void> _clearAllHiveBoxesFast() async {
  // Define all known box names
  const List<String> boxNames = [
    'notesBox',
    'notes',
    'deleted_notes',
    'note_versions',
    'chat_history',
    'note_templates',
  ];

  final List<Future<void>> clearFutures = boxNames.map((boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        await box.clear();
        await box.close();
      }
      if (await Hive.boxExists(boxName)) {
        await Hive.deleteBoxFromDisk(boxName);
      }
    } catch (e, st) {
      FlutterBugfender.error("Failed to clear box '$boxName': $e");
      FlutterBugfender.sendCrash("Hive cleanup error: $e", st.toString());
    }
  }).toList();

  // Execute all clearing operations in parallel
  await Future.wait(clearFutures);
}

/// Clear all secure storage data
Future<void> _clearAllSecureStorage() async {
  try {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
  } catch (e) {
    FlutterBugfender.sendCrash(
        "Failed to clear secure storage: $e", StackTrace.current.toString());
  }
}

void showLogoutDialog(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          minHeight: 200,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and Title Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  LineIcons.alternateSignOut,
                  size: 32,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Confirm Logout",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                "Are you sure you want to log out? This will clear all local data and return you to the login screen.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                  height: 1.4,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: Center(
                            child: Text(
                              "Cancel",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    colorScheme.primary.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Logout Button
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.error,
                            colorScheme.error.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.error.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pop(context);
                            handleLogout(context);
                          },
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LineIcons.alternateSignOut,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Logout",
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void handleLogout(BuildContext context) async {
  final authRepo = AuthRepo();
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  // Enhanced loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 300,
          minHeight: 160,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Loading indicator with custom styling
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.secondary),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Logging out...",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                "Please wait while we secure your data",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: colorScheme.primary.withValues(alpha: 0.6),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  final error = await authRepo.logout();

  if (!context.mounted) return;
  Navigator.pop(context);

  if (error == null) {
    try {
      await _clearAllHiveBoxesFast();
      await _clearAllSecureStorage();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition(
          type: PageTransitionType.leftToRight,
          duration: const Duration(milliseconds: 300),
          child: const SplashScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      FlutterBugfender.sendCrash(
          "Failed to clear data: $e", StackTrace.current.toString());
    }
  } else {
    CustomSnackBar.show(context, "Logout Failed: $error");
    FlutterBugfender.sendCrash(
        "Logout Failed: $error", StackTrace.current.toString());
  }
}
