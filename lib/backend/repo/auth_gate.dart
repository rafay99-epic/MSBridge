import 'package:flutter/material.dart';
import 'package:msbridge/backend/repo/auth_repo.dart';
import 'package:msbridge/frontend/screens/auth/verify_email.dart';
import 'package:msbridge/frontend/screens/home/home.dart';
import 'package:msbridge/frontend/screens/splash/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepo();

    return StreamBuilder<User?>(
      stream: authRepo.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'An error occurred, please try again later.',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const AuthGate())),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const SplashScreen();
        }

        // 🔹 Check if email is verified before allowing access to home
        return FutureBuilder<bool>(
          future: authRepo.isEmailVerified(),
          builder: (context, verificationSnapshot) {
            if (verificationSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (verificationSnapshot.hasData &&
                verificationSnapshot.data == true) {
              return const Home();
            } else {
              return const EmailVerificationScreen();
            }
          },
        );
      },
    );
  }
}
