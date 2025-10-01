// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_svg/svg.dart';

// Project imports:
import 'package:msbridge/core/repo/contact_repo.dart';
import 'package:msbridge/utils/img.dart';
import 'package:msbridge/widgets/custom_text_field.dart';

class ContactPage extends StatelessWidget {
  ContactPage({super.key});

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final messageController = TextEditingController();

  void sendMessage(BuildContext context) async {
    try {
      ContactService contactService = ContactService();

      await contactService.saveContactMessage(
        emailController.text,
        nameController.text,
        messageController.text,
        context,
      );

      messageController.clear();
      nameController.clear();
      emailController.clear();
    } catch (e) {
      FlutterBugfender.sendCrash(
          "Failed to send message: $e", StackTrace.current.toString());
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            "Failed to send message",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Text(
            "There was an error sending your message. Please try again later.",
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.8),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Contact Us",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: MediaQuery.of(context).size.width * 0.05,
            right: MediaQuery.of(context).size.width * 0.05,
          ),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 100),
              SvgPicture.asset(
                ContactFormImage.logo,
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 35),
              Text(
                'MS Bridge',
                style: TextStyle(
                  letterSpacing: .5,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'d love to hear from you',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 35),
              CustomTextField(
                controller: nameController,
                hintText: 'Enter your name',
                icon: Icons.person,
                isPassword: false,
              ),
              const SizedBox(height: 35),
              CustomTextField(
                hintText: 'Enter your email',
                controller: emailController,
                icon: Icons.email,
                isPassword: false,
              ),
              const SizedBox(height: 35),
              CustomTextField(
                controller: messageController,
                icon: Icons.message,
                isPassword: false,
                numLines: 5,
                hintText: 'Enter your message',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => sendMessage(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Send Message',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
