import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/core/services/network/internet_helper.dart';
import 'package:msbridge/features/auth/verify/verify_email.dart';
import 'package:msbridge/features/home/home.dart';
import 'package:msbridge/features/offline/offline.dart';
import 'package:msbridge/features/splash/splash_screen.dart';
import 'package:msbridge/widgets/snakbar.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final InternetHelper _internetHelper = InternetHelper();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();

    _internetHelper.connectivitySubject.listen((connected) {
      if (_isConnected != connected && mounted) {
        setState(() {
          _isConnected = connected;
        });

        if (!connected) {
          _handleOffline();
        }
      }
    });

    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    await _internetHelper.checkInternet();
    bool initialConnection = _internetHelper.connectivitySubject.value;
    if (mounted) {
      setState(() {
        _isConnected = initialConnection;
      });
    }
  }

  void _handleOffline() async {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OfflineHome(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var fadeAnimation = animation.drive(tween);

          return FadeTransition(
            opacity: fadeAnimation,
            child: child,
          );
        },
      ),
    );

    CustomSnackBar.show(context, "Sorry! Internet is offline");
  }

  @override
  void dispose() {
    _internetHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepo();

    return Scaffold(
      body: StreamBuilder<User?>(
        stream: authRepo.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data;

            if (user == null) {
              return const SplashScreen();
            } else if (!user.emailVerified) {
              return const EmailVerificationScreen();
            } else {
              return const Home();
            }
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
