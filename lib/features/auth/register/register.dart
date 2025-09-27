import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/widgets/custom_text_field.dart';
import 'package:msbridge/widgets/error_dialog.dart';
import 'package:msbridge/widgets/loading_dialogbox.dart';
import 'package:msbridge/widgets/snakbar.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final AuthRepo _authRepo = AuthRepo();

  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                kToolbarHeight,
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
                    "Create Account",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Fill in the details to sign up.",
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Full Name
                  CustomTextField(
                    hintText: "Full Name",
                    icon: LineIcons.user,
                    isPassword: false,
                    controller: _fullnameController,
                  ),
                  const SizedBox(height: 16),

                  // Email + Passwords (Autofill)
                  AutofillGroup(
                    child: Column(
                      children: [
                        CustomTextField(
                          hintText: "Email",
                          icon: LineIcons.envelope,
                          isPassword: false,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enableSuggestions: true,
                          autocorrect: false,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          hintText: "Password",
                          icon: LineIcons.lock,
                          isPassword: true,
                          controller: _passwordController,
                          textInputAction: TextInputAction.next,
                          enableSuggestions: false,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.newPassword],
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          hintText: "Re-enter Password",
                          icon: LineIcons.lock,
                          isPassword: true,
                          controller: _confirmPasswordController,
                          textInputAction: TextInputAction.done,
                          enableSuggestions: false,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.newPassword],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Phone Number
                  CustomTextField(
                    hintText: "Phone Number",
                    icon: LineIcons.phone,
                    isPassword: false,
                    keyboardType: TextInputType.phone,
                    controller: _phoneNumberController,
                  ),
                  const SizedBox(height: 24),

                  // Sign Up Button
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
                      onPressed: () => _registerUser(context),
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.onPrimary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Already have an account? Login",
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

  void _registerUser(BuildContext context) async {
    if (_fullnameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _phoneNumberController.text.isEmpty) {
      CustomSnackBar.show(
        context,
        "Please fill in all fields.",
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      showDialog(
        context: context,
        builder: (context) =>
            const ErrorDialog(message: "Passwords do not match!"),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(message: "Registering..."),
    );

    final result = await _authRepo.register(
      _emailController.text,
      _passwordController.text,
      _fullnameController.text,
      _phoneNumberController.text,
    );
    if (!context.mounted) return;
    Navigator.pop(context);

    if (result.isSuccess) {
      CustomSnackBar.show(
          context, "Account created successfully! Please Veriffy your email.");

      _fullnameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _phoneNumberController.clear();

      // Navigate back after delay to let user read the message
      Future.delayed(const Duration(seconds: 4), () {
        if (!context.mounted) return;
        Navigator.pop(context);
      });
    } else {
      showDialog(
        context: context,
        builder: (context) =>
            ErrorDialog(message: result.error ?? "Unknown error"),
      );
    }
  }
}
