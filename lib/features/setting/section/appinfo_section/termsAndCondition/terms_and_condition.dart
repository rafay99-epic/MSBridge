import 'package:flutter/material.dart';
import 'package:msbridge/widgets/appbar.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  Widget buildSectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildParagraph(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        text,
        style: TextStyle(
            color: Theme.of(context).colorScheme.primary, height: 1.5),
      ),
    );
  }

  Widget buildBulletPoints(BuildContext context, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: const CustomAppBar(
        title: 'Terms and Conditions',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildParagraph(context, 'Welcome to MS Bridge!'),
              buildParagraph(context,
                  'Please read these Terms and Conditions carefully before using the MS Bridge app.'),
              buildSectionTitle(context, '1. Acceptance of Terms'),
              buildParagraph(context,
                  'By registering or using MS Bridge, you agree to these Terms and Conditions. If you do not agree, please do not use the app.'),
              buildSectionTitle(context, '2. User Accounts'),
              buildParagraph(context,
                  'To prevent spam accounts, user registration and authentication are required. We use Firebase Authentication to manage your account securely. You can register, log in, and change your password within the app.'),
              buildSectionTitle(context, '3. Data Storage & Privacy'),
              buildBulletPoints(context, [
                'Your notes and tasks are stored locally first, giving you full control over your data.',
                'Synchronization with Firebase occurs when you choose to sync.',
                'All authentication-related data is encrypted.',
                'We do NOT view, collect, or share any personal data or content you create.',
                'No third parties have access to your data.',
              ]),
              buildSectionTitle(context, '4. Usage'),
              buildParagraph(context,
                  'The imported notes from rafay99.com are public and accessible within the app. You may use them for personal learning purposes. Redistribution or misuse is prohibited.'),
              buildSectionTitle(context, '5. Changes to Terms'),
              buildParagraph(context,
                  'We may update these Terms and Conditions from time to time. Continued use of MS Bridge after any changes indicates your acceptance.'),
              buildSectionTitle(context, '6. Contact'),
              buildParagraph(context,
                  'For any questions, feel free to contact us at 99marafay@gmail.com.'),
              buildParagraph(context, 'Thank you for using MS Bridge!'),
            ],
          ),
        ),
      ),
    );
  }
}
