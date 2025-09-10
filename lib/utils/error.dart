import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
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
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.primary,
          title: Text(
            "Initialization Error",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "Oops! Something Went Wrong",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "The app hit a snag during startup. You can copy the details below and try again.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onBackgroundColor.withOpacity(0.75),
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: outlineVariantColor.withOpacity(0.5)),
                      ),
                      child: SelectableText(
                        errorMessage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onSurfaceColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: Icon(Icons.copy,
                              color: theme.colorScheme.primary),
                          label: Text(
                            "Copy Details",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            await Clipboard.setData(
                                ClipboardData(text: errorMessage));
                            try {
                              FirebaseCrashlytics.instance.log(
                                  'Initialization error copied to clipboard');
                            } catch (e) {
                              FlutterBugfender.sendCrash(
                                  'Failed to copy initialization error.',
                                  StackTrace.current.toString());
                              FlutterBugfender.error(
                                  'Failed to copy initialization error.');
                            }
                            if (context.mounted) {
                              const snackBar = SnackBar(
                                content: Text('Error details copied'),
                                duration: Duration(seconds: 2),
                              );
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text("Try Again"),
                          onPressed: () {
                            // Restart.restartApp();
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.surface,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
