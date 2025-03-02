import 'package:flutter/material.dart';

class Msnotes extends StatelessWidget {
  const Msnotes({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("MS Notes"),
        automaticallyImplyLeading: false,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: const Center(child: Text("MS Notes")),
    );
  }
}
