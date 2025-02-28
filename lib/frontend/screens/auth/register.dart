import 'package:flutter/material.dart';
// import 'package:msbridge/backend/repo/auth_repo.dart';
import 'package:msbridge/frontend/widgets/custom_text_field.dart';
import 'package:msbridge/frontend/widgets/error_dialog.dart';

class Register extends StatelessWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context) {
    // final AuthRepository _authRepository = AuthRepository();
    final theme = Theme.of(context).colorScheme;
    final TextEditingController _fullnameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _phoneNumberController =
        TextEditingController();
    final TextEditingController _confirmPasswordController =
        TextEditingController();

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
                icon: Icons.person,
                isPassword: false,
                controller: _fullnameController,
              ),
              const SizedBox(height: 16),

              // Email
              CustomTextField(
                hintText: "Email",
                icon: Icons.email,
                isPassword: false,
                controller: _emailController,
              ),
              const SizedBox(height: 16),

              // Password
              CustomTextField(
                hintText: "Password",
                icon: Icons.lock,
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 16),

              // Re-enter Password
              CustomTextField(
                hintText: "Re-enter Password",
                icon: Icons.lock,
                isPassword: true,
                controller: _confirmPasswordController,
              ),
              const SizedBox(height: 16),

              // Phone Number
              CustomTextField(
                hintText: "Phone Number",
                icon: Icons.phone,
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
                  onPressed: () {
                    // Check all field are filled
                    try {
                      if (_fullnameController.text.isEmpty ||
                          _emailController.text.isEmpty ||
                          _passwordController.text.isEmpty ||
                          _confirmPasswordController.text.isEmpty ||
                          _phoneNumberController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              "Please fill in all fields.",
                              style: TextStyle(color: Colors.black),
                            ),
                            backgroundColor: theme.primary,
                            duration: const Duration(seconds: 2),
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            behavior: SnackBarBehavior.floating,
                            closeIconColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            ErrorDialog(message: e.toString()),
                      );
                    }

                    try {
                      // check if passwords are matching
                      if (_passwordController.text !=
                          _confirmPasswordController.text) {
                        showDialog(
                          context: context,
                          builder: (context) => const ErrorDialog(
                              message: "Passwords do not match!"),
                        );
                        return;
                      }
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            ErrorDialog(message: e.toString()),
                      );
                    }

                    // send the data using model via the repo of the auth
                    try {
                      // send the data using model via the repo of the auth
                      // _authRepository.signUp(
                      //   email: _emailController.text,
                      //   password: _passwordController.text,
                      //   fullName: _fullnameController.text,
                      //   phoneNumber: _phoneNumberController.text,
                      // );
                    } catch (e) {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            ErrorDialog(message: e.toString()),
                      );
                    }
                  },
                  child: Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primary, // White text for contrast
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Already have an account? Login
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
}
