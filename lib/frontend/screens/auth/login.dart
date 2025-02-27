import 'package:flutter/material.dart';
import 'package:msbridge/frontend/screens/auth/forget_password.dart';
import 'package:msbridge/frontend/screens/auth/register.dart';
import 'package:msbridge/frontend/widgets/custom_text_field.dart';
import 'package:page_transition/page_transition.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: theme.surface, // Surface as background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Title
              Text(
                "Welcome to MS Bridge",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.primary, // White text
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Seamlessly access and sync your MS Notes.",
                style: TextStyle(
                  fontSize: 16,
                  color:
                      theme.primary.withOpacity(0.7), // White text with opacity
                ),
              ),
              const SizedBox(height: 32),

              // Email Field
              const CustomTextField(
                hintText: "Email",
                icon: Icons.email,
                isPassword: false,
              ),
              const SizedBox(height: 16),

              // Password Field
              const CustomTextField(
                hintText: "Password",
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 8),

              // Forgot Password Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        child: const ForgetPassword(),
                        type: PageTransitionType.rightToLeft,
                        duration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                        fontSize: 16,
                        color: theme.secondary), // Secondary color
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.secondary, // Secondary color button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Login logic
                  },
                  child: Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primary, // White text on button
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Don't have an account? Register Now
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                        fontSize: 16, color: theme.primary), // White text
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          child: const Register(),
                          type: PageTransitionType.rightToLeft,
                          duration: const Duration(milliseconds: 300),
                        ),
                      );
                    },
                    child: Text(
                      "Register Now",
                      style: TextStyle(
                          fontSize: 16,
                          color: theme.secondary), // Secondary color
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
