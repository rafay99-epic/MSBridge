import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:msbridge/config/feature_flag.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/core/services/sync/note_taking_sync.dart';
import 'package:msbridge/core/services/sync/reverse_sync.dart';
import 'package:msbridge/core/services/sync/templates_sync.dart';
import 'package:msbridge/core/services/sync/auto_sync_scheduler.dart';
import 'package:msbridge/core/services/sync/streak_sync_service.dart';
import 'package:msbridge/features/auth/verify/verify_email.dart';
import 'package:msbridge/features/home/home.dart';
import 'package:msbridge/features/splash/splash_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepo();

    return Scaffold(
      body: StreamBuilder<User?>(
        stream: authRepo.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;

            if (user == null) {
              return const SplashScreen();
            } else if (!user.emailVerified) {
              return const EmailVerificationScreen();
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                Future<void>(() async {
                  try {
                    await AutoSyncScheduler.initialize();

                    if (FeatureFlag.enableReverseSyncLayer) {
                      final reverse = ReverseSyncService();
                      await reverse.syncDataFromFirebaseToHive();
                      await TemplatesSyncService().pullTemplatesFromCloud();
                      await StreakSyncService().syncNow();
                    }

                    if (FeatureFlag.enableSyncLayer) {
                      final syncService = SyncService();
                      final templatesSync = TemplatesSyncService();
                      await syncService.startListening();
                      await templatesSync.startListening();
                      await StreakSyncService().pushTodayIfDue();
                    }
                  } catch (e) {
                    FirebaseCrashlytics.instance.recordError(
                      e,
                      StackTrace.current,
                      reason: 'Background startup sync failed',
                    );
                  }
                });
              });

              return const Home();
            }
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
