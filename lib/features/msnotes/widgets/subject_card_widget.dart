import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

class SubjectCardWidget extends StatelessWidget {
  final String subject;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const SubjectCardWidget({
    super.key,
    required this.subject,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest, // Match search screen color
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow
                .withValues(alpha: 0.2), // Increased shadow opacity
            blurRadius: 12, // Increased blur for better depth
            offset: const Offset(0, 6), // Increased offset for better elevation
          ),
        ],
        border: Border.all(
          color: colorScheme.primary
              .withValues(alpha: 0.3), // Match search screen border color
          width: 2, // Match search screen border width
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary
                        .withValues(alpha: 0.15), // Slightly more prominent
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      // Add border to icon container
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    LineIcons.bookOpen,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight
                              .w700, // Increased weight for better visibility
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tap to view lectures",
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(
                              alpha:
                                  0.7), // Increased opacity for better readability
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  // Wrap arrow icon in styled container
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    LineIcons.angleRight,
                    color: colorScheme.primary,
                    size: 20,
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
