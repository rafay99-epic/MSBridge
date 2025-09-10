import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'dart:async';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/features/setting/section/logout/logout_dialog.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:provider/provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  bool _isResending = false;
  bool _canResend = true;
  int _resendCount = 0;
  static const int _maxResendAttempts = 5;
  static const Duration _resendCooldown = Duration(minutes: 1);

  Timer? _cooldownTimer;
  Duration _remaining = Duration.zero;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCooldownTimer(_resendCooldown);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startCooldownTimer([Duration? cooldownDuration]) {
    if (_canResend) return;

    final duration = cooldownDuration ?? _resendCooldown;
    _remaining = duration;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds <= 1) {
          _remaining = Duration.zero;
          _canResend = true;
          timer.cancel();
        } else {
          _remaining = _remaining - const Duration(seconds: 1);
        }
      });
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend || _isResending || _resendCount >= _maxResendAttempts) {
      return;
    }

    setState(() {
      _isResending = true;
      _canResend = false;
      _resendCount++;
    });

    try {
      final result = await context.read<AuthRepo>().resendVerificationEmail();

      if (result.isSuccess) {
        CustomSnackBar.show(context, "Verification email sent!",
            isSuccess: true);

        // Check if max attempts reached after successful send
        if (_resendCount >= _maxResendAttempts) {
          // Start 24-hour cooldown for max attempts reached
          _startCooldownTimer(const Duration(hours: 24));
          CustomSnackBar.show(
            context,
            "Maximum resend attempts reached. Please wait 24 hours or contact support.",
            isSuccess: false,
          );
        } else {
          // Start normal short cooldown for successful sends
          _startCooldownTimer(_resendCooldown);
        }
      } else {
        String errorMessage = result.error ?? "Something went wrong";

        if (errorMessage.contains('too-many-requests')) {
          errorMessage =
              "Too many requests. Please wait 24 hours before trying again.";
          _resendCount = _maxResendAttempts;
          if (mounted) {
            setState(() {
              _isResending = false;
              _canResend = false;
            });
          }
          _startCooldownTimer(const Duration(hours: 24));
        } else if (errorMessage.contains('network')) {
          errorMessage =
              "Network error. Please check your connection and try again.";
          // For network errors, re-enable immediately for retry
          if (mounted) {
            setState(() {
              _isResending = false;
              _canResend = true;
            });
          }
        } else {
          // For other errors, re-enable immediately for retry
          if (mounted) {
            setState(() {
              _isResending = false;
              _canResend = true;
            });
          }
        }

        CustomSnackBar.show(context, errorMessage, isSuccess: false);
      }
    } catch (e) {
      CustomSnackBar.show(
          context, "An unexpected error occurred. Please try again later.");
      FlutterBugfender.error("Error in resend verification email $e");
      FlutterBugfender.sendCrash("Error in resend verification email $e",
          StackTrace.current.toString());
      // For unexpected errors, re-enable immediately for retry
      if (mounted) {
        setState(() {
          _isResending = false;
          _canResend = true;
        });
      }
    } finally {
      // Ensure _isResending is always reset, regardless of the path taken
      if (mounted && _isResending) {
        setState(() {
          _isResending = false;
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
      appBar: const CustomAppBar(
        title: "Email Verification",
        backbutton: true,
        showTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Main Icon Container
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.mark_email_unread_outlined,
                    size: 70,
                    color: colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 32),

                // Title Section
                Text(
                  "Verify Your Email",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  "We've sent a verification link to your email address.\nPlease check your inbox and spam folder to complete the verification.",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.8),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.secondary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lightbulb_outline,
                          color: colorScheme.secondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pro Tip",
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Firebase emails often go to spam. Check your spam/junk folder!",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Resend Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canResend &&
                            _resendCount < _maxResendAttempts &&
                            !_isResending
                        ? _resendVerificationEmail
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _canResend && _resendCount < _maxResendAttempts
                              ? colorScheme.secondary
                              : colorScheme.surface.withOpacity(0.5),
                      foregroundColor: colorScheme.onSecondary,
                      elevation: 4,
                      shadowColor: colorScheme.shadow.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: _isResending
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onSecondary),
                            ),
                          )
                        : Text(
                            _resendCount >= _maxResendAttempts
                                ? "Max Attempts Reached - Wait 24H"
                                : _canResend
                                    ? "Resend Verification Email"
                                    : "Resend in ${_formatDuration(_remaining)}",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Status Information
                if (_resendCount > 0 && _resendCount < _maxResendAttempts) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      "Attempts: $_resendCount/$_maxResendAttempts",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (!_canResend && _resendCount < _maxResendAttempts) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.secondary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      "Please wait ${_formatDuration(_remaining)} before requesting another email",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.secondary.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Back to Login Button
                TextButton(
                  onPressed: () {
                    handleLogout(context);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Back to Login",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
