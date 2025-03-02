import 'package:flutter/material.dart';
import 'package:msbridge/backend/repo/auth_repo.dart';
import 'package:msbridge/frontend/screens/auth/verify/verify_email.dart';
import 'package:msbridge/frontend/screens/home/home.dart';
import 'package:msbridge/frontend/screens/auth/forget/forget_password.dart';
import 'package:msbridge/frontend/screens/auth/register/register.dart';

import 'package:msbridge/frontend/widgets/custom_text_field.dart';
import 'package:msbridge/frontend/widgets/snakbar.dart';
import 'package:page_transition/page_transition.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);

    final authRepo = AuthRepo();
    final result =
        await authRepo.login(_emailController.text, _passwordController.text);

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      final isVerified = await authRepo.isEmailVerified();

      if (isVerified) {
        CustomSnackBar.show(context, "✅ Welcome ${result.user!.displayName}!",
            isSuccess: true);

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            PageTransition(
              child: const Home(),
              type: PageTransitionType.fade,
              duration: const Duration(milliseconds: 300),
            ),
          );
        });
      } else {
        CustomSnackBar.show(context, "❌ Please verify your email first.",
            isSuccess: false);
        Navigator.pushReplacement(
          context,
          PageTransition(
            child: const EmailVerificationScreen(),
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 300),
          ),
        );
      }
    } else {
      CustomSnackBar.show(context, "❌ ${result.error}", isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: theme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome to MS Bridge",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.primary)),
              const SizedBox(height: 8),
              Text("Seamlessly access and sync your MS Notes.",
                  style: TextStyle(
                      fontSize: 16, color: theme.primary.withOpacity(0.7))),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _emailController,
                hintText: "Email",
                icon: Icons.email,
                isPassword: false,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                hintText: "Password",
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 8),
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
                  child: Text("Forgot Password?",
                      style: TextStyle(fontSize: 16, color: theme.secondary)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.secondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Login",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.primary)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?",
                      style: TextStyle(fontSize: 16, color: theme.primary)),
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
                    child: Text("Register Now",
                        style: TextStyle(fontSize: 16, color: theme.secondary)),
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
