import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:pinput/pinput.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/lock_app/app_pin_lock_provider.dart';

class PinLockScreen extends StatefulWidget {
  final bool isCreating;
  final bool isChanging;
  final String? existingPin;
  final Function(String) onConfirmed;
  final VoidCallback? onCancel;

  const PinLockScreen({
    super.key,
    this.isCreating = false,
    this.isChanging = false,
    this.existingPin,
    required this.onConfirmed,
    this.onCancel,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isError = false;
  bool _isFirstNewPinEntry = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.isCreating ? 'Create PIN' : 'Enter PIN',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () {
            widget.onCancel?.call();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                widget.isCreating
                    ? (_isConfirming ? 'Confirm PIN' : 'Create a 4-digit PIN')
                    : widget.isChanging
                        ? (_isConfirming
                            ? 'Confirm New PIN'
                            : 'Enter Current PIN')
                        : 'Enter your PIN',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                widget.isCreating
                    ? (_isConfirming
                        ? 'Re-enter the PIN to confirm'
                        : 'This PIN will be used to lock the app')
                    : widget.isChanging
                        ? (_isConfirming
                            ? 'Re-enter the new PIN to confirm'
                            : 'Enter your current PIN to verify identity')
                        : 'Enter your 4-digit PIN to continue',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Status indicator for PIN change flow
              if (widget.isChanging)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isConfirming
                        ? colorScheme.primaryContainer
                        : colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isConfirming
                          ? colorScheme.primary.withOpacity(0.3)
                          : colorScheme.secondary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isConfirming
                            ? (_isFirstNewPinEntry
                                ? Icons.edit
                                : Icons.check_circle)
                            : Icons.verified_user,
                        size: 20,
                        color: _isConfirming
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isConfirming
                            ? (_isFirstNewPinEntry
                                ? 'Step 2: Enter your new PIN'
                                : 'Step 3: Confirm your new PIN')
                            : 'Step 1: Verify current PIN',
                        style: TextStyle(
                          color: _isConfirming
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // PIN Input Container
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Pinput(
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  length: 4,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  defaultPinTheme: PinTheme(
                    width: 65,
                    height: 65,
                    textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isError
                            ? colorScheme.error
                            : colorScheme.outline.withOpacity(0.3),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: colorScheme.surface,
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 65,
                    height: 65,
                    textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: colorScheme.surface,
                    ),
                  ),
                  submittedPinTheme: PinTheme(
                    width: 65,
                    height: 65,
                    textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: colorScheme.primary,
                    ),
                  ),
                  errorPinTheme: PinTheme(
                    width: 65,
                    height: 65,
                    textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onError,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.error,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: colorScheme.errorContainer,
                    ),
                  ),
                  onCompleted: (pin) {
                    if (_isProcessing) return;

                    setState(() {
                      _isProcessing = true;
                    });

                    if (widget.isCreating) {
                      _handlePinCreation(pin);
                    } else if (widget.isChanging) {
                      if (!_isConfirming) {
                        // First verify current PIN
                        _handlePinVerification(pin);
                      } else if (_isFirstNewPinEntry) {
                        // First time entering new PIN
                        _handleFirstNewPin(pin);
                      } else {
                        // Confirming new PIN
                        _handlePinConfirmation(pin);
                      }
                    } else {
                      _handlePinVerification(pin);
                    }
                  },
                  onChanged: (pin) {
                    if (_isError) {
                      setState(() {
                        _isError = false;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Error message
              if (_isError)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.isCreating
                        ? 'PINs do not match. Please try again.'
                        : widget.isChanging
                            ? (_isConfirming
                                ? 'New PINs do not match. Please try again.'
                                : 'Incorrect current PIN. Please try again.')
                            : 'Incorrect PIN. Please try again.',
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24),

              // Action buttons
              if (widget.isCreating && _isConfirming)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isConfirming = false;
                          _confirmPin = '';
                          _pinController.clear();
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _pinFocusNode.requestFocus();
                        });
                      },
                      child: Text(
                        'Back',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),

              // Back button for PIN change flow
              if (widget.isChanging && _isConfirming)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isConfirming = false;
                          _confirmPin = '';
                          _pinController.clear();
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _pinFocusNode.requestFocus();
                        });
                      },
                      child: Text(
                        'Back to Current PIN',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),

              // Add a subtle loading indicator when processing
              if (_isProcessing && !_isConfirming)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Updated handler methods

  void _handlePinCreation(String pin) {
    if (!_isConfirming) {
      setState(() {
        _confirmPin = pin;
        _isConfirming = true;
        _pinController.clear();
        _isProcessing = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pinFocusNode.requestFocus();
      });
    } else {
      if (pin == _confirmPin) {
        final pinProvider =
            Provider.of<AppPinLockProvider>(context, listen: false);

        // Save the PIN using the provider
        pinProvider.savePin(pin).then((_) {
          if (!mounted) return;
          if (pinProvider.hasError) {
            CustomSnackBar.show(
              context,
              pinProvider.getErrorMessage(),
              isSuccess: false,
            );
            setState(() {
              _isProcessing = false;
            });
            return;
          }

          // Show success message
          String successMessage = widget.isChanging
              ? 'PIN changed successfully!'
              : 'PIN created successfully!';

          CustomSnackBar.show(
            context,
            successMessage,
            isSuccess: true,
          );

          // Call the callback and navigate back
          widget.onConfirmed(pin);

          // Use a small delay to ensure the snackbar is shown
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });
        }).catchError((e) {
          if (!mounted) return;
          FlutterBugfender.sendCrash(
              "Failed to save PIN. Please try again.", e.toString());
          CustomSnackBar.show(
            context,
            'Failed to save PIN. Please try again.',
            isSuccess: false,
          );
          setState(() {
            _isProcessing = false;
          });
        });
      } else {
        setState(() {
          _isError = true;
          _pinController.clear();
          _isProcessing = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pinFocusNode.requestFocus();
        });
      }
    }
  }

  void _handlePinVerification(String pin) async {
    final pinProvider = Provider.of<AppPinLockProvider>(context, listen: false);

    try {
      final isCorrect = await pinProvider.verifyPin(pin);
      if (!mounted) return;
      if (isCorrect) {
        CustomSnackBar.show(
          context,
          'Current PIN verified! Now enter your new PIN',
          isSuccess: true,
        );
        setState(() {
          _isConfirming = true;
          _isFirstNewPinEntry = true;
          _confirmPin = '';
          _pinController.clear();
          _isProcessing = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pinFocusNode.requestFocus();
        });
      } else {
        // Incorrect current PIN
        CustomSnackBar.show(
          context,
          'Incorrect current PIN. Please try again.',
          isSuccess: false,
        );
        setState(() {
          _isError = true;
          _pinController.clear();
          _isProcessing = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pinFocusNode.requestFocus();
        });
      }
    } catch (e) {
      if (!mounted) return;
      FlutterBugfender.sendCrash(
          "Error verifying PIN. Please try again.", e.toString());
      CustomSnackBar.show(
        context,
        'Error verifying PIN. Please try again.',
        isSuccess: false,
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _handleFirstNewPin(String pin) {
    setState(() {
      _confirmPin = pin;
      _isFirstNewPinEntry = false;
      _pinController.clear();
      _isProcessing = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocusNode.requestFocus();
    });
  }

  void _handlePinConfirmation(String pin) {
    if (pin == _confirmPin) {
      final pinProvider =
          Provider.of<AppPinLockProvider>(context, listen: false);

      // Update the PIN using the provider
      pinProvider.updatePin(pin).then((_) {
        if (pinProvider.hasError) {
          CustomSnackBar.show(
            context,
            pinProvider.getErrorMessage(),
            isSuccess: false,
          );
          setState(() {
            _isProcessing = false;
          });
          return;
        }

        // Show success message
        CustomSnackBar.show(
          context,
          'New PIN confirmed! PIN changed successfully!',
          isSuccess: true,
        );

        // Call the callback and navigate back
        widget.onConfirmed(pin);

        // Use a small delay to ensure the snackbar is shown
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      }).catchError((e) {
        if (!mounted) return;
        FlutterBugfender.sendCrash(
            "Failed to update PIN. Please try again.", e.toString());
        CustomSnackBar.show(
          context,
          'Failed to update PIN. Please try again.',
          isSuccess: false,
        );
        setState(() {
          _isProcessing = false;
        });
      });
    } else {
      setState(() {
        _isError = true;
        _pinController.clear();
        _isProcessing = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pinFocusNode.requestFocus();
      });
    }
  }
}
