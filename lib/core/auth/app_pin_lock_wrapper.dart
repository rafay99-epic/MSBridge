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

class _AppPinLockWrapperState extends State<AppPinLockWrapper>
    with TickerProviderStateMixin {
  bool _pinVerified = false;
  bool _isInitialized = false;
  bool _shouldShowPinLock = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePinLock();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400), // Reduced from 800ms
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut, // Changed from easeInOut for better performance
    ));
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
        // Start fade in animation for immediate content
        _fadeController.forward();
      }
    } catch (e) {
      setState(() {
        _shouldShowPinLock = false;
        _pinVerified = true;
        _isInitialized = true;
      });
      // Start fade in animation for immediate content
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
            // Optimized transition: faster and smoother
            await _fadeController.reverse();

            // Use microtask for better performance
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _pinVerified = true;
              });
              _fadeController.forward();
            });
          },
        ),
      );
    }

    return widget.child;
  }
}
