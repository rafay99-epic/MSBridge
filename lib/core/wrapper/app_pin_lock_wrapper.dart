import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/lock_provider/app_pin_lock_provider.dart';
import 'package:msbridge/features/lock/startup_pin_lock_screen.dart';

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

      // Ensure persisted state is loaded before deciding what to show
      await pinProvider.refreshPinLockState();

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
        _fadeController.forward();
      }
    } catch (e) {
      setState(() {
        _shouldShowPinLock = false;
        _pinVerified = true;
        _isInitialized = true;
      });
      _fadeController.forward();
    }
  }

  void _onPinProviderChanged() {
    if (!mounted) return;

    final pinProvider = Provider.of<AppPinLockProvider>(context, listen: false);

    // Check if PIN lock state changed and we need to show lock screen
    if (pinProvider.enabled && pinProvider.wasRecentlyInBackground) {
      setState(() {
        _shouldShowPinLock = true;
        _pinVerified = false;
      });
    } else if (!pinProvider.enabled) {
      setState(() {
        _shouldShowPinLock = false;
        _pinVerified = true;
      });
    }
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    try {
      final pinProvider =
          Provider.of<AppPinLockProvider>(context, listen: false);
      pinProvider.removeListener(_onPinProviderChanged);
    } catch (e) {
      FlutterBugfender.sendCrash("Error removing pin provider listener: $e",
          StackTrace.current.toString());
      FlutterBugfender.error("Error removing pin provider listener: $e");
      // Provider might not be available during dispose
    }

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
