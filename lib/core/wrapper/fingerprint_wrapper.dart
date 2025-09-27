import 'package:flutter/material.dart';
import 'package:msbridge/core/provider/lock_provider/fingerprint_provider.dart';
import 'package:msbridge/features/lock/fingerprint_lock_screen.dart';
import 'package:provider/provider.dart';

class FingerprintAuthWrapper extends StatefulWidget {
  final Widget child;

  const FingerprintAuthWrapper({
    super.key,
    required this.child,
  });

  @override
  State<FingerprintAuthWrapper> createState() => _FingerprintAuthWrapperState();
}

class _FingerprintAuthWrapperState extends State<FingerprintAuthWrapper> {
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndAuthenticate();
  }

  Future<void> _loadAndAuthenticate() async {
    final fingerprintProvider =
        Provider.of<FingerprintAuthProvider>(context, listen: false);

    await Future.delayed(const Duration(milliseconds: 100));

    if (fingerprintProvider.isFingerprintEnabled) {
      if (!_isAuthenticated && !_isAuthenticating) {
        setState(() {
          _isAuthenticating = true;
        });
        if (!context.mounted) return;
        bool authenticated = await fingerprintProvider.authenticate(context);
        setState(() {
          _isAuthenticated = authenticated;
          _isAuthenticating = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isAuthenticated = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }

    final fingerprintProvider = Provider.of<FingerprintAuthProvider>(context);

    if (fingerprintProvider.isFingerprintEnabled && !_isAuthenticated) {
      return FingerprintAuthScreen(
        isAuthenticating: _isAuthenticating,
        onAuthenticate: () async {
          setState(() {
            _isAuthenticating = true;
          });
          bool authenticated = await fingerprintProvider.authenticate(context);
          setState(() {
            _isAuthenticated = authenticated;
            _isAuthenticating = false;
          });
        },
      );
    } else {
      return widget.child;
    }
  }
}
