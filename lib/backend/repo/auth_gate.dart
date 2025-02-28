import 'package:flutter/material.dart';
import 'package:msbridge/backend/repo/auth_repo.dart';
import 'package:msbridge/frontend/screens/home/home.dart';
import 'package:msbridge/frontend/screens/splash/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:appwrite/models.dart' as models;

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<AuthRepo>(context, listen: false);

    return StreamBuilder<models.User?>(
      stream: authRepo.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user != null) {
          return const Home();
        } else {
          return const SplashScreen();
        }
      },
    );
  }
}
