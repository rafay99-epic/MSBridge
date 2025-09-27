import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/custom_text_field.dart';
import 'package:msbridge/widgets/snakbar.dart';

class Changepassword extends StatefulWidget {
  const Changepassword({super.key});

  @override
  ChangepasswordState createState() => ChangepasswordState();
}

class ChangepasswordState extends State<Changepassword>
    with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final AuthRepo authRepo = AuthRepo();
  bool _isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();

    // Initialize animations
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
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  Future<void> _loadCurrentUserEmail() async {
    final result = await authRepo.getCurrentUserEmail();
    if (result.isSuccess && result.user != null) {
      setState(() {
        emailController.text = result.user!.email ?? '';
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        CustomSnackBar.show(
            context, "Failed to load your email. Please enter it manually.");
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: "Change Password",
        backbutton: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Header Section
                _buildHeaderSection(context, colorScheme, theme),

                const SizedBox(height: 40),

                // Form Section
                _buildFormSection(context, colorScheme, theme),

                const SizedBox(height: 40),

                // Action Section
                _buildActionSection(context, colorScheme, theme),

                const SizedBox(height: 32),

                // Info Section
                _buildInfoSection(context, colorScheme, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon and Title
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.secondary.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              LineIcons.lock,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          "Reset Your Password",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Subtitle
        Text(
          "Enter your email address and we'll send you a link to reset your password securely.",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.primary.withValues(alpha: 0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormSection(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LineIcons.envelope,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Email Address",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Email Field
          CustomTextField(
            hintText: "Enter your email address",
            icon: LineIcons.envelope,
            isPassword: false,
            controller: emailController,
          ),

          const SizedBox(height: 16),

          // Helper Text
          Text(
            "We'll send a password reset link to this email address",
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Column(
      children: [
        // Reset Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              shadowColor: colorScheme.primary.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() {
                      _isLoading = true;
                    });
                    final authRepo = AuthRepo();
                    final result = await authRepo.resetPassword(
                      emailController.text,
                    );
                    setState(() {
                      _isLoading = false;
                    });

                    if (result.isSuccess) {
                      emailController.clear();
                      CustomSnackBar.show(context,
                          "Password reset successful. Check your inbox.");
                    } else {
                      CustomSnackBar.show(
                          context, result.error ?? "Password reset failed.");
                    }
                  },
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Sending...",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LineIcons.paperPlane,
                        size: 20,
                        color: colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Send Reset Link",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Alternative Action
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary.withValues(alpha: 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            "Back to Settings",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LineIcons.infoCircle,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                "What happens next?",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "• Check your email inbox (and spam folder)\n"
            "• Click the reset link in the email\n"
            "• Create a new strong password\n"
            "• Sign in with your new password",
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
