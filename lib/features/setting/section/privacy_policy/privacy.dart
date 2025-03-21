import 'package:flutter/material.dart';
import 'package:msbridge/widgets/appbar.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  PrivacyPolicyPageState createState() => PrivacyPolicyPageState();
}

class PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  bool showAdditionalContent = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(
        title: 'Privacy Policy',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Effective Date: March 21, 2025',
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Welcome to MS Bridge. Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information when you use our application.',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            buildSectionTitle(context, '1. Information We Collect'),
            buildParagraph(context, 'We collect the following information:'),
            buildBulletPoints(context, [
              'Personal Information: When you register, we collect your email address and any other information you provide.',
              'Notes and Tasks: Your notes and tasks are stored locally on your device and synchronized with our servers.',
              'Usage DaQta: We may collect information about how you use the app to improve our services.',
            ]),
            buildSectionTitle(context, '2. Use of Your Information'),
            buildParagraph(context, 'We use your information to:'),
            buildBulletPoints(context, [
              'Provide and maintain our services.',
              'Authenticate your identity.',
              'Synchronize your notes and tasks across devices.',
              'Improve and personalize your experience.',
            ]),
            buildSectionTitle(context, '3. Data Storage and Security'),
            buildParagraph(context,
                'We use Firebase services to store and manage your data. Firebase is a platform provided by Google that offers secure data storage solutions. For more information on Firebase\'s privacy practices, please visit their '),
            GestureDetector(
              onTap: () {
                // Handle link tap (open browser, etc.)
              },
              child: Text(
                'Privacy and Security page',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 10),
            buildParagraph(context,
                'We implement industry-standard security measures to protect your data. However, no method of transmission over the internet or electronic storage is 100% secure.'),
            buildSectionTitle(context, '4. Data Encryption'),
            buildParagraph(context,
                'All authentication-related data is encrypted to ensure your privacy and security. This means that sensitive information is transformed into a secure format that cannot be read without proper authorization.'),
            buildSectionTitle(context, '5. Third-Party Services'),
            buildParagraph(context,
                'We do not share your personal information with third parties except as necessary to provide our services or as required by law.'),
            buildSectionTitle(context, '6. User Rights'),
            buildParagraph(context, 'You have the right to:'),
            buildBulletPoints(context, [
              'Access and update your personal information.',
              'Delete your account and associated data.',
              'Contact us regarding privacy concerns.',
            ]),
            buildSectionTitle(context, '7. Changes to This Privacy Policy'),
            buildParagraph(context,
                'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.'),
            buildSectionTitle(context, '8. Contact Us'),
            buildParagraph(context,
                'If you have any questions about this Privacy Policy, please contact us at '),
            GestureDetector(
              onTap: () {
                // Handle email tap
              },
              child: Text(
                '99marafay@gmail.com',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                ),
                onPressed: () {
                  setState(() {
                    showAdditionalContent = !showAdditionalContent;
                  });
                },
                child: Text(
                  showAdditionalContent ? 'Show Less' : 'Read More',
                  style: TextStyle(color: theme.colorScheme.surface),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (showAdditionalContent) ...[
              buildSectionTitle(context, '9. Additional Information'),
              buildParagraph(context,
                  'For more details on our data practices, please refer to our Terms of Service.'),
            ]
          ],
        ),
      ),
    );
  }

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
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
}
