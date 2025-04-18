import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:msbridge/config/feature_flag.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/core/services/sync/note_taking_sync.dart';
import 'package:msbridge/core/services/sync/reverse_sync.dart';
import 'package:msbridge/features/auth/verify/verify_email.dart';
import 'package:msbridge/features/home/home.dart';
import 'package:msbridge/features/splash/splash_screen.dart';
import 'package:msbridge/widgets/snakbar.dart';

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
              if (FeatureFlag.enableSyncLayer) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  try {
                    final syncService = SyncService();
                    await syncService.startListening();
                  } catch (e) {
                    CustomSnackBar.show(
                      context,
                      "Error starting sync service: $e",
                    );
                  }
                });
              }
              if (FeatureFlag.enableReverseSyncLayer) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  try {
                    final ReverseSyncService reverseSyncService =
                        ReverseSyncService();
                    await reverseSyncService.syncDataFromFirebaseToHive();
                  } catch (e) {
                    CustomSnackBar.show(
                      context,
                      "Error starting sync service: $e",
                    );
                  }
                });
              }

              return const Home();
            }
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
