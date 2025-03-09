import 'package:flutter/material.dart';
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Forgot Password?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your email to reset your password.",
                style: TextStyle(
                  fontSize: 16,
                  color: theme.primary.withOpacity(0.7),
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
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final authRepo = AuthRepo();
                    final result = await authRepo.resetPassword(
                      emailController.text,
                    );
                    if (result.isSuccess) {
                      emailController.clear();
                      CustomSnackBar.show(context,
                          "Password reset successful. Check your inbox.");
                    } else {
                      CustomSnackBar.show(context, "Password reset failed.");
                    }
                  },
                  child: Text(
                    "Reset Password",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primary,
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
                    style: TextStyle(fontSize: 16, color: theme.secondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
