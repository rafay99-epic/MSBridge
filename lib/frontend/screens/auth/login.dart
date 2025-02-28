import 'package:flutter/material.dart';
import 'package:msbridge/backend/repo/auth_repo.dart';
import 'package:msbridge/frontend/screens/home/home.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/frontend/screens/auth/forget_password.dart';
import 'package:msbridge/frontend/screens/auth/register.dart';
import 'package:msbridge/frontend/widgets/custom_text_field.dart';
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

    final authRepo = Provider.of<AuthRepo>(context, listen: false);
    final result =
        await authRepo.login(_emailController.text, _passwordController.text);

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      showCustomSnackBar("✅ Welcome ${result.user!.name}!", isSuccess: true);

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
      showCustomSnackBar("❌ ${result.error}", isSuccess: false);
    }
  }

  void showCustomSnackBar(String message, {required bool isSuccess}) {
    final snackBar = SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      elevation: 6.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 5),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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

              // Email Field
              CustomTextField(
                controller: _emailController,
                hintText: "Email",
                icon: Icons.email,
                isPassword: false,
              ),
              const SizedBox(height: 16),

              // Password Field
              CustomTextField(
                controller: _passwordController,
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
                  child: Text("Forgot Password?",
                      style: TextStyle(fontSize: 16, color: theme.secondary)),
                ),
              ),
              const SizedBox(height: 16),

              // Login Button
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

              // Don't have an account? Register Now
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
