import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:provider/provider.dart';

class EmptyNotesMessage extends StatelessWidget {
  final String message;
  final String description;
  const EmptyNotesMessage(
      {super.key, required this.message, required this.description});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imagePath = themeProvider.currentImagePath;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Illustrated header inside a themed circular container
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.25),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: SvgPicture.asset(
                    imagePath,
                    width: 120,
                    height: 120,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Content card
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.25),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      message,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.75),
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Subtle divider and hint
                    const SizedBox(height: 14),
                    Container(
                      height: 1,
                      width: 120,
                      color: colorScheme.outline.withOpacity(0.18),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.secondary.withOpacity(0.18),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "Nothing here yet",
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
