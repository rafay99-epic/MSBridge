import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/app_pin_lock_provider.dart';
import 'package:msbridge/core/auth/startup_pin_lock_screen.dart';

class AppPinLockWrapper extends StatefulWidget {
  final Widget child;

  const AppPinLockWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AppPinLockWrapper> createState() => _AppPinLockWrapperState();
}

class _AppPinLockWrapperState extends State<AppPinLockWrapper> {
  bool _pinVerified = false;
  bool _isInitialized = false;
  bool _shouldShowPinLock = false;

  @override
  void initState() {
    super.initState();
    _initializePinLock();
  }

  Future<void> _initializePinLock() async {
    try {
      final pinProvider =
          Provider.of<AppPinLockProvider>(context, listen: false);

      final hasPin = await pinProvider.hasPin();

      if (pinProvider.enabled && hasPin) {
        setState(() {
          _shouldShowPinLock = true;
          _isInitialized = true;
        });
      } else {
        setState(() {
          _shouldShowPinLock = false;
          _pinVerified = true;
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _shouldShowPinLock = false;
        _pinVerified = true;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_pinVerified) {
      return widget.child;
    }

    if (_shouldShowPinLock) {
      return StartupPinLockScreen(
        onPinCorrect: () {
          setState(() {
            _pinVerified = true;
          });
        },
      );
    }

    return widget.child;
  }
}
