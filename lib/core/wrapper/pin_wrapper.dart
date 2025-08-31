import 'package:flutter/material.dart';
import 'package:msbridge/core/repo/auth_gate.dart';
import 'package:msbridge/core/wrapper/finger_print_wrapper.dart';
import 'package:msbridge/features/lock/verify_pin/startup_pin_lock_screen.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/lock_app/app_pin_lock_provider.dart';
import 'package:msbridge/core/provider/lock_app/fingerprint_provider.dart';

class AppPinLockWrapper extends StatefulWidget {
  final Widget child;

  const AppPinLockWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AppPinLockWrapper> createState() => _AppPinLockWrapperState();
}

class _AppPinLockWrapperState extends State<AppPinLockWrapper>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _pinVerified = false;
  bool _isInitialized = false;
  bool _shouldShowPinLock = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializePinLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _checkAuthenticationRequired();
    } else if (state == AppLifecycleState.paused) {
      // App going to background, mark that we were in background
      Provider.of<AppPinLockProvider>(context, listen: false);
      // The provider already tracks this internally
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _initializePinLock() async {
    try {
      final pinProvider =
          Provider.of<AppPinLockProvider>(context, listen: false);

      // Listen to PIN provider changes
      pinProvider.addListener(_onPinProviderChanged);

      await _checkAuthenticationRequired();
    } catch (e) {
      if (mounted) {
        setState(() {
          _shouldShowPinLock = false;
          _pinVerified = true;
          _isInitialized = true;
        });
        _fadeController.forward();
      }
    }
  }

  Future<void> _checkAuthenticationRequired() async {
    if (!mounted) return;

    try {
      final pinProvider =
          Provider.of<AppPinLockProvider>(context, listen: false);

      // Refresh state
      await pinProvider.refreshPinLockState();

      final hasPin = await pinProvider.hasPin();

      if (pinProvider.enabled && hasPin) {
        // Always show PIN lock when PIN is enabled (WhatsApp behavior)
        bool shouldShowLock = true; // Always show for PIN

        if (mounted) {
          setState(() {
            _shouldShowPinLock = shouldShowLock;
            _pinVerified = !shouldShowLock;
            _isInitialized = true;
          });
        }
      } else {
        // Check if fingerprint is enabled as fallback
        final fingerprintProvider =
            Provider.of<FingerprintAuthProvider>(context, listen: false);
        await fingerprintProvider.refreshFingerprintState();

        if (fingerprintProvider.isFingerprintEnabled) {
          // Switch to fingerprint authentication
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const FingerprintAuthWrapper(child: AuthGate()),
                ),
              );
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _shouldShowPinLock = false;
              _pinVerified = true;
              _isInitialized = true;
            });
            _fadeController.forward();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _shouldShowPinLock = false;
          _pinVerified = true;
          _isInitialized = true;
        });
        _fadeController.forward();
      }
    }
  }

  void _onPinProviderChanged() {
    if (!mounted) return;

    final pinProvider = Provider.of<AppPinLockProvider>(context, listen: false);

    // Check if PIN lock state changed and we need to show lock screen
    if (pinProvider.enabled) {
      if (mounted) {
        setState(() {
          _shouldShowPinLock = true;
          _pinVerified = false;
        });
      }
    } else if (!pinProvider.enabled) {
      if (mounted) {
        setState(() {
          _shouldShowPinLock = false;
          _pinVerified = true;
        });
      }
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
      return FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      );
    }

    if (_shouldShowPinLock) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: StartupPinLockScreen(
          key: const ValueKey('pin_lock'),
          onPinCorrect: () async {
            // ⭐ CRITICAL FIX: Notify the provider that PIN verification was successful
            Provider.of<AppPinLockProvider>(context, listen: false)
                .onPinVerificationSuccess();
            await _fadeController.reverse();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _pinVerified = true;
                  _shouldShowPinLock = false;
                });
                _fadeController.forward();
              }
            });
          },
        ),
      );
    }

    return widget.child;
  }
}
