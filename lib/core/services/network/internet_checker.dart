import 'dart:async';
import 'package:flutter/material.dart';
import 'package:msbridge/core/provider/notes_api_provider.dart';
import 'package:msbridge/core/repo/auth_gate.dart';
import 'package:msbridge/core/services/network/internet_helper.dart';
import 'package:msbridge/features/offline/offline.dart';
import 'package:msbridge/widgets/snakbar.dart';

class InternetChecker extends StatefulWidget {
  const InternetChecker({super.key});

  @override
  State<InternetChecker> createState() => _InternetCheckerState();
}

class _InternetCheckerState extends State<InternetChecker> {
  bool _isConnected = false;
  Timer? _offlineTimer;
  final InternetHelper _internetHelper = InternetHelper();

  @override
  void initState() {
    super.initState();

    _checkInitialConnection();

    _internetHelper.connectivitySubject.listen((connected) {
      if (_isConnected != connected && mounted) {
        setState(() {
          _isConnected = connected;
        });

        if (connected) {
          _handleOnline();
        } else {
          _handleOffline();
        }
      }
    });
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

  void _handleOnline() async {
    debugPrint("✅ Internet Reconnected");
    _offlineTimer?.cancel();
    NotesProvider().fetchNotes();

    await Future.delayed(const Duration(seconds: 2));

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthGate(),
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

    if (mounted) {
      CustomSnackBar.show(
          context, "Hooray! You are back online.");
    }
  }

  void _handleOffline() {
    debugPrint("❌ No Internet");
    CustomSnackBar.show(context, "Internet Lost ❌");

    _offlineTimer = Timer(const Duration(seconds: 40), () async {
      if (_isConnected == false && mounted) {
        await Future.delayed(const Duration(seconds: 2));
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OfflineHome(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isConnected == true ? const AuthGate() : const OfflineHome(),
    );
  }

  @override
  void dispose() {
    _offlineTimer?.cancel();
    _internetHelper.dispose();
    super.dispose();
  }
}
