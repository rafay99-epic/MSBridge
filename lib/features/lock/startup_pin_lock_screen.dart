import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:pinput/pinput.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/lock_provider/app_pin_lock_provider.dart';

class StartupPinLockScreen extends StatefulWidget {
  final Function() onPinCorrect;

  const StartupPinLockScreen({
    super.key,
    required this.onPinCorrect,
  });

  @override
  State<StartupPinLockScreen> createState() => _StartupPinLockScreenState();
}

class _StartupPinLockScreenState extends State<StartupPinLockScreen>
    with TickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  bool _isVerifying = false;
  String _errorMessage = '';
  bool isUnlocking = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _successController;
  late AnimationController _iconController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _successAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration:
          const Duration(milliseconds: 400), // Reduced for better performance
      vsync: this,
    );
    _slideController = AnimationController(
      duration:
          const Duration(milliseconds: 300), // Reduced for better performance
      vsync: this,
    );
    _successController = AnimationController(
      duration:
          const Duration(milliseconds: 500), // Reduced for better performance
      vsync: this,
    );
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1200), // Slightly shorter loop
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut, // Better performance curve
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15), // Reduced offset for better performance
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut, // Changed from easeOutCubic for better performance
    ));

    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOut, // Changed from elasticOut for better performance
    ));

    _iconScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05, // Reduced scale for better performance
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeOut, // Changed from easeInOut for better performance
    ));

    _iconRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05, // Reduced rotation for better performance
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeOut, // Changed from easeInOut for better performance
    ));

    _fadeController.forward();
    _slideController.forward();
    _iconController.repeat(reverse: true);

    // Optimized focus management for Android performance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use a small delay to ensure smooth keyboard animation
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _pinFocusNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _successController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _verifyPin(String pin) async {
    if (pin.length != 4) return;

    // Optimized state updates for better performance
    if (mounted) {
      setState(() {
        _isVerifying = true;
        _errorMessage = '';
      });
    }

    try {
      final pinProvider =
          Provider.of<AppPinLockProvider>(context, listen: false);
      final storedPin = await pinProvider.readPin();

      if (storedPin == pin) {
        isUnlocking = true;
        // Pause repeating icon animation to save frames during transition
        if (_iconController.isAnimating) _iconController.stop();

        // Start success animation and then fade out the whole view for a smooth handoff
        await _successController.forward();

        // Clear background time to prevent "incorrect password" bug
        pinProvider.onPinVerificationSuccess();

        if (mounted) {
          // Subtle success toast
          CustomSnackBar.show(
            context,
            'Welcome back!',
            isSuccess: true,
          );
        }

        // Fade out content before navigating to home, avoiding sudden frame spikes
        if (mounted) {
          await _fadeController.reverse();
        }

        if (mounted) {
          widget.onPinCorrect();
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Incorrect PIN. Please try again.';
            _isVerifying = false;
          });
          _pinController.clear();
          // Optimized focus management
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _pinFocusNode.requestFocus();
            }
          });
        }
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          "Error verifying PIN: $e", StackTrace.current.toString());
      FlutterBugfender.error("Error verifying PIN: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Error verifying PIN. Please try again.';
          _isVerifying = false;
        });
        _pinController.clear();
        // Optimized focus management
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _pinFocusNode.requestFocus();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surfaceContainerHighest.withOpacity(0.2),
                    colorScheme.surface,
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: RepaintBoundary(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo/Icon Section - Cool Settings Header Effect
                      RepaintBoundary(
                          child: AnimatedBuilder(
                        animation: _iconController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _iconScaleAnimation.value,
                            child: Transform.rotate(
                              angle: _iconRotationAnimation.value,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.secondary,
                                      colorScheme.primary.withOpacity(0.8),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          colorScheme.primary.withOpacity(0.20),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.lock_outline,
                                  size: 45,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      )),

                      const SizedBox(height: 32),

                      // Title Section - Clean Typography
                      Text(
                        'Welcome Back',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Enter your PIN to unlock the app',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // PIN Input Section - Minimal Design
                      RepaintBoundary(
                        child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.shadow.withOpacity(0.10),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Pinput(
                                  controller: _pinController,
                                  focusNode: _pinFocusNode,
                                  length: 4,
                                  onCompleted: _verifyPin,
                                  obscureText: true,
                                  obscuringCharacter: '●',
                                  // Android performance optimizations
                                  autofocus:
                                      false, // Let us control focus manually
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  defaultPinTheme: PinTheme(
                                    width: 56,
                                    height: 56,
                                    textStyle:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.outline
                                            .withOpacity(0.25),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.shadow
                                              .withOpacity(0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  focusedPinTheme: PinTheme(
                                    width: 56,
                                    height: 56,
                                    textStyle:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.primary,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary
                                              .withOpacity(0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  errorPinTheme: PinTheme(
                                    width: 56,
                                    height: 56,
                                    textStyle:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onErrorContainer,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.error,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.error
                                              .withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Error Message - Clean and Simple
                                if (_errorMessage.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: colorScheme.onErrorContainer,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            _errorMessage,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color:
                                                  colorScheme.onErrorContainer,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            )),
                      ),

                      const SizedBox(height: 24),

                      // Loading State - Simple Indicator
                      if (_isVerifying)
                        Column(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Verifying PIN...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                      // Success Animation
                      if (_successController.isCompleted)
                        ScaleTransition(
                          scale: _successAnimation,
                          child: Container(
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Unlocked',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),

                      // App Branding - Bottom Section like Settings Panel
                      Column(
                        children: [
                          Text(
                            'MSBridge',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Syntax Lab Technologies',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.7),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
