import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/backend/repo/auth_repo.dart';
import 'package:msbridge/frontend/widgets/custom_text_field.dart';
import 'package:msbridge/frontend/widgets/error_dialog.dart';
import 'package:msbridge/frontend/widgets/loading_dialogbox.dart';
import 'package:msbridge/frontend/widgets/snakbar.dart';

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Fill in the details to sign up.",
                style: TextStyle(
                  fontSize: 16,
                  color: theme.primary.withOpacity(0.7),
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

              // Email
              CustomTextField(
                hintText: "Email",
                icon: LineIcons.envelope,
                isPassword: false,
                controller: _emailController,
              ),
              const SizedBox(height: 16),

              // Password
              CustomTextField(
                hintText: "Password",
                icon: LineIcons.lock,
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 16),

              // Re-enter Password
              CustomTextField(
                hintText: "Re-enter Password",
                icon: LineIcons.lock,
                isPassword: true,
                controller: _confirmPasswordController,
              ),
              const SizedBox(height: 16),

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
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _registerUser(context),
                  child: Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primary,
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

  /// **Register User Function**
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
