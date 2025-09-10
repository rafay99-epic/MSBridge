import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/features/auth/verify/verify_email.dart';
import 'package:msbridge/features/home/home.dart';
import 'package:msbridge/features/splash/splash_screen.dart';
import 'package:msbridge/core/permissions/notification_permission.dart';
import 'package:permission_handler/permission_handler.dart';

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
                await NotificationPermissionHandler
                    .checkAndRequestNotificationPermission(context);

                await Permission.photos.request();
                await Permission.storage.request();

                await Permission.camera.request();
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
