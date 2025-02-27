import 'package:flutter/material.dart';
import 'package:msbridge/frontend/widgets/custom_text_field.dart';

class Register extends StatelessWidget {
  const Register({super.key});

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
              const CustomTextField(
                hintText: "Full Name",
                icon: Icons.person,
                isPassword: false,
              ),
              const SizedBox(height: 16),

              // Email
              const CustomTextField(
                hintText: "Email",
                icon: Icons.email,
                isPassword: false,
              ),
              const SizedBox(height: 16),

              // Password
              const CustomTextField(
                hintText: "Password",
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 16),

              // Re-enter Password
              const CustomTextField(
                hintText: "Re-enter Password",
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 16),

              // Phone Number
              const CustomTextField(
                hintText: "Phone Number",
                icon: Icons.phone,
                isPassword: false,
                keyboardType: TextInputType.phone,
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
                    // Sign-up logic
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
