import 'package:flutter/material.dart';
// import 'package:restart_app/restart_app.dart';

class ErrorApp extends StatelessWidget {
  final String errorMessage;
  const ErrorApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color onSurfaceColor = theme.colorScheme.primary;
    final Color onBackgroundColor = theme.colorScheme.primary;
    final Color outlineVariantColor = theme.colorScheme.secondary;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text("Initialization Error"),
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.surface,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  "Oops! Something Went Wrong...",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "The app encountered a problem during initialization.  Please review the details below:",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: onBackgroundColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: outlineVariantColor),
                  ),
                  child: SelectableText(
                    errorMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onSurfaceColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Try Again"),
                  onPressed: () {
                    // Restart.restartApp();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.surface,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
