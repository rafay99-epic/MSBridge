import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/widgets/custom_text_field.dart';
import 'package:msbridge/widgets/snakbar.dart';

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final TextEditingController emailController = TextEditingController();

    return Scaffold(
      backgroundColor: theme.surface,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Title
                  Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter your email to reset your password.",
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email Field
                  CustomTextField(
                    hintText: "Email",
                    icon: LineIcons.envelope,
                    isPassword: false,
                    controller: emailController,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        final email = emailController.text.trim();
                        if (email.isEmpty) {
                          CustomSnackBar.show(
                              context, "Please enter your email.");
                          return;
                        }
                        final authRepo = AuthRepo();
                        try {
                          final result = await authRepo.resetPassword(email);
                          if (result.isSuccess) {
                            emailController.clear();
                            if (!context.mounted) return;
                            CustomSnackBar.show(
                              context,
                              "Password reset email sent. Check your inbox.",
                              isSuccess: true,
                            );
                          } else {
                            FlutterBugfender.sendCrash(
                                "Password reset failed: $result.error",
                                StackTrace.current.toString());
                            if (!context.mounted) return;
                            CustomSnackBar.show(
                              context,
                              result.error ?? "Password reset failed.",
                              isSuccess: false,
                            );
                          }
                        } catch (e) {
                          FlutterBugfender.sendCrash(
                              "Password reset failed: $e",
                              StackTrace.current.toString());
                          if (!context.mounted) return;
                          CustomSnackBar.show(
                            context,
                            "Password reset failed.",
                            isSuccess: false,
                          );
                        }
                      },
                      child: Text(
                        "Reset Password",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.onPrimary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Back to Login Button
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Back to Login",
                        style: TextStyle(fontSize: 16, color: theme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
