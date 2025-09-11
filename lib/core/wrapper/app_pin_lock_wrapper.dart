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
  AppPinLockProvider? _cachedPinProvider;
  bool _listenerAttached = false;
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
      _cachedPinProvider ??=
          Provider.of<AppPinLockProvider>(context, listen: false);

      final provider = _cachedPinProvider;
      if (provider == null) {
        // Provider not available yet; treat as verified to avoid blocking UI
        if (!mounted) return;
        setState(() {
          _shouldShowPinLock = false;
          _pinVerified = true;
          _isInitialized = true;
        });
        _fadeController.forward();
        return;
      }

      if (!_listenerAttached) {
        provider.addListener(_onPinProviderChanged);
        _listenerAttached = true;
      }

      await provider.refreshPinLockState();

      final hasPin = await provider.hasPin();

      if (!mounted) return;

      if (provider.enabled && hasPin) {
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
      if (!mounted) return;
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
    // Fall back to reading once if the cache is missing, but avoid during dispose
    _cachedPinProvider ??=
        Provider.of<AppPinLockProvider>(context, listen: false);

    // Check if PIN lock state changed and we need to show lock screen
    final pinProvider = _cachedPinProvider;
    if (pinProvider == null) return;
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
      if (_listenerAttached) {
        _cachedPinProvider?.removeListener(_onPinProviderChanged);
        _listenerAttached = false;
      }
    } catch (e) {
      FlutterBugfender.sendCrash("Error removing pin provider listener: $e",
          StackTrace.current.toString());
      FlutterBugfender.error("Error removing pin provider listener: $e");
      // Provider might not be available during dispose
    }
    _cachedPinProvider = null;

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
            (_cachedPinProvider ??
                    Provider.of<AppPinLockProvider>(context, listen: false))
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
