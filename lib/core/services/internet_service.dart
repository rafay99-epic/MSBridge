import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:msbridge/core/provider/notes_api_provider.dart';
import 'package:msbridge/core/repo/auth_gate.dart';
import 'package:msbridge/features/offline/offline.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:rxdart/rxdart.dart';

class InternetChecker extends StatefulWidget {
  const InternetChecker({super.key});

  @override
  State<InternetChecker> createState() => _InternetCheckerState();
}

class _InternetCheckerState extends State<InternetChecker> {
  bool? _isConnected;
  Timer? _timer;
  Timer? _offlineTimer;
  final BehaviorSubject<bool> _connectivitySubject = BehaviorSubject<bool>();

  @override
  void initState() {
    super.initState();
    _startChecking();
  }

  void _startChecking() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkInternet();
    });
    _checkInternet();

    _connectivitySubject
        .debounceTime(const Duration(seconds: 2))
        .listen((connected) {
      if (_isConnected != connected && mounted) {
        setState(() {
          _isConnected = connected;
        });

        if (connected) {
          debugPrint("✅ Internet Reconnected");
          _offlineTimer?.cancel();
          NotesProvider().fetchNotes();
        } else {
          debugPrint("❌ No Internet");
          CustomSnackBar.show(context, "Internet Lost ❌");

          _offlineTimer = Timer(const Duration(seconds: 40), () {
            if (_isConnected == false && mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const OfflineScreen()),
                (route) => false,
              );
            }
          });
        }
      }
    });
  }

  Future<void> _checkInternet() async {
    var result = await Connectivity().checkConnectivity();
    bool connected = result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi);
    _connectivitySubject.add(connected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isConnected == true
          ? const AuthGate()
          : _isConnected == false
              ? const OfflineScreen()
              : const SizedBox.shrink(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _offlineTimer?.cancel();
    _connectivitySubject.close();
    super.dispose();
  }
}
