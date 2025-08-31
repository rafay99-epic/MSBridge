import 'package:flutter/material.dart';
import 'package:msbridge/config/feature_flag.dart';
import 'package:msbridge/core/provider/lock_app/app_pin_lock_provider.dart';
import 'package:msbridge/core/provider/lock_app/fingerprint_provider.dart';
import 'package:msbridge/core/repo/auth_gate.dart';
import 'package:msbridge/core/wrapper/finger_print_wrapper.dart';
import 'package:msbridge/core/wrapper/pin_wrapper.dart';
import 'package:provider/provider.dart';

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper>
    with WidgetsBindingObserver {
  AuthMethod? _currentAuthMethod;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _determineAuthMethod();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App came back from background, re-check authentication
      _determineAuthMethod();
    }
  }

  Future<void> _determineAuthMethod() async {
    if (!mounted) return;

    try {
      final pinProvider =
          Provider.of<AppPinLockProvider>(context, listen: false);
      final fingerprintProvider =
          Provider.of<FingerprintAuthProvider>(context, listen: false);

      // Refresh states to ensure they're up-to-date
      await pinProvider.refreshPinLockState();
      await fingerprintProvider.refreshFingerprintState();

      AuthMethod newAuthMethod;

      // Priority: Fingerprint > PIN > None
      if (FeatureFlag.enableFingerprintLock &&
          fingerprintProvider.isFingerprintEnabled) {
        newAuthMethod = AuthMethod.fingerprint;
      } else if (pinProvider.enabled && await pinProvider.hasPin()) {
        newAuthMethod = AuthMethod.pin;
      } else {
        newAuthMethod = AuthMethod.none;
      }

      if (mounted) {
        setState(() {
          _currentAuthMethod = newAuthMethod;
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAuthMethod = AuthMethod.none;
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _currentAuthMethod == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.secondary,
            ),
            strokeWidth: 3,
          ),
        ),
      );
    }

    switch (_currentAuthMethod!) {
      case AuthMethod.fingerprint:
        return const FingerprintAuthWrapper(child: AuthGate());
      case AuthMethod.pin:
        return const AppPinLockWrapper(child: AuthGate());
      case AuthMethod.none:
        return const AuthGate();
    }
  }
}

enum AuthMethod { fingerprint, pin, none }
