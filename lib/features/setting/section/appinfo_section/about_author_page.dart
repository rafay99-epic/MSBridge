// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:msbridge/features/setting/section/appinfo_section/about_author_section.dart';
import 'package:msbridge/widgets/appbar.dart';

class AboutAuthorPage extends StatelessWidget {
  const AboutAuthorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(title: "About Author", backbutton: true),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: AboutAuthorSection(),
      ),
    );
  }
}
