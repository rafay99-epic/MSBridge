import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/backend/repo/auth_repo.dart';
import 'package:msbridge/frontend/widgets/custom_text_field.dart';
import 'package:msbridge/frontend/widgets/snakbar.dart';

class Changepassword extends StatefulWidget {
  const Changepassword({super.key});

  @override
  ChangepasswordState createState() => ChangepasswordState();
}

class ChangepasswordState extends State<Changepassword> {
  final TextEditingController emailController = TextEditingController();
  final AuthRepo authRepo = AuthRepo();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
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
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: const Text("Change Password"),
        automaticallyImplyLeading: true,
        backgroundColor: theme.surface,
        foregroundColor: theme.primary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Change Password?",
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
                            CustomSnackBar.show(context,
                                result.error ?? "Password reset failed.");
                          }
                        },
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          "Change Password",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
