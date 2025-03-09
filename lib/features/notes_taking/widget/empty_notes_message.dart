import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:provider/provider.dart';

class EmptyNotesMessage extends StatelessWidget {
  const EmptyNotesMessage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final imagePath = themeProvider.currentImagePath;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              imagePath,
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 24),
            Text(
              "Empty, Like a Desert Island!",
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Tap the + button to add your first note!",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
