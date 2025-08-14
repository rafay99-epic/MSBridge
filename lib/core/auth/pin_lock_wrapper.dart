import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/pin_lock_provider.dart';
import 'package:msbridge/features/setting/section/user_section/pin_lock_screen.dart';
import 'package:msbridge/widgets/snakbar.dart';

class PinLockWrapper extends StatefulWidget {
  final Widget child;

  const PinLockWrapper({
    super.key,
    required this.child,
  });

  @override
  State<PinLockWrapper> createState() => _PinLockWrapperState();
}

class _PinLockWrapperState extends State<PinLockWrapper> {
  bool _isCheckingPin = true;
  bool _isPinLocked = false;

  @override
  void initState() {
    super.initState();
    _checkPinLockStatus();
  }

  Future<void> _checkPinLockStatus() async {
    final pinProvider = Provider.of<PinLockProvider>(context, listen: false);

    // Check if PIN lock is enabled
    if (pinProvider.enabled) {
      // Check if PIN exists
      if (await pinProvider.hasPin()) {
        setState(() {
          _isPinLocked = true;
          _isCheckingPin = false;
        });
      } else {
        // PIN lock enabled but no PIN exists, disable it
        await pinProvider.setEnabled(false);
        setState(() {
          _isPinLocked = false;
          _isCheckingPin = false;
        });
      }
    } else {
      setState(() {
        _isPinLocked = false;
        _isCheckingPin = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPin) {
      // Show loading screen while checking PIN status
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isPinLocked) {
      // Show PIN lock screen
      return PinLockScreen(
        isCreating: false,
        existingPin: null, // We'll get this from the provider
        onConfirmed: (pin) async {
          // Verify PIN
          final pinProvider =
              Provider.of<PinLockProvider>(context, listen: false);
          final storedPin = await pinProvider.readPin();

          if (storedPin == pin) {
            // Correct PIN, unlock the app
            setState(() {
              _isPinLocked = false;
            });

            CustomSnackBar.show(
              context,
              'Welcome back!',
              isSuccess: true,
            );
          } else {
            // Incorrect PIN, show error
            CustomSnackBar.show(
              context,
              'Incorrect PIN. Please try again.',
              isSuccess: false,
            );
          }
        },
        onCancel: () {
          // User can't cancel from startup PIN lock
          // This will be handled by the PIN lock screen
        },
      );
    }

    // PIN lock passed or disabled, show the main app
    return widget.child;
  }
}
